# Test 19. message-nexus killed, then started again: Flow's trace shows the
# new process's Bind answered Bound, and the send of test 1 succeeds.
# Forks, first option: F2, F8.
# F6: no tiers, per design (the request carries no priority head).
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-rebind";
  forks = [
    "F2"
    "F6 no tiers, per design"
    "F8"
  ];
  script = ''
    start()
    configure()
    sender, sender_pid = open_pane("psyche")
    recipient, recipient_pid = open_pane("mind")
    bind("{ Psyche nexus Secondary }", sender_pid)
    bind("{ Mind nexus Secondary }", recipient_pid)
    before = cursor()
    run("systemctl --user kill --signal=KILL message-nexus.service")
    machine.wait_until_succeeds(as_alice("! systemctl --user is-active --quiet message-nexus.service"), timeout=30)
    status, out = run("systemctl --user start message-nexus.service")
    assert status == 0, f"starting message-nexus: {out}"
    bound(f"{RUNTIME}/message/message.sock")
    pid = main_pid("message-nexus")
    trace_in_order("flow-nexus", ["Bind", "{ Field message Primary }", pid, "Bound"], before)
    expect_send(sender, send_datom("{ Mind nexus Secondary }", "Order.«mfRebind build the lock path»"), "Delivered")
    pane_shows(recipient, "Order.«mfRebind build the lock path»")
  '';
}
