# Test 7. A send up: { Mind nexus Secondary } sends to { Mind nexus Primary },
# the address one layer above its own in the same aspect and topic, written
# by the sender (Message design, section 7.4: Message resolves nothing);
# `Delivered`, and that pane shows the sender and the request.
# Forks, first option: F4, F8, F10.
# F7: no Up, per design (Send carries an Address).
# F6: no tiers, per design (the request carries no priority head).
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-up";
  forks = [
    "F4"
    "F6 no tiers, per design"
    "F7 no Up, per design"
    "F8"
    "F10"
  ];
  script = ''
    start()
    configure()
    sender, sender_pid = open_pane("secondary")
    recipient, recipient_pid = open_pane("primary")
    bind("{ Mind nexus Secondary }", sender_pid)
    bind("{ Mind nexus Primary }", recipient_pid)
    expect_send(sender, send_datom("{ Mind nexus Primary }", "Result.«mfUp message-flow passes»"), "Delivered")
    pane_shows(recipient, "{ Mind nexus Secondary }")
    pane_shows(recipient, "Result.«mfUp message-flow passes»")
  '';
}
