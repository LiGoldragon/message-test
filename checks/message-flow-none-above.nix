# Test 8. `Up` from a Primary: Flow, resolving Up, finds no layer above
# within the sender's aspect and refuses; Message answers `Refused.NoneAbove`,
# and the layer below, also awake, never shows the request.
# Forks, first option: F8.
# F7: Flow resolves Up, per f5a6e9's ruling.
# F6: no tiers, per design (the request carries no priority head).
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-none-above";
  forks = [
    "F6 no tiers, per design"
    "F7 Flow resolves Up, per f5a6e9's ruling"
    "F8"
  ];
  script = ''
    start()
    configure()
    sender, sender_pid = open_pane("primary")
    below, below_pid = open_pane("secondary")
    bind("{ Mind nexus Primary }", sender_pid)
    bind("{ Mind nexus Secondary }", below_pid)
    expect_send(sender, send_datom("Up", "Result.«mfNoneAbove»"), "Refused.NoneAbove")
    pane_lacks(below, "mfNoneAbove")
  '';
}
