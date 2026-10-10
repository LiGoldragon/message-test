# Test 28. A message-nexus from another store path than the
# MessageNexusBinary Flow holds (a copy of the same executable in its own
# derivation) is started: Flow answers its Bind NotMessage, it exits nonzero
# naming NotMessage, and no socket of it listens.
# Forks, first option: F2.
{
  pkgs,
  flake,
  system,
  ...
}:
let
  message = flake.lib.components.message.forSystem system;
  other = pkgs.runCommand "message-nexus-other" { } ''
    mkdir -p $out/bin
    cp ${message.nexus} $out/bin/message-nexus-other
  '';
in
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-wrong-binary";
  forks = [ "F2" ];
  packages = [ other ];
  script = ''
    start(flow_configured=False)
    configure_flow()
    status, out = run("RUST_LOG=debug timeout 30 message-nexus-other 2>&1")
    print(f"message-nexus-other: «{out}» (exit {status})")
    assert status != 0 and status != 124, f"message-nexus-other did not exit refused (exit {status})"
    assert "NotMessage" in out, f"message-nexus-other does not name NotMessage: «{out}»"
    # The kernel keeps a command name to 15 characters.
    assert not listens("message-nexus-o"), "message-nexus-other listens"
  '';
}
