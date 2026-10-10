# The rig the message-flow scenarios stand on: a headless Herdr server as a
# user service of alice's inside a NixOS virtual machine, with no terminal
# attached. A pane is opened, its shell pid read, a command typed into it,
# and its output read back; the pane carries HERDR_PANE_ID. Drives no Nexus.
{
  pkgs,
  flake,
  ...
}:
let
  herdr = flake.lib.components.herdr.forPkgs pkgs;
in
pkgs.testers.runNixOSTest {
  name = "herdr";

  nodes.machine = _: {
    users.users.alice = {
      isNormalUser = true;
      uid = 1000;
      linger = true;
    };
    environment.systemPackages = [ herdr.package ];
    systemd.user.services.herdr = {
      wantedBy = [ "default.target" ];
      unitConfig.ConditionUser = "alice";
      path = [ "/run/current-system/sw" ];
      environment.SHELL = "${pkgs.bashInteractive}/bin/bash";
      serviceConfig.ExecStart = "${herdr.bin} server";
    };
  };

  testScript = ''
    import json
    import shlex


    def alice(command):
        inner = "export XDG_RUNTIME_DIR=/run/user/1000; " + command
        return machine.succeed("su -l alice -c " + shlex.quote(inner)).strip()


    machine.wait_for_unit("herdr.service", user="alice")
    machine.wait_until_succeeds("su -l alice -c 'XDG_RUNTIME_DIR=/run/user/1000 herdr workspace list'", timeout=60)
    created = json.loads(alice("herdr workspace create --cwd /home/alice --label rig --no-focus"))
    pane = created["result"]["root_pane"]["pane_id"]
    info = json.loads(alice(f"herdr pane process-info --pane {pane}"))
    pid = info["result"]["process_info"]["shell_pid"]
    assert int(pid) > 1, f"no shell pid for {pane}: {info}"
    alice(f"herdr pane run {pane} " + shlex.quote("echo rig-$HERDR_PANE_ID-$$"))
    alice(f"herdr pane wait-output --match {shlex.quote(f'rig-{pane}-{pid}')} --timeout 15000 {pane}")
  '';
}
