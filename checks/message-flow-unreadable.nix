# Test 15. An unreadable datom given to `message`: the CLI refuses it (a
# nonzero exit) and the Nexus trace shows no connection. A readable request
# afterwards (an ordinary Configure, refused AlreadyConfigured) shows that the
# Nexus trace does record a connection.
# Forks: none.
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-unreadable";
  forks = [ ];
  script = ''
    start()
    configure()
    before = cursor()
    status, out = run("message 'Send.{ { Mind nexus'")
    print(f"unreadable: «{out}» (exit {status})")
    assert status != 0, "message accepted an unreadable datom"
    silent = trace("message-nexus", before)
    assert silent.strip() == "", f"message-nexus traced a connection for an unreadable datom:\n{silent}"
    expect("control", f'message "$(cat {FIXTURES}/message.datom)"', "Refused.AlreadyConfigured")
    heard = trace("message-nexus", before)
    assert heard.strip() != "", "message-nexus traces nothing for a connection, so the silence above witnesses nothing"
  '';
}
