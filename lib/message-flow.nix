# The frame of a pure message-flow scenario: one NixOS virtual machine with
# user `alice` (uid 1000, lingering), and three of her user services: the
# real Flow Nexus started at boot with Start.{ ordinary meta } under her
# runtime directory, the real Message Nexus started with no arguments by the
# scenario once Flow holds Configure.Nexus, and a
# headless Herdr server whose panes are plain shells. Both Nexuses are
# configured by their meta clients from the payload files in
# fixtures/message-flow; Message is restarted on its persisted configuration.
# The scenario supplies its name, the design forks
# whose first option it is written against, and its drive (Python, using
# the helpers of message-flow.py), and any packages it alone needs.
{
  pkgs,
  flake,
  system,
}:
{
  name,
  forks,
  script,
  packages ? [ ],
}:
let
  message = flake.lib.components.message.forSystem system;
  flow = flake.lib.components.flow.forSystem system;
  herdr = flake.lib.components.herdr.forPkgs pkgs;

  # A user service of alice's running the given command line, tracing on.
  nexusService = executable: {
    unitConfig.ConditionUser = "alice";
    environment.RUST_LOG = "debug";
    serviceConfig.ExecStart = executable;
  };

  # Flow's Configure.Nexus for the VM. MessageNexusBinary is the
  # message-nexus under test; every other field is a VM-local fixture value
  # that no pure scenario exercises (no pure scenario launches a flow).
  flowNexus = ''
    Configure.Nexus.{ /home/alice/source
                      { /home/alice/codex/stable/codex /home/alice/codex/stable /run/user/1000/codex/stable.sock [ luna ] }
                      { /home/alice/codex/next/codex /home/alice/codex/next /run/user/1000/codex/next.sock [ luna ] }
                      [ { Codex [ / ] [ Escape ] [ Enter ] } { Claude [ / ] [ Escape ] [ Enter ] } ]
                      [ Field ]
                      /run/user/1000/${message.ordinarySocket}
                      ${message.nexus}
                      60 }
  '';
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

    environment.systemPackages = packages ++ [
      message.package
      flow.package
      herdr.package
      pkgs.iproute2
      pkgs.jq
    ];

    environment.etc."message-test".source = ../fixtures/message-flow;
    environment.etc."message-test-flow-nexus.datom".text = flowNexus;

    systemd.user.services = {
      message-nexus = nexusService message.nexus;
      # Flow's sockets come only from its start command.
      flow-nexus = {
        wantedBy = [ "default.target" ];
      }
      // nexusService "${flow.nexus} \"Start.{ /run/user/1000/${flow.ordinarySocket} /run/user/1000/${flow.metaSocket} }\"";
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
    MESSAGE_NEXUS = "${message.nexus}"
    ${builtins.readFile ./message-flow.py}
    ${script}
  '';
}
