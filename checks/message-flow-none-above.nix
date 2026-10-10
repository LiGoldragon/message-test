# Test 8. `Up` from a Primary: `Refused.NoneAbove`, and Flow's trace shows no
# Lock for it. A control send down to Mind.{ nexus Secondary } first shows
# that Flow's trace does name Lock when Message asks for one.
# Forks, first option: F5, F6, F7 (Message resolves Up), F8.
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-none-above";
  forks = [
    "F5"
    "F6"
    "F7"
    "F8"
  ];
  script = ''
    start()
    configure()
    sender, sender_pid = open_pane("primary")
    below, below_pid = open_pane("secondary")
    bind("Mind.{ nexus Primary }", sender_pid)
    bind("Mind.{ nexus Secondary }", below_pid)
    control = cursor()
    expect_send(sender, send_datom("To.Mind.{ nexus Secondary }", "Order.«mfNoneAboveControl»"), "Delivered")
    trace_in_order("flow-nexus", ["Lock"], control)
    before = cursor()
    expect_send(sender, send_datom("Up", "Result.«mfNoneAbove»"), "Refused.NoneAbove")
    after = trace("flow-nexus", before)
    assert "Lock" not in after, f"Flow was asked for a lock on Up from a Primary:\n{after}"
  '';
}
