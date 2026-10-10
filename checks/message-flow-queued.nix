# Test 2. A Notice to an asleep metaflow: `Queued`, and Flow's `Current`
# still shows it Asleep. The metaflow is made asleep by binding a pane shell
# and closing that pane; Flow's design names no request that puts a metaflow
# to sleep, so the precondition is asserted before the send. Flow's Signal at
# e17a62ca has no query that shows a metaflow's Queue, so the queue's one
# request is witnessed only by the semi-sandbox's wake (test 15).
# Forks, first option: F1 (Flow holds the queue), F6, F8.
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-queued";
  forks = [
    "F1"
    "F6"
    "F8"
  ];
  script = ''
    start()
    configure()
    sender, sender_pid = open_pane("psyche")
    recipient, recipient_pid = open_pane("mind")
    bind("{ Psyche nexus Secondary }", sender_pid)
    bind("{ Mind nexus Secondary }", recipient_pid)
    run(f"herdr pane close {recipient}")
    expect("Current before", "flow 'Current.{ Mind nexus Secondary }'", "Current.Asleep")
    expect_send(sender, send_datom("{ Mind nexus Secondary }", "Notice.«mfQueued branch merged»"), "Queued")
    expect("Current after", "flow 'Current.{ Mind nexus Secondary }'", "Current.Asleep")
  '';
}
