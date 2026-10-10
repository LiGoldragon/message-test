# Test 13. A fresh store: `Configure` on the ordinary socket is answered
# `Configured` while MetaConfigured is false; a meta `Configure` answers
# `Configured` and sets it true; the same ordinary `Configure` is then
# `Refused.AlreadyConfigured`. The payload names the default paths, so no
# restart is asked.
# Forks, first option: F2 (the payload's Flow edge is Flow's ordinary socket).
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-first-configure";
  forks = [ "F2" ];
  script = ''
    start()
    payload = f'"$(cat {FIXTURES}/message.datom)"'
    expect("ordinary Configure on a fresh store", f"message {payload}", "Configured")
    expect("meta Configure", f"message-meta {payload}", "Configured")
    expect("ordinary Configure after meta", f"message {payload}", "Refused.AlreadyConfigured")
  '';
}
