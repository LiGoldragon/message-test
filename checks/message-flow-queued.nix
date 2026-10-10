# Test 2. A Notice to an asleep metaflow: `Queued`; Flow's `Current` shows it
# Asleep; the queue holds the one request (Flow's Metaflows lists the record
# { Address State Past Queue }). The metaflow is put to sleep by Stop of its
# bound flow, which leaves it Asleep.
# Forks, first option: F1 (Flow holds the queue), F8.
# F6: no tiers, per design (the request carries no priority head).
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
    "F6 no tiers, per design"
    "F8"
  ];
  script = ''
    start()
    configure()
    sender, sender_pid = open_pane("psyche")
    _, recipient_pid = open_pane("mind")
    bind("{ Psyche nexus Secondary }", sender_pid)
    flow_id = bind("{ Mind nexus Secondary }", recipient_pid)
    expect("Stop", f"flow 'Stop.{flow_id}'", "Stopped")
    expect("Current before", "flow 'Current.{ Mind nexus Secondary }'", "Current.Asleep")
    expect_send(sender, send_datom("{ Mind nexus Secondary }", "Notice.«mfQueued branch merged»"), "Queued")
    expect("Current after", "flow 'Current.{ Mind nexus Secondary }'", "Current.Asleep")
    listed = expect_prefix("Metaflows", "flow 'Metaflows'", "Listed.")
    assert listed.count("Notice.«mfQueued branch merged»") == 1, f"the queue does not hold the Notice once: «{listed}»"
  '';
}
