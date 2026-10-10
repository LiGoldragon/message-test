# Test 24, a reaped peer. message-nexus is stopped with SIGSTOP (job
# control; nothing is traced). A `message` client in a bound pane connects
# to Message's ordinary socket and sends; it is killed while it waits for
# the reply, and its pane shell reaps it. message-nexus is then continued
# with SIGCONT and accepts a connection whose peer is already reaped.
# Expect, per the Message design section 6 step 4 (a peer reaped before
# the guard, ESRCH): the connection ends with no answer and nothing reaches
# Flow, so no Identify appears in Flow's trace and no lock is taken; and,
# per its section 9 row 24, Message's trace names ESRCH. The VM kernel must
# be 6.16 or later: before it SO_PEERPIDFD itself fails EINVAL at step 1
# for a reaped peer, and step 4 is never reached.
# A send from an unbound pane afterwards must put an Identify in Flow's
# trace, so the absence above witnesses something.
# Limit: this witnesses the ESRCH path only. No pid is reused, so a
# Message with no guard would also fail its /proc read of the dead pid; the
# test does not tell a guard from that failure.
# Forks, first option: F8 (caller read from the kernel peer).
# F6: no tiers, per design (the request carries no priority head).
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-reaped";
  forks = [
    "F6 no tiers, per design"
    "F8"
  ];
  script = ''
    start()
    configure()
    kernel = machine.succeed("uname -r").strip()
    major, minor = (int(part) for part in kernel.split(".")[:2])
    print(f"VM kernel {kernel}")
    assert (major, minor) >= (6, 16), f"kernel {kernel}: a reaped peer fails at step 1, not ESRCH at step 4"

    sender, sender_pid = open_pane("psyche")
    recipient, recipient_pid = open_pane("mind")
    bind("{ Psyche nexus Secondary }", sender_pid)
    bind("{ Mind nexus Secondary }", recipient_pid)

    nexus = main_pid("message-nexus")
    before = cursor()
    machine.succeed(f"kill -STOP {nexus}")
    machine.wait_until_succeeds(f"test \"$(cut -d' ' -f3 /proc/{nexus}/stat)\" = T", timeout=10)
    print(f"message-nexus {nexus} stopped")

    # The client connects (the listener's backlog accepts it while Message
    # is stopped), writes its whole request, then blocks reading the reply.
    datom = send_datom("{ Mind nexus Secondary }", "Order.«mfReaped request»")
    line = f"message {shlex.quote(datom)} > /tmp/reaped.reply 2>&1; echo $? > /tmp/reaped.code"
    status, typed = run(f"herdr pane run {sender} {shlex.quote(line)}")
    assert status == 0, f"herdr pane run: {typed}"
    machine.wait_until_succeeds("pgrep -u alice -f mfReaped", timeout=30)
    client = machine.succeed("pgrep -u alice -f mfReaped").split()[0]
    machine.wait_until_succeeds(f"grep -q unix_stream /proc/{client}/wchan", timeout=30)
    print(f"client {client} waits for its reply in {machine.succeed(f'cat /proc/{client}/wchan')}")

    machine.succeed(f"kill -KILL {client}")
    machine.wait_until_succeeds("test -s /tmp/reaped.code", timeout=30)
    machine.succeed(f"test ! -e /proc/{client}")
    code = machine.succeed("cat /tmp/reaped.code").strip()
    assert code == "137", f"client exit {code}, not SIGKILL"
    print(f"client {client} killed and reaped by its shell (exit {code})")

    machine.succeed(f"kill -CONT {nexus}")
    machine.wait_until_succeeds(
        "journalctl --no-pager -o cat "
        + f"--after-cursor={shlex.quote(before)} "
        + "_SYSTEMD_USER_UNIT=message-nexus.service | grep -q ESRCH",
        timeout=30,
    )
    print(trace("message-nexus", before))
    silent = trace("flow-nexus", before)
    for word in ["Identify", "Lock"]:
        assert word not in silent, f"flow-nexus traced {word} for a reaped peer:\n{silent}"
    pane_lacks(recipient, "mfReaped")

    control = cursor()
    stranger, _ = open_pane("stranger")
    expect_send_prefix(stranger, send_datom("{ Mind nexus Secondary }", "Order.«mfReapedControl request»"), "Refused.Unidentified.")
    heard = trace("flow-nexus", control)
    assert "Identify" in heard, f"flow-nexus traces no Identify, so the silence above witnesses nothing:\n{heard}"
  '';
}
