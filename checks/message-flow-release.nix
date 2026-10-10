# Test 17. Flow's Release.Lock of a lock after its Deliver: Unknown.Lock; of
# a lapsed lock (the clock set past its Until): Lapsed; of a lock never
# granted: Unknown.Lock. Flow answers these as refusals; Unknown.Lock is
# matched by its head, since the design writes no print of it.
# Forks, first option: F2 (Lock, Deliver and Release on Flow's ordinary
# socket).
{
  pkgs,
  flake,
  system,
  ...
}:
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-release";
  forks = [ "F2" ];
  script = ''
    start()
    configure()
    _, sender_pid = open_pane("psyche")
    _, recipient_pid = open_pane("mind")
    bind("{ Psyche nexus Secondary }", sender_pid)
    bind("{ Mind nexus Secondary }", recipient_pid)
    sender, recipient = "{ Psyche nexus Secondary }", "{ Mind nexus Secondary }"

    used = lock_of(flow_lock(sender, recipient))
    expect("Deliver", f"flow 'Deliver.{{ {used} Notice.«mfRelease» }}'", "Delivered")
    expect_prefix("Release after Deliver", f"flow 'Release.{used}'", "Refused.Unknown.")

    lapsed = lock_of(flow_lock(sender, recipient))
    machine.succeed(f"date -s @{lock_until(lapsed) + 1}")
    expect("Release of a lapsed lock", f"flow 'Release.{lapsed}'", "Refused.Lapsed")

    never = f"{{ {sender} {recipient} {now() + 60} }}"
    expect_prefix("Release of a lock never granted", f"flow 'Release.{never}'", "Refused.Unknown.")
  '';
}
