# Test 17. A plain client, the `flow` CLI and not the Message process, sends
# Flow Lock.{ Sender Recipient }, Deliver.{ Lock Request } and Release.Lock
# on Flow's ordinary socket: each `Refused.NotMessage`; an Identify.Process
# from the same client is answered, not refused NotMessage. That no lock
# record is left is not observable from outside Message.
# Forks, first option: F2, F8.
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-not-message";
  forks = [
    "F2"
    "F8"
  ];
  script = ''
    start()
    configure()
    _, sender_pid = open_pane("psyche")
    _, recipient_pid = open_pane("mind")
    bind("{ Psyche nexus Secondary }", sender_pid)
    bind("{ Mind nexus Secondary }", recipient_pid)
    until = int(machine.succeed("date +%s").strip()) + 60
    lock = f"{{ {{ Psyche nexus Secondary }} {{ Mind nexus Secondary }} {until} }}"
    expect("Lock", "flow 'Lock.{ { Psyche nexus Secondary } { Mind nexus Secondary } }'", "Refused.NotMessage")
    expect("Deliver", f"flow 'Deliver.{{ {lock} Order.«mfNotMessage request» }}'", "Refused.NotMessage")
    expect("Release", f"flow 'Release.{lock}'", "Refused.NotMessage")
    status, identified = run(f"flow 'Identify.{{ {sender_pid} {started_of(sender_pid)} }}'")
    print(f"Identify: «{identified}» (exit {status})")
    assert identified and identified != "Refused.NotMessage", f"Identify was not answered: «{identified}»"
  '';
}
