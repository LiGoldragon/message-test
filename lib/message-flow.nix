# The frame of a pure message-flow scenario: one NixOS virtual machine with
# user `alice` (uid 1000, lingering), and three of her user services started
# with no arguments: the real Message Nexus, the real Flow Nexus, and a
# headless Herdr server whose panes are plain shells. Both Nexuses are
# configured by their meta clients from the payload files in
# fixtures/message-flow. The scenario supplies its name, the design forks
# whose first option it is written against, and its drive (Python, using
# the helpers of message-flow.py).
{
  pkgs,
  flake,
  system,
}:
{
  name,
  forks,
  script,
}:
let
  message = flake.lib.components.message.forSystem system;
  flow = flake.lib.components.flow.forSystem system;
  herdr = flake.lib.components.herdr.forPkgs pkgs;

  # A user service of alice's, started with no arguments, tracing on.
  nexusService = executable: {
    wantedBy = [ "default.target" ];
    unitConfig.ConditionUser = "alice";
    environment.RUST_LOG = "debug";
    serviceConfig.ExecStart = executable;
  };
in
pkgs.testers.runNixOSTest {
  inherit name;

  nodes.machine = _: {
    virtualisation.memorySize = 2048;

    users.users.alice = {
      isNormalUser = true;
      uid = 1000;
      linger = true;
    };

    environment.systemPackages = [
      message.package
      flow.package
      herdr.package
      pkgs.jq
    ];

    environment.etc."message-test".source = ../fixtures/message-flow;

    systemd.user.services = {
      message-nexus = nexusService message.nexus;
      flow-nexus = nexusService flow.nexus;
      herdr = {
        wantedBy = [ "default.target" ];
        unitConfig.ConditionUser = "alice";
        path = [ "/run/current-system/sw" ];
        environment.SHELL = "${pkgs.bashInteractive}/bin/bash";
        serviceConfig.ExecStart = "${herdr.bin} server";
      };
    };
  };

  testScript = ''
    NAME = "${name}"
    FORKS = "${builtins.concatStringsSep " " forks}"
    ${builtins.readFile ./message-flow.py}
    ${script}
  '';
}
