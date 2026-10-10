# Test 20. A fresh store, seeded with MetaConfigured false: an ordinary
# Configure is answered `Configured`, which shows the seed; a meta Configure
# that changes a socket path answers `RestartRequired`; an ordinary Configure
# is then `Refused.AlreadyConfigured`, so the RestartRequired answer set the
# marker.
# Forks, first option: F2.
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-marker";
  forks = [ "F2" ];
  script = ''
    start()
    payload = f'"$(cat {FIXTURES}/message.datom)"'
    moved = f'"$(sed s/message.sock/moved.sock/ {FIXTURES}/message.datom)"'
    expect("ordinary Configure on a fresh store", f"message {payload}", "Configured")
    expect("meta Configure moving the ordinary socket", f"message-meta {moved}", "RestartRequired")
    expect("ordinary Configure after RestartRequired", f"message {payload}", "Refused.AlreadyConfigured")
  '';
}
