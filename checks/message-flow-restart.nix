# Test 13. Message restarted, again with no arguments, on its existing store:
# the send of test 1 is `Delivered` with no new Configure.
# Forks, first option: F2, F5, F6, F8.
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-restart";
  forks = [
    "F2"
    "F5"
    "F6"
    "F8"
  ];
  script = ''
    start()
    configure()
    sender, sender_pid = open_pane("psyche")
    recipient, recipient_pid = open_pane("mind")
    bind("Psyche.{ nexus Secondary }", sender_pid)
    bind("Mind.{ nexus Secondary }", recipient_pid)
    machine.succeed(f"touch {RUNTIME}/restart-mark")
    status, out = run("systemctl --user restart message-nexus.service")
    assert status == 0, f"restarting message-nexus: {out}"
    machine.wait_until_succeeds(f"test {RUNTIME}/message/message.sock -nt {RUNTIME}/restart-mark", timeout=30)
    pid = run("systemctl --user show -p MainPID --value message-nexus.service")[1]
    arguments = machine.succeed(f"tr '\\0' '\\n' < /proc/{pid}/cmdline").split()
    assert len(arguments) == 1, f"message-nexus restarted with arguments {arguments}"
    expect_send(sender, send_datom("To.Mind.{ nexus Secondary }", "Order.«mfRestart build the lock path»"), "Delivered")
    pane_shows(recipient, "Order.«mfRestart build the lock path»")
  '';
}
