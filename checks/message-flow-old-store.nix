# Test 21. A version-1 store of old Message at the store path: message-nexus
# refuses to start, its trace names the store path, and the file's checksum
# is unchanged. The store is made by running old Message (0.19.1, the
# `message-old` input) once on an empty store path. That the trace names
# version 1 is matched only as the store path, since no design writes the
# refusal's wording.
# Forks: F14, Message's option until ruled (refuse, the file left as found).
{
  pkgs,
  flake,
  system,
  ...
}:
let
  old = flake.lib.components.messageOld.forSystem system;
in
flake.lib.messageFlow { inherit pkgs flake system; } {
  name = "message-flow-old-store";
  forks = [ "F14 refuse, the file left as found" ];
  packages = [ (pkgs.writeShellScriptBin "message-nexus-old" ''exec ${old.nexus} "$@"'') ];
  script = ''
    start()
    store = "/home/alice/.local/state/message/message.sema"
    status, out = run("systemctl --user stop message-nexus.service")
    assert status == 0, f"stopping message-nexus: {out}"
    machine.succeed(f"rm -rf {store}")
    run("setsid message-nexus-old > /tmp/old.log 2>&1 < /dev/null & echo $! > /tmp/old.pid")
    machine.wait_until_succeeds(f"test -e {store}", timeout=30)
    machine.succeed("kill $(cat /tmp/old.pid) 2>/dev/null || true; while kill -0 $(cat /tmp/old.pid) 2>/dev/null; do sleep 0.2; done")
    checksum = machine.succeed(f"find {store} -type f -exec sha256sum {{}} + | sort").strip()
    before = cursor()
    run("systemctl --user start message-nexus.service")
    machine.wait_until_succeeds(as_alice("! systemctl --user is-active --quiet message-nexus.service"), timeout=30)
    result = run("systemctl --user show -p ExecMainStatus --value message-nexus.service")[1]
    assert result not in ("", "0"), f"message-nexus exited {result} on an old store"
    assert not listens("message-nexus"), "message-nexus listens on an old store"
    traced = trace("message-nexus", before)
    assert store in traced, f"message-nexus does not name {store}:\n{traced}"
    after = machine.succeed(f"find {store} -type f -exec sha256sum {{}} + | sort").strip()
    assert after == checksum, f"the old store changed:\n{checksum}\n{after}"
  '';
}
