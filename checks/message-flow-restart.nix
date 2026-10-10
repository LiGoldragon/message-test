# Test 13. Message restarted, again with no arguments, on its existing store:
# the send of test 1 is `Delivered` with no new Configure.
# Forks, first option: F2, F8.
# F6: no tiers, per design (the request carries no priority head).
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
    "F6 no tiers, per design"
    "F8"
  ];
  script = ''
    start()
    configure()
    sender, sender_pid = open_pane("psyche")
    recipient, recipient_pid = open_pane("mind")
    bind("{ Psyche nexus Secondary }", sender_pid)
    bind("{ Mind nexus Secondary }", recipient_pid)
    status, out = run("systemctl --user restart message-nexus.service")
    assert status == 0, f"restarting message-nexus: {out}"
    bound(f"{RUNTIME}/message/message.sock")
    pid = run("systemctl --user show -p MainPID --value message-nexus.service")[1]
    arguments = machine.succeed(f"tr '\\0' '\\n' < /proc/{pid}/cmdline").split()
    assert len(arguments) == 1, f"message-nexus restarted with arguments {arguments}"
    expect_send(sender, send_datom("{ Mind nexus Secondary }", "Order.«mfRestart build the lock path»"), "Delivered")
    pane_shows(recipient, "Order.«mfRestart build the lock path»")
  '';
}
