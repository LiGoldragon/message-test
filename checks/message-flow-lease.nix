# Test 20. Flow started with no Lease in Configure.Nexus, then a lock: the
# Until of Locked.Lock is 60 seconds past the grant.
# Forks, first option: F2.
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-lease";
  forks = [ "F2" ];
  script = ''
    start()
    configure()
    _, sender_pid = open_pane("psyche")
    _, recipient_pid = open_pane("mind")
    bind("{ Psyche nexus Secondary }", sender_pid)
    bind("{ Mind nexus Secondary }", recipient_pid)
    before = now()
    until = lock_until(lock_of(flow_lock("{ Psyche nexus Secondary }", "{ Mind nexus Secondary }")))
    after = now()
    assert before + 60 <= until <= after + 60, f"Until {until} is not 60 seconds past a grant between {before} and {after}"
  '';
}
