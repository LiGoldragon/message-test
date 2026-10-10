# Test 27. The sender's metaflow is Ended in Flow while its stand-in shell
# still runs, then that shell sends: Refused.Ended.Address naming the sender,
# matched by its head and the address. That no lock record is left is not
# observable from outside Message.
# Forks, first option: F8.
# F6: no tiers, per design (the request carries no priority head).
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-sender-ended";
  forks = [
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
    expect("End of the sender", "flow 'End.{ Psyche nexus Secondary }'", "Ended")
    machine.succeed(f"kill -0 {sender_pid}")
    reply = expect_send_prefix(sender, send_datom("{ Mind nexus Secondary }", "Order.«mfSenderEnded request»"), "Refused.Ended.")
    assert "Psyche nexus Secondary" in reply, f"Ended does not name the sender: «{reply}»"
    pane_lacks(recipient, "mfSenderEnded")
  '';
}
