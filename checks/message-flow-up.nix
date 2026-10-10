# Test 7. `Up` from { Mind nexus Secondary }: Flow resolves it to
# { Mind nexus Primary } (the layer above within the sender's aspect);
# `Delivered`, and that pane shows the sender and the request.
# Forks, first option: F4, F8, F10.
# F7: Flow resolves Up, per f5a6e9's ruling.
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
    "F7 Flow resolves Up, per f5a6e9's ruling"
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
    expect_send(sender, send_datom("Up", "Result.«mfUp message-flow passes»"), "Delivered")
    pane_shows(recipient, "{ Mind nexus Secondary }")
    pane_shows(recipient, "Result.«mfUp message-flow passes»")
  '';
}
