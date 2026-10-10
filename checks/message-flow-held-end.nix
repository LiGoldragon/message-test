# Test 19. Flow's End of M while a lock on M is held: Refused.Held.Lock;
# after the lock is released, the same End proceeds: Ended. The lock is
# taken directly from Flow, Lock.{ Sender Recipient }, since Message holds
# its own lock only inside one Send; Flow refuses End under any held lock.
# Refresh, the other call the design names, needs a launched harness.
# Forks, first option: F2.
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-held-end";
  forks = [ "F2" ];
  script = ''
    start()
    configure()
    _, sender_pid = open_pane("psyche")
    _, recipient_pid = open_pane("mind")
    bind("{ Psyche nexus Secondary }", sender_pid)
    bind("{ Mind nexus Secondary }", recipient_pid)
    held = lock_of(flow_lock("{ Psyche nexus Secondary }", "{ Mind nexus Secondary }"))
    expect_prefix("End under a held lock", "flow 'End.{ Mind nexus Secondary }'", "Refused.Held.")
    expect("Release", f"flow 'Release.{held}'", "Released")
    expect("End after release", "flow 'End.{ Mind nexus Secondary }'", "Ended")
  '';
}
