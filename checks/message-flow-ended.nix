# Test 4. A send to an Ended metaflow: `Refused.Ended.{ Mind nexus Secondary }`
# (the request returns to its sender), and its pane never shows the request.
# Forks, first option: F6, F8.
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-ended";
  forks = [
    "F6"
    "F8"
  ];
  script = ''
    start()
    configure()
    sender, sender_pid = open_pane("psyche")
    recipient, recipient_pid = open_pane("mind")
    bind("{ Psyche nexus Secondary }", sender_pid)
    bind("{ Mind nexus Secondary }", recipient_pid)
    expect("End", "flow 'End.{ Mind nexus Secondary }'", "Ended")
    expect_send(sender, send_datom("{ Mind nexus Secondary }", "Order.«mfEnded»"), "Refused.Ended.{ Mind nexus Secondary }")
  '';
}
