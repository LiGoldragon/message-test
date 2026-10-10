# Test 29. A fresh Flow with no Configure.Nexus, then message-nexus started:
# Flow refuses its start Bind NotConfigured, so message-nexus exits nonzero,
# no socket of its listens, and its trace names NotConfigured. After
# Configure.Nexus a start binds and the send of test 1 succeeds.
# Forks, first option: F2, F8.
# F6: no tiers, per design (the request carries no priority head).
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-not-configured";
  forks = [
    "F2"
    "F6 no tiers, per design"
    "F8"
  ];
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
    configure_flow()
    status, out = run("systemctl --user start message-nexus.service")
    assert status == 0, f"starting message-nexus: {out}"
    listening("message-nexus")
    configure()
    sender, sender_pid = open_pane("psyche")
    recipient, recipient_pid = open_pane("mind")
    bind("{ Psyche nexus Secondary }", sender_pid)
    bind("{ Mind nexus Secondary }", recipient_pid)
    expect_send(sender, send_datom("{ Mind nexus Secondary }", "Order.«mfNotConfigured build the lock path»"), "Delivered")
    pane_shows(recipient, "Order.«mfNotConfigured build the lock path»")
  '';
}
