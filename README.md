# message-test

Acceptance scenarios for the Message Nexus run together with the real Flow
Nexus. This repository holds no component source: `message` and `flow` are
flake inputs whose `nixpkgs` follows this flake's. The scenarios are written
to the Message design of flow 73ada7 (`flows/73ada7/reports/build/message-design.md`,
section 9) and Flow's design at Primary revision e17a62ca
(`flows/f5a6e9/reports/flow-buildable-design.md`). The Address,
Lock, Process and Request forms are Flow's at e17a62ca:
`{ Mind nexus Secondary }`, `Lock.{ Address Until }`, `Bind.{ Address { Pid
Started } }`, and Message's `Send.{ Address Request }` (or `Send.{ Up Request }`).
Fork F5 is therefore taken as Flow's design writes it, the struct
`{ Aspect Topic Layer }`, and no scenario names it. Where the Message design
leaves a fork to the living (its section 12), each scenario is written
against the fork's first option and names that fork in its header and in the
`forks` it prints.

Test unpushed code with `--override-input message path:<checkout>` or
`--override-input flow path:<checkout>`; once it lands, `nix flake update
<input>` and commit the lock.

## Layout

    flake.nix                       inputs and `inputs.blueprint { inherit inputs; }`
    lib/default.nix                 flake.lib: components, messageFlow, cheapestModel
    lib/components/message.nix      Message Nexus and clients: paths, Configure payload
    lib/components/flow.nix         Flow Nexus and clients: paths, Model payload
    lib/components/herdr.nix        headless Herdr
    lib/message-flow.nix            the frame of a pure scenario: one VM, three user services
    lib/message-flow.py             the frame's helpers: panes, Bind, send, trace
    checks/herdr.nix                the rig: headless Herdr in the VM
    checks/message-flow-*.nix       tests 1 to 14, one per file
    packages/message-flow-claude.nix tests 15 and 16, semi-sandbox
    fixtures/message-flow/          the meta Configure payloads
    checks/lint.nix, formatter.nix  style gate

## Scenarios

| # | check | forks | drive | expect |
|---|---|---|---|---|
| 1 | message-flow-delivered | F2 F4 F6 F8 F9 F10 | Order to awake { Mind nexus Secondary } | Delivered; trace Identified, Locked, Delivered; pane shows sender and request; lock gone |
| 2 | message-flow-queued | F1 F6 F8 | Notice to asleep metaflow | Queued; Current.Asleep |
| 3 | message-flow-unknown | F6 F8 | send to no such metaflow | Refused.Unknown.…; no lock record |
| 4 | message-flow-ended | F6 F8 | send to Ended metaflow | Refused.Ended.… |
| 5 | message-flow-off-route | F2 F6 F8 | Field Tertiary to Psyche Primary | Refused.OffRoute; lock released |
| 6 | message-flow-same-layer | F4 F6 F8 F10 | Field Secondary to Mind Secondary | Delivered |
| 7 | message-flow-up | F4 F6 F7 F8 F10 | Up from Mind Secondary | delivered to Mind Primary |
| 8 | message-flow-none-above | F6 F7 F8 | Up from a Primary | Refused.NoneAbove; no Lock in Flow's trace |
| 9 | message-flow-unidentified | F6 F8 F11 | send from an unbound pane | Refused.Unidentified.… |
| 10 | message-flow-held | F2 F3 F6 F8 | Lock taken directly, then send; clock past Until | Refused.Held.…, then Delivered |
| 11 | message-flow-unreachable | F2 F6 | Flow stopped, then send | Refused.FlowUnreachable |
| 12 | message-flow-first-configure | F2 | ordinary, meta, ordinary Configure | Configured, Configured, Refused.AlreadyConfigured |
| 13 | message-flow-restart | F2 F6 F8 | Message restarted with no arguments | send Delivered, no new Configure |
| 14 | message-flow-unreadable | — | unreadable datom to `message` | CLI refuses; no connection traced |
| 15 | message-flow-claude | F1 F4 F6 F10 | Notice then Order to asleep Claude metaflow | Queued, Woken; first prompt ends with the queue, Order last |
| 16 | message-flow-claude | F1 F4 F6 F10 | Order to working Claude flow | placed by Flow's rule; transcript holds it once |

F6's first option is vision-messaging's `Priority.[HardAbrupt MiddleAbrupt Soft]`
as a head on the message datom; every send here heads its request with
`Soft` (`Send.{ { Mind nexus Secondary } Soft.Order.«…» }`).

## Running

    nix flake check --no-build --option allow-import-from-derivation false
    nix flake check --keep-going -L
    MESSAGE_TEST_LIVE=1 nix run .#message-flow-claude
