# Test 16. Flow's Deliver.{ Lock Request } under a lock Flow never granted:
# Refused.Unknown.Lock, matched by its head (the design writes no print of
# it); the recipient's pane never shows the request.
# Forks, first option: F2 (Deliver on Flow's ordinary socket).
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-unknown-lock";
  forks = [ "F2" ];
  script = ''
    start()
    configure()
    _, sender_pid = open_pane("psyche")
    recipient, recipient_pid = open_pane("mind")
    bind("{ Psyche nexus Secondary }", sender_pid)
    bind("{ Mind nexus Secondary }", recipient_pid)
    never = f"{{ {{ Psyche nexus Secondary }} {{ Mind nexus Secondary }} {now() + 60} }}"
    expect_prefix("Deliver under a lock never granted", f"flow 'Deliver.{{ {never} Order.«mfNeverGranted» }}'", "Refused.Unknown.")
    pane_lacks(recipient, "mfNeverGranted")
  '';
}
