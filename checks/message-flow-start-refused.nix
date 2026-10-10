# Test 18. Flow stopped, then message-nexus started: it exits nonzero, no
# socket of Message's listens, its trace names FlowUnreachable, and it is not
# started again. Separately, a second message-nexus started while the first
# lives: it exits nonzero, its trace names Taken, and the first process still
# serves (a send succeeds).
# Forks, first option: F2.
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-start-refused";
  forks = [ "F2" ];
  script = ''
    start()
    configure()
    sender, sender_pid = open_pane("psyche")
    recipient, recipient_pid = open_pane("mind")
    bind("{ Psyche nexus Secondary }", sender_pid)
    bind("{ Mind nexus Secondary }", recipient_pid)

    # A second Message while the first lives.
    status, out = run("RUST_LOG=debug timeout 30 message-nexus 2>&1")
    print(f"second message-nexus: «{out}» (exit {status})")
    assert status != 0 and status != 124, f"the second message-nexus did not exit refused (exit {status})"
    assert "Taken" in out, f"the second message-nexus does not name Taken: «{out}»"
    expect_send(sender, send_datom("{ Mind nexus Secondary }", "Order.«mfStartRefused first serves»"), "Delivered")

    # Flow stopped, then Message started.
    for unit in ["message-nexus", "flow-nexus"]:
        status, out = run(f"systemctl --user stop {unit}.service")
        assert status == 0, f"stopping {unit}: {out}"
    before = cursor()
    run("systemctl --user start message-nexus.service")
    machine.wait_until_succeeds(as_alice("! systemctl --user is-active --quiet message-nexus.service"), timeout=30)
    result = run("systemctl --user show -p ExecMainStatus --value message-nexus.service")[1]
    assert result not in ("", "0"), f"message-nexus exited {result}"
    assert not listens("message-nexus"), "a refused message-nexus listens"
    traced = trace("message-nexus", before)
    assert "FlowUnreachable" in traced, f"message-nexus does not name FlowUnreachable:\n{traced}"
    restarts = run("systemctl --user show -p NRestarts --value message-nexus.service")[1]
    assert restarts == "0", f"message-nexus was started again {restarts} times"
  '';
}
