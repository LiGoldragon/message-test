# Test 6. { Field nexus Secondary } sends to { Mind nexus Secondary }, same
# layer and topic across aspects: `Delivered`, and the recipient's pane shows
# the sender and the request.
# Forks, first option: F4, F8, F10.
# F6: no tiers, per design (the request carries no priority head).
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-same-layer";
  forks = [
    "F4"
    "F6 no tiers, per design"
    "F8"
    "F10"
  ];
  script = ''
    start()
    configure()
    sender, sender_pid = open_pane("field")
    recipient, recipient_pid = open_pane("mind")
    bind("{ Field nexus Secondary }", sender_pid)
    bind("{ Mind nexus Secondary }", recipient_pid)
    expect_send(sender, send_datom("{ Mind nexus Secondary }", "Question.«mfSameLayer which revision»"), "Delivered")
    pane_shows(recipient, "{ Field nexus Secondary }")
    pane_shows(recipient, "Question.«mfSameLayer which revision»")
  '';
}
