# message-flow-claude — semi-sandbox: tests 16 and 17 of the Message design
# at Primary 9541cd08, with real Claude Code flows on the cheapest model, launched by the real
# Flow Nexus, sent to by the real Message Nexus. It needs the living's Claude
# login and the network, so it is a runner, never a check, and it refuses to
# run unless MESSAGE_TEST_LIVE=1 is set.
#
# A fresh short root (removed in an exit trap) holds HOME and
# XDG_RUNTIME_DIR; only ~/.claude/.credentials.json is copied in. A headless
# Herdr server, flow-nexus and message-nexus start on that root with no
# arguments; each client reaches its Nexus at the defaults they share.
# Message's meta client persists the root's sockets and Message is restarted
# on them; Flow is given the model of every layer.
#
# 16. Pending: it needs an asleep metaflow, and neither Flow's design at
#     Primary e846c2ca nor the Message design names a request or event that
#     puts a metaflow to sleep. It is reported PENDING and drives nothing.
# 17. Forks, first option: F1, F4, F10; F6 no tiers,
#     per design. An Order to the awake, working
#     { Mind busy Secondary }: placed by Flow's rule (`Delivered` or `Queued`);
#     the recipient's transcript holds the Order exactly once.
{
  pkgs,
  flake,
  system,
  ...
}:
let
  message = flake.lib.components.message.forSystem system;
  flow = flake.lib.components.flow.forSystem system;
  herdr = flake.lib.components.herdr.forPkgs pkgs;
in
pkgs.writeShellApplication {
  name = "message-flow-claude";

  runtimeInputs = [
    pkgs.coreutils
    pkgs.findutils
    pkgs.gnugrep
    pkgs.iproute2
    pkgs.jq
    message.package
    flow.package
    herdr.package
  ];

  meta.description = "Test 17 of the Message design (test 16 pending): a Claude Code flow reached through Message and Flow (needs MESSAGE_TEST_LIVE=1).";

  text = ''
    if [ "''${MESSAGE_TEST_LIVE:-}" != 1 ]; then
      echo "message-flow-claude: needs the living's Claude login and the network; set MESSAGE_TEST_LIVE=1 to run it" >&2
      exit 2
    fi

    model="''${MESSAGE_TEST_MODEL:-${flake.lib.cheapestModel.claude}}"
    credentials="$HOME/.claude/.credentials.json"
    if [ ! -s "$credentials" ]; then
      echo "message-flow-claude: no Claude login at $credentials" >&2
      exit 1
    fi

    # A short root: sun_path holds 108 bytes.
    root="$(mktemp -d /tmp/mt-XXXXXXXX)"
    pids=()
    trap 'kill "''${pids[@]}" 2>/dev/null || true; herdr server stop > /dev/null 2>&1 || true; rm -rf "$root"' EXIT

    export HOME="$root/home" XDG_RUNTIME_DIR="$root/run"
    mkdir -p "$HOME/.claude" "$XDG_RUNTIME_DIR"
    chmod 700 "$XDG_RUNTIME_DIR"
    cp "$credentials" "$HOME/.claude/.credentials.json"
    SHELL="${pkgs.bashInteractive}/bin/bash" herdr server > "$root/herdr.log" 2>&1 &
    pids+=($!)
    RUST_LOG=debug ${flow.nexus} 2> "$root/flow-nexus.log" &
    pids+=($!)
    RUST_LOG=debug ${message.nexus} 2> "$root/message-nexus.log" &
    pids+=($!)

    for _ in $(seq 1 100); do herdr workspace list > /dev/null 2>&1 && break; sleep 0.1; done

    # bound <socket>: true once a process listens on it.
    bound() {
      for _ in $(seq 1 100); do
        ss -xlpn | grep -qF " $1 " && return 0
        sleep 0.1
      done
      echo "message-flow-claude: no process listens on $1" >&2
      return 1
    }

    # expect <label> <reply> <command...>: the whole stdout must equal <reply>.
    expect() {
      label="$1" want="$2"
      shift 2
      got="$(timeout 30 "$@" 2>&1)" || true
      echo "$label: «$got»"
      [ "$got" = "$want" ] || { echo "$label: expected «$want»" >&2; return 1; }
    }

    openPane() {
      herdr workspace create --cwd "$HOME" --label "$1" --no-focus | jq -r .result.root_pane.pane_id
    }
    shellPid() {
      herdr pane process-info --pane "$1" | jq -r .result.process_info.shell_pid
    }
    # bindPane <address> <pane>: binds the pane's shell (its pid and the
    # kernel's start time of that pid) to the address.
    bindPane() {
      pid="$(shellPid "$2")"
      started="$(cut -d' ' -f22 "/proc/$pid/stat")"
      reply="$(flow-meta "Bind.{ $1 { $pid $started } }" 2>&1)" || true
      echo "Bind $1: «$reply»"
      case "$reply" in Bound.*) ;; *) return 1 ;; esac
    }
    # sendFrom <pane> <datom>: runs `message` inside the pane, prints its reply.
    sends=0
    sendFrom() {
      sends=$((sends + 1))
      out="$root/send-$sends"
      herdr pane run "$1" "message '$2' > $out.reply 2>&1; echo \$? > $out.code" > /dev/null
      for _ in $(seq 1 600); do [ -s "$out.code" ] && break; sleep 0.1; done
      cat "$out.reply"
    }
    # transcriptOf: the newest Claude transcript under the root.
    transcriptOf() {
      find "$HOME/.claude/projects" -name '*.jsonl' -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-
    }

    # Message persists its payload, answers Configured or RestartRequired, and
    # is restarted with no arguments on its store.
    for _ in $(seq 1 100); do
      configured="$(timeout 30 message-meta "${message.configuration "$XDG_RUNTIME_DIR"}" 2>&1)" || true
      case "$configured" in Configured | RestartRequired) break ;; esac
      sleep 0.1
    done
    echo "message meta Configure: «$configured»"
    case "$configured" in Configured | RestartRequired) ;; *) exit 1 ;; esac
    kill "''${pids[2]}"
    wait "''${pids[2]}" 2>/dev/null || true
    RUST_LOG=debug ${message.nexus} 2>> "$root/message-nexus.log" &
    pids[2]=$!
    for socket in ${message.ordinarySocket} ${message.metaSocket} ${flow.ordinarySocket}; do
      bound "$XDG_RUNTIME_DIR/$socket" || exit 1
    done
    for layer in Primary Secondary Tertiary Quaternary; do
      expect "flow meta Configure $layer" Configured flow-meta "Configure.Model.{ $layer $model }"
    done

    test17() {
      sender="$(openPane psyche-busy)"
      bindPane '{ Psyche busy Secondary }' "$sender"
      launched="$(flow 'Launch.{ { Mind busy Secondary } [ ] «Run the shell command sleep 30, then reply done.» }')"
      echo "Launch: «$launched»"
      case "$launched" in Launched.*) ;; *) return 1 ;; esac
      for _ in $(seq 1 600); do
        transcript="$(transcriptOf)"
        [ -n "$transcript" ] && grep -q '"tool_use"' "$transcript" && break
        sleep 0.5
      done
      reply="$(sendFrom "$sender" 'Send.{ { Mind busy Secondary } Order.«mfBusy reply received» }')"
      case "$reply" in Delivered | Queued) ;; *) echo "Order: «$reply»" >&2; return 1 ;; esac
      for _ in $(seq 1 1200); do grep -q mfBusy "$transcript" && break; sleep 0.5; done
      count="$(jq -s '[.[] | select(.type == "user") | tostring | select(test("mfBusy"))] | length' "$transcript")"
      echo "transcript holds the Order $count times"
      [ "$count" = 1 ]
    }

    # report <name> <exit code>
    failed=0
    report() {
      if [ "$2" = 0 ]; then echo "$1: PASS"; else echo "$1: FAIL"; failed=1; fi
    }
    echo "test16: PENDING (no designed way to put a metaflow to sleep)"
    set +e
    ( set -e; test17 )
    report test17 $?
    set -e
    exit "$failed"
  '';
}
