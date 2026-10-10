# Test 5. { Field nexus Tertiary } sends to { Psyche nexus Primary }, off the
# vision-aspects routes: `Refused.OffRoute`; the recipient's pane never shows
# the request; the lock is released (a direct Lock is granted).
# Forks, first option: F2, F8.
# F6: no tiers, per design (the request carries no priority head).
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-off-route";
  forks = [
    "F2"
    "F6 no tiers, per design"
    "F8"
  ];
  script = ''
    start()
    configure()
    sender, sender_pid = open_pane("field")
    recipient, recipient_pid = open_pane("psyche")
    bind("{ Field nexus Tertiary }", sender_pid)
    bind("{ Psyche nexus Primary }", recipient_pid)
    expect_send(sender, send_datom("{ Psyche nexus Primary }", "Order.«mfOffRoute»"), "Refused.OffRoute")
    pane_lacks(recipient, "mfOffRoute")
    expect_prefix("Lock after refusal", "flow 'Lock.{ Psyche nexus Primary }'", "Locked.")
  '';
}
