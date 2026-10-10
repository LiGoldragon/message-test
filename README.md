# message-test

Acceptance scenarios for the Message Nexus run together with the real Flow
Nexus. This repository holds no component source: `message` and `flow` are
flake inputs whose `nixpkgs` follows this flake's.

The scenarios are written to two designs in the Primary repository
(github:LiGoldragon/primary):

- Message: `flows/73ada7/reports/build/message-design.md` at bae5545f,
  sections 3 to 9.
- Flow: `flows/f5a6e9/reports/flow-buildable-design.md` at 72418b11,
  section 1.

From them: an Address written short, `{ Mind nexus Secondary }`; the send
`Send.{ Address Request }`, written `Send.{ { Mind nexus Secondary }
Order.«…» }`; `Lock.Address`, `Bind.{ Address Process }` with Process
`{ Pid Started }`, `End.Address` and `Current.Address` on Flow. A send up is
a send to the address one layer above, written by the sender (Message design
7.4). Where the Message design leaves a fork to the living (its section 12),
each scenario is written against the fork's first option and names that fork
in its header and in the `forks` it prints.

Both Nexuses start with no arguments, and each client reaches its Nexus at
the defaults they share; the frame names no socket before a payload does.
Message's meta client persists `fixtures/message-flow/message.datom`
(answered `Configured`, or `RestartRequired` when a socket changed), Message
is restarted with no arguments on its store, and the frame waits until a
process listens on each socket the payload names.

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
    lib/message-flow.py             the frame's helpers: configure, panes, Bind, send, trace
    checks/herdr.nix                the rig: headless Herdr in the VM
    checks/message-flow-*.nix       tests 1 to 14, one per file, 2 and 8 pending
    packages/message-flow-claude.nix tests 15 and 16, semi-sandbox, 15 pending
    fixtures/message-flow/          the meta Configure payloads
    checks/lint.nix, formatter.nix  style gate

## Scenarios

| # | check | forks | drive | expect |
|---|---|---|---|---|
| 1 | message-flow-delivered | F2 F4 F6* F8 F9 F10 | Order to awake { Mind nexus Secondary } | Delivered; trace Identified, Locked, Delivered; pane shows sender and request; lock gone |
| 2 | pending | F1 F6* F8 | Notice to asleep metaflow | Queued. No design names how a metaflow falls asleep |
| 3 | message-flow-unknown | F6* F8 | send to no such metaflow | Refused.Unknown.…; no lock record |
| 4 | message-flow-ended | F6* F8 | send to Ended metaflow | Refused.Ended.… |
| 5 | message-flow-off-route | F2 F6* F8 | Field Tertiary to Psyche Primary | Refused.OffRoute; lock released |
| 6 | message-flow-same-layer | F4 F6* F8 F10 | Field Secondary to Mind Secondary | Delivered |
| 7 | message-flow-up | F4 F6* F7* F8 F10 | Mind Secondary to { Mind nexus Primary } | Delivered to Mind Primary |
| 8 | pending | F6* F7* F8 | send up from a Primary | no design writes this refusal |
| 9 | message-flow-unidentified | F6* F8 F11 | send from an unbound pane | Refused.Unidentified.… |
| 10 | message-flow-held | F2 F3 F6* F8 | Lock taken directly, then send; clock past Until | Refused.Held.…, then Delivered |
| 11 | message-flow-unreachable | F2 F6* | Flow stopped, then send | Refused.FlowUnreachable |
| 12 | message-flow-first-configure | F2 | ordinary, meta, ordinary Configure | Configured, Configured, Refused.AlreadyConfigured |
| 13 | message-flow-restart | F2 F6* F8 | Message restarted with no arguments | send Delivered, no new Configure |
| 14 | message-flow-unreadable | — | unreadable datom to `message` | CLI refuses; no connection traced |
| 15 | message-flow-claude, pending | F1 F4 F6* F10 | Notice then Order to asleep Claude metaflow | Queued, Woken. No design names how a metaflow falls asleep |
| 16 | message-flow-claude | F1 F4 F6* F10 | Order to working Claude flow | placed by Flow's rule; transcript holds it once |

F6* is not its first option: no tiers, per design. The request carries no
priority head (`Send.{ { Mind nexus Secondary } Order.«…» }`).
F7* is not its first option: no Up, per design; `Send` carries an Address.

## Running

    nix flake check --no-build --option allow-import-from-derivation false
    nix flake check --keep-going -L
    MESSAGE_TEST_LIVE=1 nix run .#message-flow-claude
