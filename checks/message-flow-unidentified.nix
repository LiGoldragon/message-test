# Test 9. `message` run from a shell in no flow's pane (a Herdr pane bound to
# no metaflow): `Refused.Unidentified.<pid>`.
# Forks, first option: F6, F8 (caller read from the kernel peer), F11
# (senders that are no metaflow are refused Unidentified).
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-unidentified";
  forks = [
    "F6"
    "F8"
    "F11"
  ];
  script = ''
    start()
    configure()
    stranger, _ = open_pane("stranger")
    recipient, recipient_pid = open_pane("mind")
    bind("Mind.{ nexus Secondary }", recipient_pid)
    expect_send_prefix(stranger, send_datom("To.Mind.{ nexus Secondary }", "Order.«mfUnidentified»"), "Refused.Unidentified.")
    pane_lacks(recipient, "mfUnidentified")
  '';
}
