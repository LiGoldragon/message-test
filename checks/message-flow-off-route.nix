# Test 5. { Field nexus Tertiary } sends to { Psyche nexus Primary }, off the
# vision-aspects routes: `Refused.OffRoute` from the lock request; no lock
# record (a direct Lock.{ Sender Recipient } from { Psyche nexus Secondary },
# up its own stack, is granted); no Deliver or Release in Message's trace;
# the recipient's pane never shows the request.
# Forks, first option: F2, F8.
# F6: no tiers, per design (the request carries no priority head).
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-off-route";
  forks = [
    "F2"
    "F6 no tiers, per design"
    "F8"
  ];
  script = ''
    start()
    configure()
    sender, sender_pid = open_pane("field")
    recipient, recipient_pid = open_pane("psyche")
    bind("{ Field nexus Tertiary }", sender_pid)
    bind("{ Psyche nexus Primary }", recipient_pid)
    before = cursor()
    expect_send(sender, send_datom("{ Psyche nexus Primary }", "Order.«mfOffRoute»"), "Refused.OffRoute")
    traced = trace("message-nexus", before)
    for word in ["Deliver", "Release"]:
        assert word not in traced, f"message-nexus traced {word} after OffRoute:\n{traced}"
    pane_lacks(recipient, "mfOffRoute")
    lock_of(flow_lock("{ Psyche nexus Secondary }", "{ Psyche nexus Primary }"))
  '';
}
