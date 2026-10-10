# Test 16. message-nexus started: Flow's trace shows the Bind of
# { Field message Primary } with Message's own pid and start time, and a
# send then succeeds. That the Bind comes before Message's first listen is
# not checked: no design writes Message's trace of a listen.
# Forks, first option: F2, F8.
# F6: no tiers, per design (the request carries no priority head).
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-bind";
  forks = [
    "F2"
    "F6 no tiers, per design"
    "F8"
  ];
  script = ''
    start()
    configure()
    pid = main_pid("message-nexus")
    started = started_of(pid)
    trace_in_order("flow-nexus", ["Bind", "{ Field message Primary }", pid, started])
    sender, sender_pid = open_pane("psyche")
    recipient, recipient_pid = open_pane("mind")
    bind("{ Psyche nexus Secondary }", sender_pid)
    bind("{ Mind nexus Secondary }", recipient_pid)
    expect_send(sender, send_datom("{ Mind nexus Secondary }", "Order.«mfBind build the lock path»"), "Delivered")
    pane_shows(recipient, "Order.«mfBind build the lock path»")
  '';
}
