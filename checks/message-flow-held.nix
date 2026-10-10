# Test 11. A lock on M taken directly from Flow, Lock.{ Sender Recipient },
# then a send to M:
# `Refused.Held.<lock>`, the request returned to its sender (never shown in
# M's pane). The machine's clock is then set past the lock's Until (Flow
# judges a lapse by comparing Until with now, on the next request), and the
# same send is `Delivered`.
# Forks, first option: F2, F3 (a refused send returns to its sender),
# F8.
# F6: no tiers, per design (the request carries no priority head).
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-held";
  forks = [
    "F2"
    "F3"
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
    until = lock_until(lock_of(flow_lock("{ Psyche nexus Secondary }", "{ Mind nexus Secondary }")))
    datom = send_datom("{ Mind nexus Secondary }", "Order.«mfHeld»")
    expect_send_prefix(sender, datom, "Refused.Held.")
    pane_lacks(recipient, "Order.«mfHeld»")
    machine.succeed(f"date -s @{until + 1}")
    expect_send(sender, datom, "Delivered")
    pane_shows(recipient, "Order.«mfHeld»")
  '';
}
