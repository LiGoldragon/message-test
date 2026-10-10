# message-test

Acceptance scenarios for the Message Nexus run together with the real Flow
Nexus. This repository holds no component source: `message` and `flow` are
flake inputs whose `nixpkgs` follows this flake's.

The scenarios are written to two designs in the Primary repository
(github:LiGoldragon/primary):

- Message: `flows/73ada7/reports/build/message-design.md` at be5c2e5b
  (blob e3ea9872), sections 3 to 9; tests are numbered as its section 9
  numbers them.
- Flow: `flows/f5a6e9/reports/flow-buildable-design.md` at 9b006dd2
  (blob c443d8a8), sections 1 and 2.

From them: an Address written short, `{ Mind nexus Secondary }`; the send
`Send.{ Recipient Request }`, Recipient being Flow's
`Recipient.[ Address Up ]`, written as the Message design writes it,
`Send.{ { Mind nexus Secondary } Order.«…» }` or `Send.{ Up Result.«…» }`.
On Flow: Message's lock request `Lock.{ Sender Recipient }`, answered
`Locked.Lock` with the Lock `{ Sender Address Until }`; Flow resolves `Up`
relative to the sender and refuses `OffRoute` and `NoneAbove` at the lock
request; `Deliver.{ Lock Request }` and `Release.Lock` carry that Lock.
Message binds to Flow as `{ Field message Primary }`, and Flow admits Lock,
Deliver and Release only from that exact Message process, so no scenario
calls them directly; this repository keeps only what is observable through
Message. Flow's own lock contract (an unknown lock, Release after Deliver and
after lapse, a lapsed Until, End refused while a lock is held, the lease) is
covered by flow-test, and so is the Message design's test 26, a send from an
asleep sender, refused Asleep.
Message binds at its start with
`Bind.{ { Field message Primary } { Pid Started } }`. Test 21 makes the old
store with old Message, the `message-old` input pinned at 6fa4d0. Flow starts with `Start.{ OrdinarySocketPath MetaSocketPath }`.
A datom String is written bare when it has no space, no delimiter glyph and
does not begin or end with `.`, `!` or `:`; otherwise in guillemets. `Bind.{ Address
Process }` on Flow's ordinary socket, Process `{ Pid Started }`, answered
`Bound.FlowId`;
`Stop.FlowId` leaves the metaflow Asleep; `End.Address`, `Current.Address`
and `Metaflows`. Flow's unknown refusals are one
`Unknown.[ Address Lock FlowId Key ]`; no design writes their print, so they
are matched by their head. Flow's sockets come from its start command.

Flow accepts Message's start Bind only from the executable that
`Configure.Nexus`'s MessageNexusBinary names, and refuses it NotConfigured
before any `Configure.Nexus`. So the frame starts Flow at boot, gives it the
model of each layer and a `Configure.Nexus`, and only then starts Message. In
that payload MessageNexusBinary is the message-nexus under test, a real file
(Flow compares canonical paths, and the frame checks it resolves to a file), and
MessageNexusPath the VM's Message ordinary socket; SourceRoot, StableCodex,
NextCodex, HarnessProfiles and MetaAspects are VM-local fixture values that
no pure scenario exercises, since none launches a flow, and Lease is 60.
Nothing in it comes from the living's setup.

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
    checks/message-flow-*.nix       tests 1-21 and 24-30, one per file;
                                    11, 25, 30 pending; 26 in flow-test
    packages/message-flow-claude.nix tests 22 and 23, semi-sandbox
    fixtures/message-flow/          the meta Configure payloads
    lib/skill-variable.nix          the runner's skill-variable reader
    checks/skill-variable.nix       the reader over a sample file
    checks/lint.nix, formatter.nix  style gate

## Scenarios

| # | check | forks | drive | expect |
|---|---|---|---|---|
| 1 | message-flow-delivered | F2 F4 F6* F8 F9 F10 | Order to awake { Mind nexus Secondary } | Delivered; trace Identified, Locked, Delivered; pane shows sender and request |
| 2 | message-flow-queued | F1 F6* F8 | Notice to a metaflow asleep after Stop | Queued; Current.Asleep; Metaflows shows the Notice queued once |
| 3 | message-flow-unknown | F6* F8 | send to no such metaflow | Refused.Unknown.… |
| 4 | message-flow-ended | F6* F8 | send to Ended metaflow | Refused.Ended.… |
| 5 | message-flow-off-route | F2 F6* F8 | Field Tertiary to Psyche Primary | Refused.OffRoute from the lock; no Deliver or Release traced |
| 6 | message-flow-same-layer | F4 F6* F8 F10 | Field Secondary to Mind Secondary | Delivered |
| 7 | message-flow-above | F4 F6* F8 F10 | Mind Secondary to { Mind nexus Primary } | Delivered to Mind Primary |
| 8 | message-flow-up | F4 F6* F7* F8 F10 | Up from Mind Secondary | trace Identified, Locked carrying { Mind nexus Primary }, Delivered; delivered to Mind Primary |
| 9 | message-flow-none-above | F6* F7* F8 | Up from Mind Primary | Refused.NoneAbove from the lock; no Deliver in the trace |
| 10 | message-flow-unidentified | F6* F8 F11 | send from an unbound pane | Refused.Unidentified.… |
| 11 | pending | F2 F3 F6* F8 | a Flow stand-in holds Deliver; Message stopped after Locked, started again, then a send | Refused.Held.Lock, then Delivered. Needs a Flow stand-in |
| 12 | message-flow-unreachable | F2 F6* | Flow stopped, then send | Refused.FlowUnreachable |
| 13 | message-flow-first-configure | F2 | ordinary, meta, ordinary Configure | Configured, Configured, Refused.AlreadyConfigured |
| 14 | message-flow-restart | F2 F6* F8 | Message restarted with no arguments | send Delivered, no new Configure |
| 15 | message-flow-unreadable | — | unreadable datom to `message` | CLI refuses; no connection traced |
| 16 | message-flow-bind | F2 F6* F8 | message-nexus started | Flow's trace shows Bind of { Field message Primary } with Message's pid and start time; a send succeeds |
| 17 | message-flow-not-message | F2 F8 | the `flow` CLI sends Lock, Deliver, Release | each Refused.NotMessage; its Identify is answered |
| 18 | message-flow-start-refused | F2 | a second message-nexus while the first lives; Flow stopped, then message-nexus started | nonzero exit, trace names Taken, the first still serves; nonzero exit, nothing listens, trace names FlowUnreachable, no restart |
| 19 | message-flow-rebind | F2 F6* F8 | message-nexus killed, started again | Flow's trace shows the Bind answered Bound; a send succeeds |
| 20 | message-flow-marker | F2 | fresh store: ordinary Configure, meta Configure moving a socket, ordinary Configure | Configured, RestartRequired, Refused.AlreadyConfigured |
| 21 | message-flow-old-store | F14 | old Message's version-1 store at the store path | start refused, trace names the path, store checksum unchanged |
| 24 | message-flow-reaped | F6* F8 | message-nexus stopped by SIGSTOP; a client connects, sends, is killed and reaped by its shell; SIGCONT | Message's trace names ESRCH; no Identify and no Lock in Flow's trace; the recipient's pane lacks the request; then an unbound pane's send puts an Identify in Flow's trace. Witnesses the ESRCH path on a kernel of 6.16 or later, not a pid reuse; fails against the pinned message-nexus 0.19.1, which runs no section-6 guard |
| 25 | pending | F8 | sender's metaflow has no Flow record at Lock | Refused.Unknown.Address naming the sender. Needs a Flow stand-in that emits Identified.Address then Refused.Unknown.Address on Flow's design ordinary wire; that wire (Bind, Lock, Identify, Deliver, Release and the design refusals) is in no published signal-flow — the pinned flow builds signal-flow 11.0.0 (068f0ea) whose Query carries only the 0.25.0 operations — so it cannot be emitted without inventing a contract |
| 27 | message-flow-sender-ended | F6* F8 | the sender's metaflow Ended while its shell runs, then it sends | Refused.Ended.… naming the sender |
| 28 | message-flow-wrong-binary | F2 | a message-nexus copied to another store path is started | nonzero exit naming NotMessage; nothing listens |
| 29 | message-flow-not-configured | F2 F6* F8 | message-nexus started before Flow holds Configure.Nexus, then after it | nonzero exit, nothing listens, trace names NotConfigured; then a send is Delivered |
| 31 | covered by 28 | F2 | Flow answers NotMessage to Message's Lock after its start Bind | Covered by test 28: Message exits naming NotMessage when refused at Bind, together with flow-test's flow-lock-message-exec (the refusal after execve). A mid-run change of MessageNexusBinary is refused Conflict under Flow's design, so no message-test scenario reaches it. |
| 22 | message-flow-claude | F1 F4 F6* F10 | Notice then Order to a Claude metaflow asleep after Stop | Queued, Woken; first prompt ends with the queue, Order last |
| 23 | message-flow-claude | F1 F4 F6* F10 | Order to working Claude flow | placed by Flow's rule; transcript holds it once |

F6* is not its first option: no tiers, per design. The request carries no
priority head (`Send.{ { Mind nexus Secondary } Order.«…» }`).
F7*: Flow resolves Up, per design.

Test 30, the bound Message process replaced through execve, is Flow's gate
and is tested in flow-test as `flow-lock-message-exec` (flow-test 446478).

## Running

    nix flake check --no-build --option allow-import-from-derivation false
    nix flake check --keep-going -L
    MESSAGE_TEST_LIVE=1 MESSAGE_TEST_SKILL_VARIABLES=<skill variables file> \
      nix run .#message-flow-claude

The semi-sandbox starts Flow with `Start.{ ordinary meta }`, its sockets
under the sandbox root, and launches flows; Launch needs Flow's
`Configure.Nexus`. The runner reads its fields at run time from the skill
variables file (`Name: value` lines, a list space-separated), builds each
value whole, and stops before any Launch, naming each variable missing.
CodexEndpoint and HarnessProfile are meta-signal-flow's at 88f37592, the
revision Flow 0.25.0 pins.

| Skill variable | Field |
|---|---|
| `Flow source root` | SourceRoot, String |
| `Flow stable Codex client path` | StableCodex ClientPath, String |
| `Flow stable Codex home` | StableCodex Home, String |
| `Flow stable Codex control socket path` | StableCodex ControlSocketPath, String |
| `Flow stable Codex model names` | StableCodex Vector<ModelName>, Strings |
| `Flow next Codex client path` | NextCodex ClientPath, String |
| `Flow next Codex home` | NextCodex Home, String |
| `Flow next Codex control socket path` | NextCodex ControlSocketPath, String |
| `Flow next Codex model names` | NextCodex Vector<ModelName>, Strings |
| `Flow Codex command sigils` | HarnessProfile Codex: Vector<CommandSigil>, Strings |
| `Flow Codex interrupt keys` | HarnessProfile Codex: InterruptKeys, Vector<KeyName> |
| `Flow Codex submit keys` | HarnessProfile Codex: SubmitKeys, Vector<KeyName> |
| `Flow Claude command sigils` | HarnessProfile Claude: Vector<CommandSigil>, Strings |
| `Flow Claude interrupt keys` | HarnessProfile Claude: InterruptKeys, Vector<KeyName> |
| `Flow Claude submit keys` | HarnessProfile Claude: SubmitKeys, Vector<KeyName> |
| `Flow meta aspects` | MetaAspects, Vector<Aspect>, aspect names such as `Field Mind` |

MessageNexusPath is the sandbox's own Message ordinary socket, and Lease
takes the design's default, 60 seconds. `checks/skill-variable.nix` runs the
reader over `fixtures/skill-variable/sample.md`.
