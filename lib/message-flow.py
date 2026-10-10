# Herdr 0.8.0 reads a pane command's pane id first, its options after.
# Helpers every message-flow scenario shares. Commands run as alice inside the
# machine; a send runs `message` inside a Herdr pane, so the caller is a
# descendant of that pane's shell, the process a scenario binds to a metaflow.
import json
import shlex

RUNTIME = "/run/user/1000"
FIXTURES = "/etc/message-test"
SENDS = [0]

print(f"{NAME}: written against the first option of forks {FORKS or '(none)'}")


def as_alice(command):
    inner = f"export XDG_RUNTIME_DIR={RUNTIME}; {command}"
    return "su -l alice -c " + shlex.quote(inner)


def run(command):
    status, out = machine.execute(as_alice(command), timeout=30)
    return status, out.strip()


def expect(label, command, want):
    status, got = run(command)
    print(f"{label}: «{got}» (exit {status})")
    assert got == want, f"{label}: expected «{want}», got «{got}»"
    return got


def expect_prefix(label, command, want):
    status, got = run(command)
    print(f"{label}: «{got}» (exit {status})")
    assert got.startswith(want), f"{label}: expected «{want}…», got «{got}»"
    return got


# The Nexuses start with no arguments, so each binds the sockets of its own
# default configuration and its clients look there too (Message design,
# sections 3 and 5): the frame names no socket until a payload names one.
def listening(executable):
    machine.wait_until_succeeds(f"ss -xlpn | grep -q '\"{executable}\"'", timeout=60)


FLOW_NEXUS = "/etc/message-test-flow-nexus.datom"


# Flow, at boot, takes the model of every layer and Configure.Nexus, whose
# MessageNexusBinary names the message-nexus under test; Message's start Bind
# is accepted only after it. Message is then started with no arguments.
def configure_flow():
    # Flow compares canonical paths; MessageNexusBinary must name a real file.
    machine.succeed(f"test -f \"$(readlink -f {MESSAGE_NEXUS})\"")
    for layer in ["primary", "secondary", "tertiary", "quaternary"]:
        payload = f"{FIXTURES}/flow/model-{layer}.datom"
        expect(f"flow meta Configure {layer}", f'flow-meta "$(cat {payload})"', "Configured")
    expect("flow meta Configure Nexus", f'flow-meta "$(cat {FLOW_NEXUS})"', "Configured")


def start(flow_configured=True):
    machine.wait_for_unit("user@1000.service")
    for unit in ["flow-nexus.service", "herdr.service"]:
        machine.wait_for_unit(unit, user="alice")
    machine.wait_until_succeeds(as_alice("herdr workspace list"), timeout=60)
    listening("flow-nexus")
    if not flow_configured:
        return
    configure_flow()
    status, out = run("systemctl --user start message-nexus.service")
    assert status == 0, f"starting message-nexus: {out}"
    listening("message-nexus")


# A socket counts as bound when a process listens on it, so a socket file
# left by the Nexus before its restart does not count.
def bound(socket):
    status, _ = machine.execute(f"timeout 30 sh -c 'until ss -xlpn | grep -qF \" {socket} \"; do sleep 0.2; done'")
    listed = machine.succeed("ss -xlpn || true")
    assert status == 0, f"no process listens on {socket}; listening:\n{listed}"


# Message's payload is persisted by its meta client, answered Configured, or
# RestartRequired when a socket path changed. Message is then restarted with
# no arguments, so it serves from the store whatever it answered, and the
# sockets the payload names must be bound.
def configure():
    payload = f"{FIXTURES}/message.datom"
    status, got = run(f'message-meta "$(cat {payload})"')
    print(f"message meta Configure: «{got}» (exit {status})")
    assert got in ("Configured", "RestartRequired"), f"message meta Configure: expected «Configured» or «RestartRequired», got «{got}»"
    status, out = run("systemctl --user restart message-nexus.service")
    assert status == 0, f"restarting message-nexus: {out}"
    for socket in machine.succeed(f"cat {payload}").split()[1:4]:
        bound(socket.strip("{}"))


def open_pane(label):
    status, out = run(f"herdr workspace create --cwd /home/alice --label {label} --no-focus")
    assert status == 0, f"herdr workspace create: {out}"
    pane = json.loads(out)["result"]["root_pane"]["pane_id"]
    status, out = run(f"herdr pane process-info --pane {pane}")
    assert status == 0, f"herdr pane process-info: {out}"
    pid = json.loads(out)["result"]["process_info"]["shell_pid"]
    print(f"pane {label}: {pane}, shell pid {pid}")
    return pane, pid


# Bind.{ Address Process } on Flow's ordinary socket: Process is the pid and the kernel's start time of
# that pid (field 22 of /proc/<pid>/stat, clock ticks since boot). Answered
# Bound.FlowId; the flow id is returned.
def bind(address, pid):
    started = started_of(pid)
    bound_reply = expect_prefix(f"Bind {address}", f"flow 'Bind.{{ {address} {{ {pid} {started} }} }}'", "Bound.")
    return bound_reply[len("Bound."):]



# Send.{ Recipient Request }, Recipient.[ Address Up ] from Flow's Library,
# written as the Message design
# writes it: the Address variant short, `Send.{ { Mind nexus Secondary }
# Order.«…» }` (section 5), and a send up `Send.{ Up Order.«…» }` (7.4).
# Fork F6: no tiers, per design. The request carries no priority head.
def send_datom(recipient, request):
    return f"Send.{{ {recipient} {request} }}"


def send_from(pane, datom):
    SENDS[0] += 1
    out = f"/tmp/send-{SENDS[0]}"
    line = f"message {shlex.quote(datom)} > {out}.reply 2>&1; echo $? > {out}.code"
    status, typed = run(f"herdr pane run {pane} {shlex.quote(line)}")
    assert status == 0, f"herdr pane run: {typed}"
    machine.wait_until_succeeds(f"test -s {out}.code", timeout=60)
    code = machine.succeed(f"cat {out}.code").strip()
    reply = machine.succeed(f"cat {out}.reply").strip()
    print(f"send {datom}: «{reply}» (exit {code})")
    return reply


def expect_send(pane, datom, want):
    reply = send_from(pane, datom)
    assert reply == want, f"expected «{want}», got «{reply}»"
    return reply


def expect_send_prefix(pane, datom, want):
    reply = send_from(pane, datom)
    assert reply.startswith(want), f"expected «{want}…», got «{reply}»"
    return reply


def pane_shows(pane, text):
    status, out = run(f"herdr pane wait-output {pane} --match {shlex.quote(text)} --timeout 15000")
    assert status == 0, f"pane {pane} never showed «{text}»: {out}"


def pane_lacks(pane, text):
    status, out = run(f"herdr pane read {pane} --source recent --format text")
    assert status == 0, f"herdr pane read: {out}"
    assert text not in out, f"pane {pane} shows «{text}»"


def cursor():
    out = machine.succeed("journalctl -n 0 --show-cursor --no-pager")
    return out.strip().split("cursor: ")[-1]


def trace(unit, after=None):
    since = f"--after-cursor={shlex.quote(after)}" if after else ""
    return machine.succeed(f"journalctl --no-pager -o cat {since} _SYSTEMD_USER_UNIT={unit}.service")


def trace_in_order(unit, words, after=None):
    text = trace(unit, after)
    position = 0
    for word in words:
        found = text.find(word, position)
        assert found >= 0, f"{unit} trace lacks «{word}» after position {position}:\n{text}"
        position = found + len(word)


# The kernel's start time of a pid, field 22 of /proc/<pid>/stat.
def started_of(pid):
    return machine.succeed(f"cut -d' ' -f22 /proc/{pid}/stat").strip()


def main_pid(unit):
    return run(f"systemctl --user show -p MainPID --value {unit}.service")[1]


# Whether any process listens on a unix socket under the runtime directory
# whose command is the given executable name.
def listens(executable):
    return machine.execute(f"ss -xlpn | grep -q '\"{executable}\"'")[0] == 0
