# Test 3. A send to a metaflow that does not exist: Refused.Unknown.Address
# naming { Mind ghost Secondary }, and no lock record is left (a direct
# Lock.{ Sender Recipient } on it is refused Unknown, never Held). The design
# writes no print of Unknown.[ Address Lock ], so the reply is matched by its
# head and the address it names.
# Forks, first option: F8.
# F6: no tiers, per design (the request carries no priority head).
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-unknown";
  forks = [
    "F6 no tiers, per design"
    "F8"
  ];
  script = ''
    start()
    configure()
    sender, sender_pid = open_pane("psyche")
    bind("{ Psyche nexus Secondary }", sender_pid)
    reply = expect_send_prefix(sender, send_datom("{ Mind ghost Secondary }", "Order.«mfUnknown»"), "Refused.Unknown.")
    assert "Mind ghost Secondary" in reply, f"Unknown names no address: «{reply}»"
    locked = flow_lock("{ Psyche nexus Secondary }", "{ Mind ghost Secondary }")
    assert locked.startswith("Refused.Unknown.") and "Mind ghost Secondary" in locked, f"direct Lock: «{locked}»"
  '';
}
