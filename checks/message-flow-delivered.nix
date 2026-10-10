# Test 1. { Psyche nexus Secondary } sends an Order to the awake
# { Mind nexus Secondary }: `Delivered`; Message's trace runs Identified,
# Locked, Delivered in that order; the recipient's pane shows the sender and
# the request; the lock is gone (a direct Lock on the recipient is granted).
# Forks, first option: F2 (Lock and Deliver on Flow's ordinary socket), F4
# (end of the prompt), F6 (Priority head), F8 (caller read from the kernel peer), F9 (the
# request a String in the Nexus), F10 (Flow textualizes into the pane).
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-delivered";
  forks = [
    "F2"
    "F4"
    "F6"
    "F8"
    "F9"
    "F10"
  ];
  script = ''
    start()
    configure()
    sender, sender_pid = open_pane("psyche")
    recipient, recipient_pid = open_pane("mind")
    bind("{ Psyche nexus Secondary }", sender_pid)
    bind("{ Mind nexus Secondary }", recipient_pid)
    before = cursor()
    expect_send(sender, send_datom("{ Mind nexus Secondary }", "Order.«mfDelivered build the lock path»"), "Delivered")
    trace_in_order("message-nexus", ["Identified", "Locked", "Delivered"], before)
    pane_shows(recipient, "{ Psyche nexus Secondary }")
    pane_shows(recipient, "Order.«mfDelivered build the lock path»")
    expect_prefix("Lock after delivery", "flow 'Lock.{ Mind nexus Secondary }'", "Locked.")
  '';
}
