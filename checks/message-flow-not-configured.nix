# Message started before Flow holds Configure.Nexus: Flow refuses its start
# Bind NotConfigured, so message-nexus exits nonzero, no socket of its
# listens, and its trace names NotConfigured. (f5a6e9's ruling, current best;
# not yet a row of the Message design's section 9.)
# Forks, first option: F2.
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-not-configured";
  forks = [ "F2" ];
  script = ''
    start(flow_configured=False)
    before = cursor()
    run("systemctl --user start message-nexus.service")
    machine.wait_until_succeeds(as_alice("! systemctl --user is-active --quiet message-nexus.service"), timeout=30)
    result = run("systemctl --user show -p ExecMainStatus --value message-nexus.service")[1]
    assert result not in ("", "0"), f"message-nexus exited {result} before Configure.Nexus"
    assert not listens("message-nexus"), "message-nexus listens before Configure.Nexus"
    traced = trace("message-nexus", before)
    assert "NotConfigured" in traced, f"message-nexus does not name NotConfigured:\n{traced}"
  '';
}
