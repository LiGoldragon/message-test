# Test 3. A send to a metaflow that does not exist:
# `Refused.Unknown.Mind.{ ghost Secondary }`, and no lock record is left
# (a direct Lock on it is refused Unknown, never Held).
# Forks, first option: F5, F6, F8.
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-unknown";
  forks = [
    "F5"
    "F6"
    "F8"
  ];
  script = ''
    start()
    configure()
    sender, sender_pid = open_pane("psyche")
    bind("Psyche.{ nexus Secondary }", sender_pid)
    expect_send(sender, send_datom("To.Mind.{ ghost Secondary }", "Order.«mfUnknown»"), "Refused.Unknown.Mind.{ ghost Secondary }")
    expect("Lock after refusal", "flow 'Lock.Mind.{ ghost Secondary }'", "Refused.Unknown.Mind.{ ghost Secondary }")
  '';
}
