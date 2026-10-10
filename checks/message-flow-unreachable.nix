# Test 11. Flow stopped, then a send: `Refused.FlowUnreachable`.
# Forks, first option: F2 (the Flow edge is Flow's ordinary socket).
# F6: no tiers, per design (the request carries no priority head).
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-unreachable";
  forks = [
    "F2"
    "F6 no tiers, per design"
  ];
  script = ''
    start()
    configure()
    sender, sender_pid = open_pane("psyche")
    recipient, recipient_pid = open_pane("mind")
    bind("{ Psyche nexus Secondary }", sender_pid)
    bind("{ Mind nexus Secondary }", recipient_pid)
    status, out = run("systemctl --user stop flow-nexus.service")
    assert status == 0, f"stopping flow-nexus: {out}"
    expect_send(sender, send_datom("{ Mind nexus Secondary }", "Order.«mfUnreachable»"), "Refused.FlowUnreachable")
  '';
}
