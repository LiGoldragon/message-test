# message-test

Acceptance scenarios for the Message Nexus run together with the real Flow
Nexus. This repository holds no component source: `message` and `flow` are
flake inputs whose `nixpkgs` follows this flake's.

The scenarios are written to two designs in the Primary repository
(github:LiGoldragon/primary):

- Message: `flows/73ada7/reports/build/message-design.md` at e275b6bd
  (blob 66d3fdcf), sections 3 to 9; tests are numbered as its section 9
  numbers them.
- Flow: `flows/f5a6e9/reports/flow-buildable-design.md` at d849975a
  (blob bf5d5914), sections 1 and 2.

From them: an Address written short, `{ Mind nexus Secondary }`; the send
`Send.{ Recipient Request }`, Recipient being Flow's
`Recipient.[ Address Up ]`, written as the Message design writes it,
`Send.{ { Mind nexus Secondary } Order.«…» }` or `Send.{ Up Result.«…» }`.
On Flow: the lock request `Lock.{ Sender Recipient }`, written
`Lock.{ { Psyche nexus Secondary } { Mind nexus Secondary } }`, answered
`Locked.Lock` with the Lock `{ Sender Address Until }`; Flow resolves `Up`
relative to the sender and refuses `OffRoute` and `NoneAbove` at the lock
request. `Deliver.{ Lock Request }` and `Release.Lock` carry that Lock; one
delivery per lock; the lease is 60 seconds by default. `Bind.{ Address
Process }` with Process `{ Pid Started }`, answered `Bound.FlowId`;
`Stop.FlowId` leaves the metaflow Asleep; `End.Address`, `Current.Address`
and `Metaflows`. Flow's unknown refusals are one
`Unknown.[ Address Lock FlowId Key ]`; no design writes their print, so they
are matched by their head. Flow's sockets come from its start command; the
pure checks give it only the model of each layer and no `Configure.Nexus`,
which only Launch needs, so its lease is the 60 second default.

Where the Message design leaves a fork to the living (its section 12), each
scenario is written against the fork's first option and names that fork
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
    checks/message-flow-*.nix       tests 1 to 20, one per file, 18 pending
    packages/message-flow-claude.nix tests 21 and 22, semi-sandbox
    fixtures/message-flow/          the meta Configure payloads
    checks/lint.nix, formatter.nix  style gate

## Scenarios

| # | check | forks | drive | expect |
|---|---|---|---|---|
| 1 | message-flow-delivered | F2 F4 F6* F8 F9 F10 | Order to awake { Mind nexus Secondary } | Delivered; trace Identified, Locked, Delivered; pane shows sender and request; lock gone |
| 2 | message-flow-queued | F1 F6* F8 | Notice to a metaflow asleep after Stop | Queued; Current.Asleep; Metaflows shows the Notice queued once |
| 3 | message-flow-unknown | F6* F8 | send to no such metaflow | Refused.Unknown.…; no lock record |
| 4 | message-flow-ended | F6* F8 | send to Ended metaflow | Refused.Ended.… |
| 5 | message-flow-off-route | F2 F6* F8 | Field Tertiary to Psyche Primary | Refused.OffRoute from the lock; no lock record; no Deliver or Release traced |
| 6 | message-flow-same-layer | F4 F6* F8 F10 | Field Secondary to Mind Secondary | Delivered |
| 7 | message-flow-above | F4 F6* F8 F10 | Mind Secondary to { Mind nexus Primary } | Delivered to Mind Primary |
| 8 | message-flow-up | F4 F6* F7* F8 F10 | Up from Mind Secondary | trace Identified, Locked carrying { Mind nexus Primary }, Delivered; delivered to Mind Primary |
| 9 | message-flow-none-above | F6* F7* F8 | Up from Mind Primary | Refused.NoneAbove from the lock; no Deliver in the trace |
| 10 | message-flow-unidentified | F6* F8 F11 | send from an unbound pane | Refused.Unidentified.… |
| 11 | message-flow-held | F2 F3 F6* F8 | Lock taken directly, then send; clock past Until | Refused.Held.…, then Delivered |
| 12 | message-flow-unreachable | F2 F6* | Flow stopped, then send | Refused.FlowUnreachable |
| 13 | message-flow-first-configure | F2 | ordinary, meta, ordinary Configure | Configured, Configured, Refused.AlreadyConfigured |
| 14 | message-flow-restart | F2 F6* F8 | Message restarted with no arguments | send Delivered, no new Configure |
| 15 | message-flow-unreadable | — | unreadable datom to `message` | CLI refuses; no connection traced |
| 16 | message-flow-unknown-lock | F2 | Flow Deliver under a lock never granted | Refused.Unknown.… |
| 17 | message-flow-release | F2 | Release after Deliver; of a lapsed lock; of a lock never granted | Refused.Unknown.…; Refused.Lapsed; Refused.Unknown.… |
| 18 | pending | — | a Flow stand-in answers Locked with an Until already past, then a send | Refused.Lapsed. No component or design gives the stand-in |
| 19 | message-flow-held-end | F2 | End of M under a lock taken directly, then after Release | Refused.Held.…, then Ended |
| 20 | message-flow-lease | F2 | Flow with no Lease, then a lock | Until 60 seconds past the grant |
| 21 | message-flow-claude | F1 F4 F6* F10 | Notice then Order to a Claude metaflow asleep after Stop | Queued, Woken; first prompt ends with the queue, Order last |
| 22 | message-flow-claude | F1 F4 F6* F10 | Order to working Claude flow | placed by Flow's rule; transcript holds it once |

F6* is not its first option: no tiers, per design. The request carries no
priority head (`Send.{ { Mind nexus Secondary } Order.«…» }`).
F7*: Flow resolves Up, per design.

## Running

    nix flake check --no-build --option allow-import-from-derivation false
    nix flake check --keep-going -L
    MESSAGE_TEST_LIVE=1 MESSAGE_TEST_SKILL_VARIABLES=<skill variables file> \
      nix run .#message-flow-claude

The semi-sandbox launches flows, and Launch needs Flow's `Configure.Nexus`.
The runner reads its fields at run time from the skill variables file
(`Name: value` lines) and stops before any Launch, naming each one missing:

- `Flow source root`: SourceRoot
- `Flow stable Codex`: StableCodex
- `Flow next Codex`: NextCodex
- `Flow harness profiles`: HarnessProfiles, space-separated
- `Flow meta aspects`: MetaAspects, space-separated (`Psyche Mind Field`)

MessageNexusPath is the sandbox's own Message ordinary socket, and Lease
takes the design's default, 60 seconds.
