# Test 9. `Up` from { Mind nexus Primary }, the top layer of its aspect:
# Flow refuses the lock NoneAbove and Message answers `Refused.NoneAbove`;
# no Deliver appears in Message's trace, and the layer below, also awake,
# never shows the request.
# Forks, first option: F8.
# F7: Flow resolves Up, per design.
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
    "F7 Flow resolves Up, per design"
    "F8"
  ];
  script = ''
    start()
    configure()
    sender, sender_pid = open_pane("primary")
    below, below_pid = open_pane("secondary")
    bind("{ Mind nexus Primary }", sender_pid)
    bind("{ Mind nexus Secondary }", below_pid)
    before = cursor()
    expect_send(sender, send_datom("Up", "Result.«mfNoneAbove»"), "Refused.NoneAbove")
    traced = trace("message-nexus", before)
    assert "Deliver" not in traced, f"message-nexus traced a Deliver for a refused Up:\n{traced}"
    pane_lacks(below, "mfNoneAbove")
  '';
}
