---
name: iykes-solana-bughunt-skill
description: >-
  End-to-end Solana / Anchor / native Rust bug-hunting playbook (researcher:
  deviykee). Invoke to hunt vulnerabilities in a Solana program or DeFi protocol
  and turn a finding into a responsible, paid disclosure. Fill the INTAKE block,
  then run the steps in order. Mechanical probes live in tools/; each step has
  decision gates and fill-in templates for the PoC, report, and disclosure
  message. Verification is local simulator / bankstest / fork-read ONLY. Never
  exploit mainnet. Be token-conservative; use smaller models for capable
  subtasks. After surface map, run foundation maps, multi-angle adversarial
  passes, product-type hunts (bonding curve, AMM, vault, lending, perps, OTC,
  bridge), and honest severity (including kill temporary-vs-persistent
  conditions). Keep a Low, Medium, or High when it is a lead or attack-path step
  toward a Critical, and report every confirmed Low, Medium, or High at its real
  severity. Always check the frontend for exposed secrets (Step 11). For
  closed-source programs, recover Rust via function-by-function decompilation
  scored against recompilation to the on-chain binary (Step 3.5). Maintain
  coverage.md incrementally (files opened, paths traced, %, exclusions); never
  imply a complete audit when coverage is low.
  Use when the user names a Solana target (project, program id, repo, or
  website) and wants it audited for bounties, or says "Solana hunt", "Anchor
  audit", "find Solana bugs", "SVM bughunt".
---

# Iyke's Solana Bughunt Skill

By **deviykee**. Fill the INTAKE, then execute the steps top to bottom. Mechanical
probes are scripts under `tools/`; decision gates tell you exactly what to do next.
You should not have to invent the repeatable parts - run the tool, read the gate.

This is the Solana / SVM counterpart to `iykes-web3-bughunt-skill` (EVM). Same
discipline (fork/sim only, honest severity, private disclosure, coverage
tracking). Different runtime model (accounts, PDAs, CPI, rent, Token-2022).

### Pair with other Solana audit material

After Step 3 has source (or a solid surface map), also load companion checklists
or pattern libraries when available in your environment (examples below - names
vary by install):

| Material | When |
|---|---|
| Anchor constraint / account validation checklist | Full pass over `#[account(...)]`, seeds, signers |
| Anchor vulnerability pattern library (PDA, CPI, type cosplay, close) | Deep pattern matching |
| Protocol-type notes (AMM, lending, staking, oracle, governance) | Product-specific heuristics |
| Critical-only / low false-positive severity rubric | Tightening severity before disclosure |
| Solana systems / state-machine reasoning notes | Complex multi-ix protocols |

This playbook stays the **lead** for bounty hunt intake, gates, disclosure, and
honest bounds. Companions deepen analysis; they do not replace Steps 1-10.

### Optional corpus (pattern mining)

Public Solana audit reports (launchpads, AMMs, vaults, lending, perps, OTC,
bridges) are useful for **bug-class recall**, not for inventing issues that do
not exist in the target. Prefer patterns that match the PRODUCT_TYPE in INTAKE.

---

### Token budget and model routing (apply on every hunt)

Be **token-conservative** for the whole hunt. Prefer cheap, narrow work over
reloading giant contexts. Employ **smaller / faster models** (or lightweight
subagents) wherever they are capable; reserve the primary high-capability model
for judgment-heavy steps only.

| Prefer small / cheap model or subagent | Keep on primary (high-capability) model |
|---|---|
| RPC probes, program id greps, IDL dumps | Severity call and kill-your-own-finding |
| `rg` over constraints, seeds, CPI sites | Root-cause reading of value-moving paths |
| File search, log tails, `anchor test`, builds | Novel attack design and exploit sequencing |
| Drafting report/DM from a filled template | Final report accuracy and bound honesty |
| Parallel explore lanes with narrow prompts | Disclosure strategy if ambiguous |
| Static / linter noise triage | Complex multi-ix economic logic |

Rules:
1. **Do not re-read entire skills** every turn. Load this playbook once per hunt;
   load only the one checklist section you need for the product type.
   For mechanical steps, run the matching script in the **Tools** table below -
   do not re-derive the bash/python by hand.
2. **Shell first for facts.** Prefer `solana`/`spl-token`/`curl`/`rg` (or
   `tools/*.sh`) over long model reasoning when the answer is an on-chain number
   or a string in a file.
3. **Narrow tool output.** Cap logs, `head` greps, avoid dumping megabyte IDLs
   into context; write to files and read slices.
4. **One finding path at a time** until confirmed or killed. No shotgun of five
   parallel deep dives unless each is a small explore subagent with a tight prompt.
5. **Subagents:** use `explore` (read-only) or a small model for map/grep/auth
   triage; bring results back as short bullets. Parent model decides go/no-go.
6. **PoC:** smallest test that proves the bound. Prefer Anchor/banks-client /
   LiteSVM unit PoC + on-chain magnitude over multi-hour mainnet-fork when RPC
   is slow.
7. **User updates:** short status (what proven, what next). No essay recaps of
   tool logs.
8. **Chunk, do not dump.** For complex logic, feed one mechanism at a time
   (migrate path, take_offer, redeem, one oracle leg) with a single adversarial
   question. Full-repo paste increases hallucination and misses interactions.
9. **Coverage tracking is mandatory.** Update `coverage.md` as you read files and
   trace paths (see **Coverage tracking** below). Do not invent thoroughness.

---

## INTAKE - fill this in before running

Fill only fields you actually know. In the written report, **omit any key whose value is
unknown** (do not print `KEY : unknown` or empty placeholders). Drop the whole line.
`none` is fine when that is a real answer (e.g. no bounty program). Prefer leaving a
field out over guessing.

```
PROJECT_NAME   : <e.g. example.fun>
X_HANDLE       : <e.g. @exampledotfun>       # only if known; private disclosure channel
WEBSITE        : <https://...>               # app URL
DOCS           : <https://docs...>           # only if known
SECURITY_EMAIL : <security@... or omit>      # fill in Step 10A from a quoted official page
DISCLOSURE     : <immunefi URL / "discretionary" / omit>
CLUSTER        : <mainnet-beta | devnet | custom>
RPC            : <https://...>               # confirm in Step 1
EXPLORER       : <https://explorer.solana.com | solscan | custom>
KNOWN_PROGRAMS : <role=ProgramId pairs; omit line if none known>
KNOWN_ACCOUNTS : <role=Pubkey pairs; config, vault, mint; omit if none>
FRAMEWORK      : <anchor | native | pinocchio | mixed>
PRODUCT_TYPE   : <launchpad/bonding-curve | amm-dex | vault/lst | lending | perps |
                  otc/escrow | distribution | bridge/oft | staking/governance | other>
TOKEN_SURFACE  : <spl-token | token-2022 | both | unknown>
BOUNTY/CONTEST : <live program? amount? or "none / discretionary">
NOTES          : <optional extras; omit if empty>
RESEARCHER     : deviykee
```

Set shell vars from the intake and reuse them:
```bash
RPC="<RPC>"; CLUSTER="<CLUSTER>"; EXPLORER="<EXPLORER>"
export SOLANA_URL="$RPC"
# TOOLS=path/to/tools  # if not already on PATH / cwd-relative
```

---

## Operating rules (non-negotiable read once, apply always)

1. **Simulator / bankstest / read-only verification only. Never move real funds
   on mainnet.** A passing local PoC is the proof. This does not bend for revenge,
   "I'll give it back", or "just to prove it".
2. **Honest severity.** State the bound. A Medium is a Medium. Do not upgrade High
   to Critical because the story is dramatic.
3. **Ask, never threaten.** No "pay or I release/exploit". That's extortion.
4. **Kill your own finding if it doesn't hold up.** Disproving yourself is the job.
5. **Never publish a live, unpatched bug.** Private channel + private repo until fixed.
6. **Audit programs, not narratives.** Day-one hype with no verifiable program id =
   scam trap. Sketchy TLDs (`.online`, `.cash`, brand-impersonation) = assume
   phishing until proven; never connect a wallet to them.
7. **Token-conservative; smaller models when capable.** Every hunt. See
   "Token budget and model routing" above.
8. **Separate trust-root from permissionless.** Owner/admin/keeper-by-design power
   is not a Critical stranger exploit. Label Trust/centralization honestly.
9. **Temporary condition != permanent condition.** One-slot price manip that is
   restored often leaves victims whole. Persistent stuck vault / frozen ATA /
   closed PDA while balances remain is a different finding. Kill the first before
   claiming the second.
10. **Coverage tracking.** Maintain `coverage.md` for the whole hunt. Update it
    **when you open a file or finish tracing a path**, not only at the end. Opening
    a file without tracing its value-moving logic does not count as path coverage.
    If coverage is low, say so explicitly in the report and user status; never
    imply a complete audit was performed.
11. **No em dashes** in reports or DMs (use commas, periods, or a normal hyphen).
12. **Overcome blockers proactively.** When you hit a blocker (closed-source
    program, missing IDL, unsupported cluster, unavailable data, missing tool),
    actively search for and install/use something that solves it: decompilers
    (Binary Ninja + bn-ebpf-solana, patina-research style agents, sbpf
    disassembler), disassemblers (`solana program dump` + BPF/sBPF tools),
    explorers, RPC providers, APIs, or alternative data sources. For closed-source
    Solana programs, follow **STEP 3.5** (function-by-function recovery scored
    against recompilation to the on-chain binary). Install packages with
    `cargo`/`pip`/`npm` when needed and write small scripts to automate repeats.
    Do NOT stop at "no source" or "tool not installed"; find a way forward and
    document the tools/methods so future hunts benefit.
13. **Chain leads to a Critical.** Hunt and keep a Low, Medium, or High when it
    can be a step on an attack path to a Critical. A usable step is a missing
    constraint, a weak invariant, griefing, a rounding leak, an oracle gap, a
    trust assumption, or a partial auth bypass that combines with another bug, a
    reachable state, or a second instruction into unauthenticated theft, a
    freeze, or unbounded loss. Record the lead at its honest severity (rule 2).
    Name the missing piece that would make the chain Critical, and try that chain
    before you close the path. If the chain is confirmed with a sim/bankstest
    PoC, report the chain severity, not the piece alone. If the second piece is
    missing, keep a lead line that names what is missing. Drop the lead only when
    the chain is impossible: the state is unreachable, the auth cannot be
    bypassed, or the condition restores and leaves victims whole. Do not upgrade
    the piece by itself. Report every confirmed Low, Medium, and High, whether or
    not it chains. Write the Step 9 report and include it in the private
    disclosure at that severity. Do not leave it only in hunt notes, and do not
    wait for a Critical before you report it. Killed findings and false positives
    stay out of the report.

---

## Coverage tracking (mandatory every hunt)

During any bug-hunting or security-audit session, maintain a **`coverage.md`**
file that tracks what was actually examined.

### Where to put it

Prefer one of (first match wins for the session):

1. Hunt workspace root: e.g. `hunts/<project>/coverage.md`
2. Audit output dir: e.g. `.context/outputs/<N>/coverage.md` or `hunts/<project>/audit/coverage.md`
3. Repo root of the target under audit (only if that repo is a private hunt workspace)

Do **not** leave coverage only in chat. It must be a file on disk.

### What to track

1. **Files opened** - every source file read (prefer paths under `programs/**/src`).
2. **Code paths followed** - instructions/flows actually traced (e.g.
   `create_offer -> take_offer partial -> remaining vault locked because close=`).
   A file can be opened without its logic being understood; say so in Notes if
   only skimming.
3. **Coverage percentage** - `files read / total relevant files` in scope.
   Define the denominator early (e.g. all `programs/**/src/**/*.rs` excluding
   generated IDL clients and `target/`).
4. **Explicitly excluded areas** - with one-line reasons.

### Format (running table)

```markdown
# Coverage - <PROJECT>

Coverage: X/Y files (Z%).

Last updated: <ISO date or step name>

| File | Read? | Paths traced | Notes |
|------|-------|--------------|-------|
| programs/foo/src/lib.rs | yes | entry routing | full read |
| programs/foo/src/instructions/take_offer.rs | yes | partial fill + close | full read |

## Explicitly excluded

| Path / area | Reason |
|-------------|--------|
| target/** | build artifacts |
| tests/** | fixtures (unless hunting test-only bugs) |
| clients/** | generated IDL clients (unless auth lives there) |
```

### Update rules

- **Incremental, not retroactive.** When you `read` a file or finish tracing a flow,
  update the row the same turn.
- **Read? values:** `yes` | `partial` | `no`.
- **Paths traced** empty or `-` means file opened but logic not followed; that does
  **not** inflate the "understood" claim.
- **Low coverage gate:** before Step 9 / final user summary, if Z < 50% of
  in-scope production code (or fewer than the core value-moving instructions),
  state explicitly: `Coverage incomplete: Z% (X/Y). Findings apply to examined paths
  only.`

### Template bootstrap

```bash
# after INTAKE, once PROJECT_NAME and hunt dir are known
cat > "$HUNT_DIR/coverage.md" <<'EOF'
# Coverage - <PROJECT_NAME>

Coverage: 0/Y files (0%).  # set Y after inventory

Last updated: intake

| File | Read? | Paths traced | Notes |
|------|-------|--------------|-------|

## Explicitly excluded

| Path / area | Reason |
|-------------|--------|
| target/** | build artifacts |
| tests/** | tests (exclude unless in scope) |
| node_modules/** / .yarn/** | frontend deps |
EOF
```

---

## Tools

Mechanical scripts next to this playbook (`tools/`). Prerequisites and full docs:
`tools/README.md`. Run from the hunt workspace; scripts fail non-zero on RPC errors
instead of hanging. Smoke-check: `./tools/selftest.sh`.

| Script | Step | Inputs | Outputs / gates | Why this exists |
|---|---|---|---|---|
| `tools/step1_ground_truth.sh` | 1 | `<RPC>` | health, slot, version; **PASS** or **STOP** | Avoid hours on dead/scam RPCs |
| `tools/step2_bundle_grep.sh` | 2B | `<WEBSITE>` | base58-ish program ids / pubkeys from JS | Find hidden frontend config ids |
| `tools/step3_surface_map.sh` | 3 | `<RPC> <PROGRAM_ID>` | executable?, owner, data len, optional IDL | Verified vs opaque program path |
| `tools/step3_account_map.sh` | 3 | `<RPC> <PUBKEY> [label]` | owner, lamports, data len, executable | Map config / vault / mint accounts |
| `tools/step3_5_decompile_prep.sh` | 3.5 | `<RPC> <PROGRAM_ID> [SLOT]` | dumped .so + basic metadata / strings | Bootstrap closed-source decompilation |
| `tools/step4_auth_triage.sh` | 4 | `<SRC_ROOT>` | constraint/signer/CPI grep scoreboard | Free-win missing-auth / loose seeds |
| `tools/step7_poc_scaffold.sh` | 7 | `<POC_DIR> [anchor\|native]` | Anchor or banks-client PoC skeleton | Repeatable sim-only proof setup |
| `tools/step9_report_skeleton.py` | 9 | INTAKE + severity + title (+ optional) | filled Step 9 report skeleton | Same report shape every hunt |
| `tools/step10_contact_hunt.sh` | 10A | `<URL> [URL ...]` | emails, bounty-platform links, quotes; **GATE** | Real security inbox, not a guess |
| `tools/step10_dm_skeleton.py` | 10 | project/severity/cluster/component/impact | filled first DM text | Consistent private first contact |
| `tools/step11_frontend_security.sh` | 11 | `<WEBSITE> [OUTPUT_DIR]` | API keys, tokens, RPC endpoints, pubkeys | Catch hardcoded secrets in frontend |
| `tools/selftest.sh` | - | none | usage/exit smoke for all tools | Catch broken tools before a hunt |

Optional static / helper commands (when available):
```bash
# Anchor constraint and account surface
rg -n "UncheckedAccount|AccountInfo|remaining_accounts|init_if_needed|close\s*=" programs
rg -n "seeds\s*=|bump|has_one|constraint\s*=" programs
rg -n "invoke\(|invoke_signed\(|CpiContext|transfer_checked|token_interface" programs
rg -n "Token-2022|transfer_fee|TransferFee|permanent_delegate|freeze_authority" programs

# On-chain
solana program show <PROGRAM_ID> --url "$RPC"
solana account <PUBKEY> --url "$RPC" -v
spl-token display <MINT> --url "$RPC"
```

Do not promote a static "High" to Critical without a working PoC.

---

## STEP 1 - Ground truth (is this real, and where)

```bash
./tools/step1_ground_truth.sh "$RPC"
```
Confirms RPC alive; prints slot and version (or cluster health).

Gate:
- RPC does not resolve, or no docs/verifiable program exist -> **STOP. Likely
  vaporware/scam.** Report that to the user; do not sink hours.
- Real cluster confirmed -> continue.

---

## STEP 2 - Locate the core program(s)

Frontends hide program ids in runtime config. Use these in order until you have ids:

**A. Official docs / GitHub / verified explorer page**
- Solscan / Solana Explorer / custom explorer "Program" pages
- Anchor `declare_id!` / `Anchor.toml` / deploy scripts in the public repo

**B. Grep the app bundle**
```bash
./tools/step2_bundle_grep.sh "<WEBSITE>"
```
Fetches HTML + JS assets and greps for base58-like pubkeys and common config keys
(`programId`, `PROGRAM_ID`, `idl`, bonding curve, vault).

**C. Browser** (when config is fetched at runtime): load the app, read the network
requests, and pull program ids from RPC `getAccountInfo` / transaction simulation
payloads.

**D. Known token mint -> largest holders / vault ATAs -> owner program**
```bash
spl-token accounts --owner <vault_or_authority> --url "$RPC"
solana account <ATA_OR_VAULT> --url "$RPC" -v
```

---

## STEP 3 - Verification gate + surface map

```bash
./tools/step3_surface_map.sh "$RPC" "<PROGRAM_ID>"
# optional known accounts:
./tools/step3_account_map.sh "$RPC" "<CONFIG_OR_VAULT>" "config"
```
Prints executable flag, owner (loader), data length; attempts IDL discovery if
tools exist; writes raw notes under the hunt dir when possible.

Gate:
- **Source available** (repo audit or verified) -> inventory `programs/**/src`,
  set **Y** in `coverage.md`, start reading value-moving instructions.
- **No source** -> run **STEP 3.5** (closed-source decompilation) first. If
  byte-identical or high-fidelity Rust is recovered, treat it as source and
  continue. Otherwise continue with IDL (if any), account layouts from
  explorers, transaction history, and disassembly; severity claims need
  stronger PoC discipline.
- **Source-only / pre-deploy** -> treat repo as scope; local unit PoCs; note
  pre-launch in the report Status line.

After inventory: list exclusions (clients, generated, vendor crates you will not
re-audit). Update coverage as each source file is read.

---

## STEP 3.5 - Closed-source decompilation (Rust / Anchor / native)

When Step 3 reports no source, treat the on-chain program as recoverable.
Goal (from OtterSec GoonFi V2 work, Oct 2026): recover Rust source that
**recompiles to the exact on-chain binary** (or as close as practical).
Once you have that source, ordinary Steps 4-9 apply. Never claim a full audit
on partial decompilation; track recovered functions in `coverage.md`.

### 3.5A. Dump and prepare the binary

```bash
# dump the exact deployed program (use the slot of interest if upgraded)
solana program dump <PROGRAM_ID> --url "$RPC" hunt-dir/program.so
# optional: dump at a historical slot if the program was upgraded
# solana program dump <PROGRAM_ID> --url "$RPC" --slot <SLOT> hunt-dir/program.so

# extract metadata, strings, and basic disassembly (install tools as needed)
file hunt-dir/program.so
readelf -S hunt-dir/program.so
strings hunt-dir/program.so | head -100
# if sbpf-disassembler / sbpf is available:
# cargo install sbpf  # or from blueshift-gg/sbpf
# sbpf disassemble hunt-dir/program.so > hunt-dir/disasm.txt
```

Also collect: IDL (if any), recent transactions, account layouts, and any
public docs. These bound the decompilation.

### 3.5B. Recommended tooling (install proactively)

Prefer tools that support Solana sBPF / eBPF and can feed an agent:

| Tool | Purpose | Notes |
|---|---|---|
| Binary Ninja + [bn-ebpf-solana](https://github.com/otter-sec/bn-ebpf-solana) | Static analysis, LLIL lifting, syscall signatures, memory maps, PDA/instruction grouping | MCP branch available for agent integration; install both `bn-ebpf-solana` and `binary_ninja_mcp` |
| [patina-research](https://github.com/renato-osec/patina-research) style pipeline | Agentic multi-stage decompilation (chela metadata, carpace deps, nacre type layouts, marinator renaming, signer signatures, flower blocks, mastermind full functions) | Currently Binary Ninja gated; adapt the agent hierarchy |
| sbpf / sbpf-disassembler | Fast disassembly of .so | Useful for initial function list and scoring input |
| Solana platform-tools (matching version) | Recompilation for scoring | Match the original toolchain (e.g. v1.48 for GoonFi); use `cargo build --release --locked` or Anchor equivalent |
| Alchemy Account Archive / Solrays / explorers | Historical accounts, transactions | Bound state and instruction usage |

Install what is missing (`cargo`, Binary Ninja plugins, Python MCP servers, etc.).
Document what you used in hunt notes so later runs are faster.

### 3.5C. Function-by-function recovery with recompilation scoring

1. Identify entrypoints and instruction handlers (branch on first instruction-data byte is a strong heuristic). Group by PDA / account access using Binary Ninja or static analysis.
2. Split work: an architect agent maps functions to instructions; worker agents take disjoint call-graph slices, starting from leaves that do not match known library functions.
3. For each function, produce compilable Rust. Prefer readable, idiomatic code over raw assembly.
4. Score against the original binary (deterministic, no LLM in the judge):
   - Align target instructions with recompiled function instructions.
   - Penalties (example from GoonFi work): 100 per missing/extra instruction, 60 per order error, 5 per wrong register/immediate, 1 per byte stack-offset error.
   - Score 0 = perfect match for that function.
5. Ban cheating constructs that achieve score 0 without real recovery: `asm!`, excessive `black_box`/`volatile`, `transmute`/`cast` abuse, unnecessary `#[no_mangle]` on internals, etc. Restrict `#[no_mangle]` to entrypoints and custom panic. Prefer `#[repr(C)]` for deterministic layouts. Exclude pure library functions from scoring (they come from Cargo.toml).
6. Judge on every candidate: rebuild the whole program with the original toolchain, rescore all functions. Merge only if total score improves, no function worsens, and no banned constructs appear.
7. After per-function matches, fix global differences: function emission order (Rust emits in source order), panic location strings (exact project layout), and any prologue padding. Reorder source and recreate directory structure until the binary is byte-identical (or the residual diff is explained and minimal).
8. Verify: compile and compare hashes, or reconstruct from the original deploy transaction's loader buffer writes (see GoonFi VERIFY.sh pattern). Optional: submit to a verifiable-build service once adjusted.

### 3.5D. Practical agent workflow

- Orchestrator (high-capability model) owns the goal and the judge.
- Subagents (smaller/faster models) handle single functions or narrow slices.
- Feed one function + its HLIL/LLIL + call context at a time. Do not dump the entire binary.
- Keep a running score table and a list of remaining functions.
- When a function scores 0 and passes the no-cheat check, mark it recovered and update `coverage.md`.
- If full byte-identical recovery is impractical (time, tooling, or complexity), stop at high-fidelity recovery of value-moving paths and continue the hunt on those paths with explicit coverage notes.

### 3.5E. After recovery

Treat recovered source as the audit target. Run Steps 4-9 on it. Update coverage with recovered files/paths. Note in the report that source was recovered via decompilation and whether the binary match was perfect or approximate. The GoonFi case showed that once readable source exists, ordinary audit techniques (including an auditing agent) can surface Critical issues that were invisible in the binary alone.

Gate:
- Byte-identical or high-fidelity source recovered -> proceed to Step 4 with the recovered source as `SRC_ROOT`.
- Only partial recovery -> continue with recovered paths + IDL/disassembly; state the coverage limit explicitly.
- Tooling blocked and no progress after proactive attempts -> fall back to IDL + transaction analysis and document the blocker.

---

## STEP 4 - Auth triage (find the free win first)

Run mechanical greps over source, then manually confirm the hot paths:

```bash
./tools/step4_auth_triage.sh "<SRC_ROOT>"
```

Scoreboard (fill from tool output + reading):

| Pattern | Why it matters |
|---|---|
| `UncheckedAccount` / bare `AccountInfo` without owner/signer check | Type cosplay / spoof |
| Missing `has_one` / `constraint = x.authority == signer` | Theft of user position |
| PDA seeds missing user key (global singleton where per-user needed) | One-user-only DoS or claim-any |
| `close =` on partial-fill paths | Premature close locks funds |
| `init` on ATA that anyone can pre-create | Permanent DoS of create flow |
| Fee / treasury wallet not pinned to config address | Fee diversion |
| Admin ix without role check | Free Critical if value-moving |
| `remaining_accounts` trusted without validation | CPI / oracle / vault spoof |
| Wrong token program (Token vs Token-2022) | Silent fail or extension bypass |

Also list every admin/keeper instruction. Confirm siblings of guarded functions
are not missing the same check (classic free win).

---

## STEP 5 - Foundation map (before deep findings)

Before writing findings, map the system. Keep this short; store in hunt notes.

### 5A. Account who-writes

For each important account type (config, vault, position, offer, market): who can
create, mutate, close it (user / admin / keeper / anyone)?

### 5B. Instruction graph

For each value path: accounts required -> constraints -> state writes -> CPI order.
Flag: state after CPI when re-read needed; `reload()` missing; close before residual
balance zero.

### 5C. Token paths (entry -> exit)

User ATA -> vault PDA ATA -> external venue (Raydium/Orca/stake pool) -> back.
Note any path to an arbitrary wallet (fee, residual, creator, admin).

### 5D. PDA seed table

| Account | Seeds | Bump stored? | Collision / grief risk |
|---|---|---|---|
| ... | ... | ... | ... |

### 5E. Structured first-pass checklist

For each item return **PASS / FAIL / UNCLEAR** with one sentence:

- [ ] Signer + ownership on every state-changing ix
- [ ] PDA seeds unique per logical entity (include user/mint/market as needed)
- [ ] No premature `close` while residual funds/state remain
- [ ] ATA use `init_if_needed` or idempotent create (not greifable `init`)
- [ ] Mint/token-program/decimals validated on first accept
- [ ] Token-2022 transfer fee / freeze / permanent delegate handled or blocked
- [ ] Oracle: feed id, staleness, confidence, status (if used)
- [ ] Slippage / min_out enforced on swaps and migrations
- [ ] CPI program id pinned (no arbitrary program)
- [ ] Rent refunds go to intended party; accounts closed only when empty
- [ ] Pause / blacklist actually covers all value paths
- [ ] Events / logs not security-critical alone (Solana log truncation)

---

## STEP 5.5 - Multi-angle adversarial pass (complex logic)

After the foundation map, force interaction bugs with **role-based angles**. Run on
**one chunk at a time** (e.g. only migrate; only take_offer; only harvest+swap).
Do not dump the whole codebase into one prompt.

### Angle 1 - Malicious actor (payout)

- Walk three hypothetical drain paths focused on deposit/withdraw/swap/claim.
- How would you **permanently lock** funds (close PDA, freeze mint, pre-init ATA,
  empty rent, wrong recipient ATA)?
- If Admin/Keeper is compromised, what is max damage, and what cannot be bypassed?

### Angle 2 - Economic and math

- Rounding, fee direction, decimal conversion, f64/u128 mix: free mint or leak?
- Donation of tokens into vault before migrate / snapshot: does it skew price?
- Can **internal books** desync from **actual token balances** after CPI failure
  or partial rollback myths (see bug class: Solana "rollback inconsistency")?

### Angle 3 - State and access

- Every state writer: missing constraint?
- Partial fill + close; claim without owner; duplicate init race.
- Type cosplay: same data layout, wrong discriminator / owner.

### Angle 4 - Edges

- Compute budget grief; unbounded remaining_accounts; large vec growth.
- Clock/slot advantages on epochs, funding, unlocks.
- Init frontrun of global config PDA.

### Angle 5 - External integrations

- AMM (Raydium/Orca/Meteora), stake pools, Pyth/Switchboard, LayerZero:
  pause, wrong accounts, unexpected return, decimal mismatch.
- Token-2022 extensions on accepted mints.

For each angle, record: **path attempted -> blocked by X** or **confirmed with PoC**.
Killed paths are as valuable as open ones.

---

## STEP 5.6 - Product-type deep dives

### Launchpad / bonding curve

- Virtual vs real reserves invariants; fee rounding to zero.
- Graduation/migration frontrun; pool pre-create at wrong price; donation before
  migrate; creator fee / residual SOL handling.
- Missing pause after migration; trading still open on dead curve.
- LP mint authority and freeze authority on deployed mint.
- Slippage ignores fees; min_out not passed into CPI.

### AMM / DEX

- Decimal misalignment on pool create; fee-on-transfer / Token-2022 insolvency.
- Global disable flags DoS all pools; dust orders grief keepers.
- Price manipulation via donation or empty-pool edge.
- Incorrect authority on vault token accounts.

### Vault / LST / yield converter

- Exchange rate inflated from principal (fees on user principal).
- Admin can swap stake pool / mint and corrupt all positions.
- Frozen or missing recipient ATA locks principal forever (push pattern).
- Harvest crank blocked after downtime (hard rate caps).
- Dual ledger: booked shares vs vault ATA balance vs venue claimable.

### Lending

- Blacklist/pause bypass on alternate withdraw path.
- Penalty math type casts (u16->u8), wrong field as principal repay.
- Oracle staleness/confidence; fixed-term expiry bypass.
- Reserve whitelist global vs per-reserve PDA mistakes.

### Perps / order keepers

- Keeper DoS of shifts/ADL via dust or spam updates.
- min_output not plumbed on increase/swap legs.
- Oracle feed id missing; far-future timestamps block feeds.
- Risk-free keeper trades; funding factor wrong on adaptive markets.
- Timelock / role segregation holes.

### OTC / escrow

- Premature close on partial take locks residual.
- ATA init grief; fee_wallet unconstrained.
- Maker cancel / whitelist DoS of other takers.
- Same-mint swap nonsense; missing min trade size.

### Bridge / OFT / ONFT / messaging

- Message size / return data limits.
- Frozen token_escrow DoS; decimal manipulation on mint.
- Multiple native OFTs for same mint; payload truncation.

### Staking / governance

- PDA seeds omit voter -> one voter only or claim-any.
- Missing auth on claim; rent refund to wrong party.
- Vote account not bound to signer.

---

## STEP 6 - Read with attack questions (by PRODUCT_TYPE)

Ask a fixed list. Hunt **one wrong assumption at the one moment value moves.**

Universal (Solana):
1. Who is the signer, and is the account actually theirs (seeds + has_one)?
2. What happens on partial success (close, fee, vault residual)?
3. Which program is invoked (CPI id pinned)?
4. Which mint and token program (decimals, extensions)?
5. Can a stranger init/front-run/close the critical PDA or ATA?
6. Does a failed later ix leave inconsistent state assumptions off-chain?

Then apply the PRODUCT_TYPE list in Step 5.6.

---

## STEP 6.5 - Bug-class detection playbook

Each = the pattern, the detection, the fix. Patterns distilled from real Solana
audits (OTC, launchpads, vaults, lending, perps, bridges, governance).

1. **Premature PDA close (partial fill).** `close = maker` on `take_offer` while
   residual amount remains -> vault tokens locked forever.
   *Detect:* `close =` on instructions that allow amount < total.
   *Fix:* close only when remaining == 0; or separate close ix.

2. **ATA init grief.** `init` on ATA the attacker can create first via CLI.
   *Detect:* `init` + `associated_token::` without `init_if_needed`.
   *Fix:* `init_if_needed` + idempotent ATA create; or accept pre-existing.

3. **Unconstrained fee / treasury wallet.** Fee ATA only checks mint, not
   `address = config.fee_wallet`.
   *Detect:* `AccountInfo` fee_wallet with no `address =` / `has_one`.
   *Fix:* pin to config; validate both fee ATAs.

4. **PDA seeds omit principal (user/market).** Seeds = `[b"voter", event]` only
   -> one account per event; or claim-any if ownership not checked.
   *Detect:* seeds without user pubkey where per-user state is required;
   claim ix missing `constraint = acc.owner == signer`.
   *Fix:* include user in seeds + store and check owner field.

5. **Missing signer / has_one on claim or withdraw.** Any valid PDA accepted.
   *Detect:* mut account with seeds but no link to `signer.key()`.
   *Fix:* seeds include signer; `has_one = owner`; explicit constraint.

6. **Migration / graduation frontrun.** Pool created at attacker price; donation
   skews reserves; migrate with zero slippage.
   *Detect:* migrate CPI without price/min_lp checks; permissionless pool create
   before migrate; no pause on curve after migrate.
   *Fix:* validate pool state; min_out; atomic create+seed; pause curve.

7. **Fee / decimal rounding to zero.** Fee = amount * bps / 10_000 floors to 0
   for small trades; decimal conversion wrong on mint/burn.
   *Detect:* multiply-divide order; f64; mismatched decimals across mints.
   *Fix:* checked math; round in protocol's favor; explicit decimal normalize.

8. **Token-2022 transfer fee / freeze / permanent delegate.** Booked amount !=
   received amount; freeze bricks vaults; permanent delegate steals.
   *Detect:* accepts arbitrary mints; uses `transfer` not `transfer_checked`;
   no extension allowlist.
   *Fix:* allowlist mints/extensions; use token interface + transfer_checked;
   account for fee-on-transfer balances.

9. **Oracle feed spoof / weak checks.** Missing feed id, confidence, staleness,
   or status; far-future timestamps DoS updates.
   *Detect:* price read without Clock check; Switchboard/Pyth account not pinned.
   *Fix:* full validation suite; pin feed accounts; reject wild timestamps.

10. **Keeper / admin grief and risk-free paths.** Dust orders, spam ADL updates,
    setting is_signer in malicious remaining accounts, stealing rent via close.
    *Detect:* privileged ix without bounds; close refund to caller not creator.
    *Fix:* role segregation; rent to creator; rate limits; account validation.

11. **Push-payment permanent lock.** Harvest/claim sends to recipient ATA that is
    frozen or missing; no pull alternative.
    *Detect:* mandatory destination ATA with no close/reassign path.
    *Fix:* pull pattern; allow recipient update; handle missing ATA.

12. **Blacklist / pause bypass.** Alternate instruction path omits the guard.
    *Detect:* compare all withdraw/borrow/claim entrypoints for shared guard.
    *Fix:* single internal guard; audit every entry.

13. **Solana "rollback" state myths / dual writers.** Off-chain indexers or second
    instruction assume atomic multi-program success incorrectly; or two ixs
    leave books desynced when one path errors mid-CPI.
    *Detect:* multi-step ops without atomic single-ix design; trusting logs only.
    *Fix:* single atomic ix; re-read accounts; do not treat logs as truth.

14. **Init frontrun of global config.** First `initialize` claims authority.
    *Detect:* permissionless init of singleton PDA.
    *Fix:* deploy-time init with known upgrade authority; or PDA seeds with
    program deployer key.

15. **Type cosplay / wrong program owner.** Account deserialized without
    owner + discriminator checks (especially `UncheckedAccount`).
    *Detect:* manual deserialize; missing owner == token_program / this program.
    *Fix:* Anchor `Account<T>` / `InterfaceAccount`; explicit owner checks.

16. **CPI program id not pinned.** User-supplied program account for swap/bridge.
    *Detect:* `AccountInfo` program with no address constraint.
    *Fix:* `address =` known program; or allowlist.

17. **Account space / realloc / INIT_SPACE wrong.** Later writes overflow or
    DoS; wrong space on mint with extensions.
    *Detect:* hard-coded space without extension room; missing realloc.
    *Fix:* correct INIT_SPACE; support realloc; extension-aware mint size.

18. **Rent / close refund to wrong party.** Approver receives rent; creator loses;
    empty accounts left forever.
    *Detect:* `close =` target; manual lamport drains.
    *Fix:* refund creator; close empty token accounts; document rent policy.

19. **Share / exchange-rate inflation.** Fee or yield math charges principal;
    admin swaps underlying pool; donation attacks if shares use raw balances.
    *Detect:* rate formulas; first depositor edges; admin set_pool without migrate.
    *Fix:* virtual offsets; careful rate components; gated admin with migration.

20. **Bridge / message bounds.** Oversized return data, truncated payloads,
    frozen escrow ATAs, decimal desync across chains.
    *Detect:* set_return_data size; escrow freeze authority; mint decimal config.
    *Fix:* size caps; dual-side decimal lock; escrow freeze revoked or gated.

Separate **owner-by-design centralization** (trust-risk, lower) from a
**permissionless exploit** (the real Critical). Never claim the former as the latter.

Also write down a Low, Medium, or High that is not a Critical by itself when it
can be combined into one (operating rule 13). Do not drop it only because the
single bug is below Critical. A confirmed Low, Medium, or High is reported at
that severity.

---

## STEP 7 - Prove it locally (mandatory)

```bash
./tools/step7_poc_scaffold.sh poc anchor
# or: ./tools/step7_poc_scaffold.sh poc native
```

Creates/refreshes a local PoC workspace (Anchor test or native banks-client /
LiteSVM style skeleton) and prints the exact test command.

Fill the test with the value-moving sequence, then run:
```bash
# Anchor
cd poc && anchor test
# or focused:
# yarn anchor test --skip-local-validator -- --test-threads 1

# Native / program-test style (if scaffolded)
cd poc && cargo test -- --nocapture
```

PoC quality bar:
- Compiles and **passes** with assertions that fail if the bug is fixed.
- Clear attacker vs victim; quantify loss, lock, or privilege.
- No synthetic sugar an on-chain attacker cannot do (unless labeled admin model).
- For permanent-lock claims: show residual funds + closed/blocked state.
- For economic claims: show net attacker profit or victim loss numbers.
- If full mainnet bankstate is impractical: exact-logic unit PoC + cite live
  account magnitudes for bound.

**Never** send exploit transactions to mainnet.

---

## STEP 8 - Severity call (honest rubric)

- **Critical** - unauthenticated theft/loss of a large share of funds, or a full
  drain / permanent freeze of user funds. One transaction (or atomic bundle), no
  special role; capital multiplies or unbounded protocol loss.
- **High** - unauthenticated, repeatable theft or preferential extraction of user
  funds but **bounded** (state the bound), or serious loss needing a common
  condition (e.g. Token-2022 mint accepted + transfer fee). Soft-lock of all exits
  under realistic conditions can be High.
- **Medium** - limited/conditional loss, griefing, ops freezes (keeper cannot
  crank), bounded value leak, asymmetric views, DoS of a subset of users.
- **Trust/centralization** - owner/admin/keeper-by-design power; disclose, but not
  a permissionless exploit. Label it as such.

Write the number you can defend, with the bound stated. Do not round up.

**Second-opinion gate (before disclosure):**
1. Compute-feasible on Solana (account limits, CU)?
2. Constraints / seeds actually block it?
3. State reachable in production config (mint freeze revoked? feature flag?)?
4. Mitigating code path elsewhere (other ix, crank, admin rescue)?
5. Temporary condition killed (can victim self-recover cheaply)?
Verdict: CONFIRMED / FALSE POSITIVE / NEEDS MORE WORK.

**Chain lead (operating rule 13).** Before you close a path as not Critical,
apply that rule: write the honest severity of the piece, name the second bug,
role, state, or instruction that would make it Critical, and trace that piece if
it exists. A chain confirmed with a sim/bankstest PoC is reported at the chain
severity. A missing piece stays as a lead line. Killed chains go in hunt notes.
A confirmed Low, Medium, or High is still reported at that severity.

---

## STEP 9 - Report (fill-in template)

Always use researcher name **deviykee**. Open every report with a plain-language
"What this means" section so a non-technical reader understands the danger before
any code. Do not use em dashes.

Keep a **master findings table** for the hunt (ID, severity, status, component,
chain-to-critical) and update it when findings are killed, reclassified, or kept
as a chain lead. `chain-to-critical` is the missing or confirmed next step, or
`n/a` when the finding cannot chain. Report every confirmed Low, Medium, and
High (operating rule 13), including ones that do not chain, at the finding's real
severity. One file per finding, or one section each in a multi-finding pack.

**Coverage honesty in the report:** cite `coverage.md` summary (`Coverage: X/Y
(Z%)`). If Z is low or core modules were only partially traced, state that the
review is path-scoped, not a full audit.

Scaffold:
```bash
python3 ./tools/step9_report_skeleton.py \
  --project "<PROJECT_NAME>" \
  --severity "<Low/Medium/High/Critical>" \
  --title "<one-line title>" \
  --cluster "<CLUSTER>" \
  --program "<PROGRAM_ID>" \
  --bound "<why; state the bound>" \
  --rpc "$RPC" \
  -o "reports/<project>-<severity>.md"
```

```markdown
# <PROJECT> - <SEVERITY>: <one-line title>
**Researcher:** deviykee
**Severity:** <Low/Medium/High/Critical> - <why; state the bound>
**Status:** Verified in local simulator / Anchor test. No mainnet state touched.
**Disclosure:** Private. Live-exploitable now.  <!-- if applicable -->

## What this means in plain language (read this first)
<Explain the danger for non-technical readers: what users thought was safe, what
can go wrong, who loses money, that no admin key is needed if that is true, and
what the bound is. Use a simple analogy if helpful. No em dashes.>

## Affected programs (<CLUSTER>)
| Role | Program ID / Account |
|---|---|
| <core program> | <ProgramId> |
| <vault / config> | <Pubkey> |

## Summary
<the one wrong assumption, plain language>

## Root cause
<exact code quoted: constraints, seeds, CPI>

## Attack
1. ... 2. ... 3. ...

## Impact
Auth: none | Capital: <flash/zero> | Frequency: <once/every cycle> | Victims: <who> | Magnitude: <number/%>

## Proof of concept
`anchor test` / `cargo test` in `poc/`  -> <result: attacker gained X / Y locked>

## Fix
<one or more concrete options>

## Disclosure & compensation
Good-faith private disclosure. I'd appreciate a bounty commensurate with a
<severity>. I am NOT conditioning the disclosure or fix on payment act on it now.
Happy to walk the team through it and review the fix.
deviykee
```

For multi-finding private packs, also ship:
- hunt notes (INTAKE, killed paths, PoC commands)
- structured checklist PASS/FAIL
- adversarial angle scoreboard (path attempted -> result)
- **coverage.md**
- **reports/contacts.md** (official inbox + source URL + quote)

---

## STEP 10 - Disclose and get paid

Run this **after** the report file exists. Disclose a confirmed Low, Medium, or
High the same way as a Critical (operating rule 13). The DM severity matches the
report. Do not hold a finding back because it is not Critical. Write the first DM
as a separate file (e.g. `reports/dm-<project>.md`). Do not put full exploit
steps in the first DM.

### 10A. Official contacts (mandatory every hunt)

Do not guess `security@` or DM the first @handle search returns. Build a
`reports/contacts.md` with **URL + exact quote** for every inbox you will use.
An email without a cited official page is not a contact.

Hunt in this order until you have a **bug-report** inbox (security@ / Immunefi /
HackerOne / Cantina beats a generic contact@):

1. Official docs FAQ / "security" / "bug bounty" / "contact" pages
   (`docs.*`, `help.*`, GitHub `docs/`, GitBook `.md` URLs).
2. `SECURITY.md`, `security.txt` (`/.well-known/security.txt`), Immunefi /
   HackerOne / Cantina / Code4rena program page for this project (not a
   lookalike).
3. Official forum / governance post **by a founder or staff account** that names
   a report address. Prefer `.json` API if the HTML hides emails behind
   Cloudflare (`data-cfemail`).
4. Official GitHub org **People** + matching verified X bios. Founders are backup
   DMs, not the first inbox.
5. **GitHub search** - use `gh search` to find security contacts:
   ```bash
   gh search code "filename:SECURITY.md" org:projectname
   gh search code "security@" org:projectname --language markdown
   gh search code "bug bounty OR bounty program" org:projectname
   gh search commits "security contact" repo:projectname/repo
   ```

Then verify socials:

- Official X: verified org/account whose bio links the **same** website as
  INTAKE. Reject lookalikes (one-letter typos, extra `l`/`o`, copied logo).
- Discord / Telegram: only the invite printed on official docs. FAQ "we have no
  Telegram" means any TG group is a scam.
- Never describe a live bug in a public forum, Discord, tweet, or GitHub issue.

```bash
./tools/step10_contact_hunt.sh "<DOCS_FAQ_URL>" "<WEBSITE>" "<FORUM_OR_SECURITY_MD>"
# write reports/contacts.md from the hits: Role | Address | Source URL | Quote
```

Show the user the **links and quotes** before sending. Prefer `security@` (or the
bounty platform) for the report; `contact@` is general and may be CC only.

Gate: no cited official inbox and no verified org X -> **do not send**. Tell the
user what you searched and what is missing.

1. **Use the inbox from 10A.** Never a public thread while it's live.
2. **First message (short):** use the template below. Who you are, plain impact,
   severity + bound, verified how, nothing touched, offer full report + PoC privately.
3. **Share via a PRIVATE repo** (add them as collaborator) or attach files. Never
   public until patched.
   ```bash
   gh repo create <project>-security-disclosure --private --source=. --push
   # confirm the RIGHT account first: gh api user --jq .login
   ```
4. **Skepticism is normal.** Point to the reproducible PoC: "run it yourself." Stay
   calm, don't threaten.
5. **Name the number AFTER they confirm.** Anchor on merit (severity + funds at risk
   + clean disclosure + you helped fix). No program = discretionary; plan a fair range.
6. **Help them fix it and review the patch.** This turns one bounty into repeat work.
7. **If they don't pay:** you still won a portfolio piece. After the fix ships, a
   factual timeline post (receipts, no rage, no threats) builds your name. Never
   bundle "pay or I post".

### First DM template

Researcher voice: **Iyke** (https://github.com/devIykee/security-research). Also sign reports as **deviykee** / Iyke.
No em dashes. Short first message. No full attack runbook. No threats. No "pay or I publish."

```bash
python3 ./tools/step10_dm_skeleton.py \
  --project "<PROJECT_NAME>" \
  --severity "<SEVERITY>" \
  --cluster "<CLUSTER>" \
  --component "<one-line component / flow, e.g. take_offer partial fill>" \
  --impact "<one plain sentence: what an attacker can do to user funds>" \
  --scope "<scope, e.g. every open offer with partial fills>" \
  -o "reports/dm-<project>.md"
```

Filled shape:
```text
Hey <PROJECT_NAME or short product name>.

I'm Iyke, a security researcher. (https://github.com/devIykee/security-research)

I've found and verified a <SEVERITY> vulnerability in <PROJECT_NAME>'s <one-line component / flow> on Solana (<CLUSTER>) that <one plain sentence: what an attacker can do to user funds>. It's live-exploitable right now on <scope>, so it's time-sensitive.

I reproduced it in a local Anchor / program-test PoC, nothing was touched on-chain.

I want to share the full private write-up with whoever owns the programs.

Who's the right person, or who do I talk to on the team?
```

---

## STEP 11 - Frontend Security Audit (always check)

**Run this step for every hunt, regardless of product type.** Frontend
vulnerabilities can be as critical as on-chain program bugs, especially unauthenticated server/database access and exposed
API keys that control RPC access, relayer/fee sponsorship, or authentication.

### 11A. Bundle analysis - extract frontend secrets

Solana apps (Vite / Next) bundle JavaScript into `/assets/*.js` or
`/_next/static/chunks/*.js`. These files often contain hardcoded secrets that
should never be client-side.

**Create and run the frontend analysis script:**

```bash
# Save as tools/step11_frontend_security.sh
cat > tools/step11_frontend_security.sh << 'SCRIPT'
#!/bin/bash
# Frontend Security Scanner (Solana)
WEBSITE=$1
OUTPUT_DIR=${2:-"frontend-security"}

mkdir -p "$OUTPUT_DIR"

echo "=== Frontend Security Analysis for $WEBSITE ==="

# 1. Fetch main page
echo "[1] Fetching main page..."
curl -s "$WEBSITE" -H "User-Agent: Mozilla/5.0" -o "$OUTPUT_DIR/index.html"

# 2. Extract JavaScript files
echo "[2] Extracting JavaScript files..."
grep -oP 'src="[^"]*\.js[^"]*"' "$OUTPUT_DIR/index.html" | \
  sed 's/src="//g' | sed 's/"//g' | sort -u > "$OUTPUT_DIR/js_files.txt"

echo "Found $(wc -l < "$OUTPUT_DIR/js_files.txt") JavaScript files"

# 3. Download largest bundle (usually the main app)
MAIN_JS=$(head -1 "$OUTPUT_DIR/js_files.txt")
if [[ $MAIN_JS == /* ]]; then
    MAIN_JS="${WEBSITE}${MAIN_JS}"
elif [[ $MAIN_JS != http* ]]; then
    MAIN_JS="${WEBSITE}/${MAIN_JS}"
fi

echo "[3] Downloading main bundle: $MAIN_JS"
curl -s "$MAIN_JS" -o "$OUTPUT_DIR/bundle.js"

# 4. Search for exposed credentials
echo ""
echo "=== CRITICAL: API Keys & Tokens ==="
grep -oiE '(api[_-]?key|apikey|secret[_-]?key|access[_-]?token)["\s:=]+[a-zA-Z0-9_-]{20,}' "$OUTPUT_DIR/bundle.js" | head -20

echo ""
echo "=== Bearer Tokens ==="
grep -oiE '(bearer|authorization)[":\s]+(bearer\s+)?[a-zA-Z0-9_-]{20,}' "$OUTPUT_DIR/bundle.js" | head -10

# 5. Extract Solana program ids / pubkeys (base58, 32-44 chars)
echo ""
echo "=== Solana Addresses (program ids / pubkeys) ==="
grep -oE '[1-9A-HJ-NP-Za-km-z]{32,44}' "$OUTPUT_DIR/bundle.js" | \
  grep -v '^1111111111111111111111111111111111111111111$' | \
  sort -u | head -30 > "$OUTPUT_DIR/pubkeys.txt"
echo "Found $(wc -l < "$OUTPUT_DIR/pubkeys.txt") unique base58 candidates (verify against known programs)"

# 6. RPC endpoints with keys (Solana providers)
echo ""
echo "=== RPC Endpoints (check for embedded keys) ==="
grep -oiE 'https?://[^"'\'']+\.(helius-rpc|helius|quiknode|quicknode|alchemy|triton|syndica|ankr|rpcpool|genesysgo)\.[^"'\'']+' "$OUTPUT_DIR/bundle.js" | \
  sort -u

# 7. API endpoints
echo ""
echo "=== API Endpoints ==="
grep -oiE 'https?://[a-zA-Z0-9.-]+/(api|v1|v2|graphql)[^"'\'']*' "$OUTPUT_DIR/bundle.js" | \
  sort -u | head -20

# 8. WebSocket endpoints
echo ""
echo "=== WebSocket Endpoints ==="
grep -oiE 'wss?://[^"'\'']+' "$OUTPUT_DIR/bundle.js" | sort -u

# 9. Database connection strings
echo ""
echo "=== Database/Private Data Exposure ==="
grep -iE '(mongodb|postgres|mysql|redis|connection.*string)' "$OUTPUT_DIR/bundle.js" | wc -l
echo "Found potential database references"

# 10. localStorage/sessionStorage (private data leakage)
echo ""
echo "=== Local Storage Keys ==="
grep -oE 'localStorage\.(get|set)Item\([^)]+\)' "$OUTPUT_DIR/bundle.js" | \
  sort -u | head -20

# 11. Authentication / keypair patterns
echo ""
echo "=== Auth / Keypair Patterns (private key leakage is CRITICAL) ==="
grep -oiE '(jwt|session|auth|token|secretKey|privateKey|Keypair\.fromSecretKey)[^,;]{0,50}' "$OUTPUT_DIR/bundle.js" | head -15

echo ""
echo "=== Analysis complete. Results in $OUTPUT_DIR/ ==="
echo "Review bundle.js for hardcoded secrets and credentials."
SCRIPT

chmod +x tools/step11_frontend_security.sh
```

**Run the analysis:**
```bash
./tools/step11_frontend_security.sh "$WEBSITE" hunt-dir/frontend-security
```

### 11B. Critical patterns to check

For each finding, assess severity and impact:

**CRITICAL findings:**
1. **Leaked keypair / private key** (`Keypair.fromSecretKey`, hardcoded 64-byte
   array, base58 secret). Impact: direct control of a signing wallet (fee payer,
   admin, relayer). Action: rotate/retire the key immediately, move signing
   server-side, check on-chain activity for that pubkey.
2. **Relayer / fee-sponsorship keys** (Octane, gasless relayer, Jito tip auth,
   sponsor endpoints). Impact: direct financial drain (SOL / fees charged to the
   project). Action: rotate, estimate potential loss, add spending limits.
3. **Bearer authentication tokens** (`Authorization.*Bearer`, hardcoded 32+ char
   secrets). Impact: auth bypass, impersonation. Action: rotate, audit backend.
4. **Database credentials** (`postgres://`, `mongodb://`, connection strings).
   Impact: direct DB access, data breach. Action: rotate, check exfiltration.
5. **Admin / master API keys.** Impact: privileged access, service abuse.
   Action: rotate and move to backend.

**HIGH findings:**
6. **RPC endpoint keys** (Helius, QuickNode, Triton, Alchemy, Syndica, Ankr).
   Pattern: `https://*.helius-rpc.com/?api-key=KEY`, `/<KEY>/` path keys.
   Impact: rate-limit exhaustion, monitoring, cost. Mitigation: check for origin
   / referrer allowlisting on the provider.
7. **Third-party API keys** (price feeds, indexers like Birdeye, The Graph).
   Impact: service abuse, rate limiting, unexpected bills. Action: backend proxy.

**MEDIUM findings:**
8. **Private user data in localStorage** (unencrypted). Impact: XSS can steal it.
   Action: encrypt sensitive data, use httpOnly cookies.
9. **Internal API endpoints exposed** (`/internal/`, `/admin/`, `/debug/`).
   Impact: information disclosure. Action: verify auth requirements.
10. **WebSocket endpoints** (oracle feeds, real-time data). Impact: front-running,
    competitive intel. Action: consider whether a direct client connection is
    necessary.

### 11C. Relayer / fee-sponsorship services

If you find keys for gasless / relayer services (Octane, a custom sponsor
endpoint, Jito auth):

```bash
grep -i "octane\|relayer\|sponsor\|feePayer\|gasless\|jito" hunt-dir/frontend-security/bundle.js | \
  grep -oE "(sponsor|feePayer|relay|tip|bundle)" | sort -u
```

**Critical questions:**
1. Is fee sponsorship enabled? (`sponsor`, `feePayer`, relayer endpoint)
2. What is the potential financial impact? (SOL/fees per op x expected usage)
3. Are there spending limits configured?
4. Can this be automated to drain the budget?

**Financial impact calculation:**
```
Estimated Loss = (Operations per day x cost per op x days until detected)
Example: 10,000 ops x $0.01 x 7 days = $700
```

### 11D. Testing exposed credentials

**Only test with user approval and document results:**

```bash
# Test if an RPC key works (check error message)
curl -s "https://mainnet.helius-rpc.com/?api-key=EXPOSED_KEY" \
  -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}'

# Expected responses:
# - origin/referrer error = good (protected)
# - valid "ok" result = bad (key works from anywhere)
# - invalid key error = already rotated
```

**Document test results in findings:**
- Tested and protected by origin/referrer allowlist (still should be backend)
- Tested and works without restrictions (CRITICAL)
- Not tested (would require a service account)

**Never** sign or send transactions with a leaked keypair, even to "prove" it.
A read-only `getHealth` / balance check is the proof. On-chain signing is out.

### 11E. Reporting frontend vulnerabilities

Frontend findings can be CRITICAL when they enable: direct financial loss
(relayer/fee drain), auth bypass (bearer tokens), database access (connection
strings), wallet control (leaked keypair), or mass user data breach (admin keys).

```markdown
# <PROJECT> - CRITICAL: Exposed <Service> API Key Enables Financial Drain

**Researcher:** deviykee
**Severity:** CRITICAL - $X,000-$Y,000 potential loss
**Component:** Frontend bundle (`/assets/index-*.js`)
**Status:** Publicly accessible, live exploitable

## What this means in plain language
The project's <Service> API key is hardcoded in publicly accessible JavaScript.
Anyone can extract it and <specific impact>. This could cost the project
$X,000-$Y,000 if exploited.

## Affected components
- **Frontend bundle:** https://<website>/assets/index-<hash>.js
- **Exposed credential:** `<KEY_PREFIX>...<KEY_SUFFIX>`
- **Service:** <Service Name> (<what it controls>)

## Root cause
Keys are embedded in client-side JavaScript instead of being protected
server-side. The key appears at line <N> in the bundle.

## Attack scenario
1. Attacker views page source or inspects network requests
2. Extracts the key from the JavaScript bundle (trivial, no tools needed)
3. Uses the key to <specific attack>
4. Project incurs costs or service disruption

## Impact
- **Auth required:** None (public website)
- **Financial impact:** $X-Y estimated (see calculation)
- **Exploitation difficulty:** Trivial (view-source)
- **Scope:** All users, entire service budget

## Proof of concept
```bash
curl -s https://<website>/assets/index-<hash>.js | grep -o "<pattern>"
# [OPTIONAL: test key with approval] Result: <works or protected>
```

## Fix
1. **Immediate (< 1 hour):** rotate the key, check usage logs, set spend alerts.
2. **Permanent (this week):** move calls to a backend proxy, store keys in
   server-side env vars, add per-user rate limiting and request auth.
3. **Architecture:**
   ```
   Before: Browser -> Service API (exposed key)
   After:  Browser -> Your Backend -> Service API (key in secrets)
   ```
```

### 11F. Update coverage tracking

Add frontend security to coverage.md:

```markdown
## Frontend Security Analysis

| Component | Analyzed | Findings | Severity |
|-----------|----------|----------|----------|
| JavaScript bundles | yes | 5 exposed keys | CRITICAL |
| API endpoints | yes | 2 internal paths | MEDIUM |
| localStorage usage | yes | No PII stored | PASS |
| WebSocket endpoints | yes | Oracle feeds exposed | LOW |

**Frontend security grade:** F (critical issues found)
```

### 11G. When to run frontend analysis

**Always run Step 11 when:**
- Target has a web frontend (most Solana DeFi projects)
- User asks to "check frontend" or "data leakage"
- Looking for quick wins before deep program analysis
- Program ids are hard to find (frontend config hides them)

**Run before or in parallel with program analysis:**
- Step 2 (locate programs) can use frontend findings
- Frontend keys might indicate centralization / trust risks
- Exposed admin keypairs change the threat model

### 11H. Frontend findings checklist

- [ ] All exposed credentials documented with severity
- [ ] Financial impact calculated for relayer / fee-sponsorship keys
- [ ] Testing results documented (what works, what's protected)
- [ ] Architecture recommendations provided
- [ ] Immediate and long-term fixes specified
- [ ] Other projects notified if they share the same vulnerable pattern

### 11I. Operating rules update (add to main list)

14. **Frontend security is mandatory.** Every hunt checks the frontend for
    exposed credentials, even when focusing on programs. Hardcoded API keys,
    bearer tokens, leaked keypairs, and relayer/fee-sponsorship keys can be as
    critical as program bugs. Also hunt for unauthenticated (or under-
    authenticated) server, API, and database access reachable from the
    frontend — open write endpoints, IDOR, and misconfigured
    Firebase/Supabase/GraphQL are primary targets (see 11J). Run Step 11
    before or during program analysis.
15. **Financial impact for infrastructure keys.** When relayer / fee-sponsorship
    keys or authenticated service keys are exposed, calculate the financial
    impact: `max_operations x cost_per_op x time_until_detected`. State it in the
    severity justification.
16. **Test frontend exposures responsibly.** Only test exposed keys with user
    approval. Document whether keys are protected by origin/referrer allowlisting.
    Testing is read-only verification, never exhausting rate limits or budgets,
    and never signing transactions with a leaked keypair.

**See also operating rule 13** (chain leads to a Critical). A frontend Low,
Medium, or High stays in scope when it is a step toward a Critical, and a
confirmed one is reported at that severity. Do not upgrade it on its own.


### 11J. Unauthenticated server / database access (primary frontend hunt goal)

**When hunting a frontend, exposed secrets are one path. The other — and often
higher-impact — path is unauthenticated (or under-authenticated) access to the
project's backend, APIs, or database.** Treat this as a first-class objective of
Step 11, not an afterthought.

You are looking for ways a stranger (no session, no wallet signature, no admin
cookie) can:

1. **Read or write the database** — open Firebase / Supabase / Appwrite / Hasura
   rules, leaked service-role keys, GraphQL that accepts mutations without auth,
   REST that creates / updates / deletes rows without a check.
2. **Call privileged server endpoints** — `/admin`, `/internal`, `/debug`,
   webhooks with no shared-secret, unsigned cloud-function URLs, open CORS +
   cookie-less state-changing POSTs.
3. **Bypass auth on user actions** — IDOR (change `userId` / `wallet` in the
   request and hit another account), missing ownership checks on update/delete,
   unsigned "claim" / "payout" / "credit" APIs that trust a client-supplied
   address.
4. **Abuse storage / queues** — public S3 / GCS / R2 buckets writable by anyone,
   open Redis / Mongo endpoints, message queues that accept unauthenticated
   publish.
5. **Chain a frontend secret into server access** — a leaked Bearer / service key
   that unlocks (1)–(4). Rate-limit-only keys are usually Low; keys that mutate
   production data are High/Critical.

**How to hunt (read-only / non-destructive first):**
- From the bundle, list every API base URL, GraphQL endpoint, Firebase config,
  Supabase URL + `anon` / `service_role` key, and webhook path.
- For each write-shaped endpoint (`POST`/`PUT`/`PATCH`/`DELETE`, GraphQL
  mutation, Firebase `.set` / `.update`, Supabase `.insert` / `.upsert`):
  try the call **without** cookies, Authorization headers, or wallet signatures.
  Document status codes and whether the mutation stuck.
- Check Firebase / Supabase security rules if the project is public or the
  rules file ships in the bundle / repo. Look for `allow read, write: if true`
  and `service_role` used from the client.
- IDOR: replay a legitimate update with a different `id` / `wallet` / `userId`.
- Never dump production user data, never delete, never spam write volume. One
  inert prove-it row (or a dry-run that the server rejects after the auth check)
  is enough for the PoC. Prefer staging / the project's own test fixtures when
  available.

**Severity (honest):**
- Unauthenticated **write** that changes balances, credits, inventory, roles, or
  payouts → Critical / High (map to the program's payout table).
- Unauthenticated **read** of PII, private keys, or full DB dumps → High.
- Unauthenticated read of non-sensitive public-ish data, or write that only
  affects the attacker's own empty sandbox → Low / Informational.
- Exposed `anon` keys that are designed to be public (Supabase anon with tight
  RLS) are not findings unless RLS actually fails.

Record every tested endpoint in `frontend-security/api-auth-matrix.md`
(method, path, auth required?, stranger result, data impact). Failures to
mutate as a stranger go in the kill-log, not the findings table.


---

## Appendix A - Solana cheat-sheet

```bash
solana cluster-version --url $RPC
solana slot --url $RPC
solana program show <PROGRAM_ID> --url $RPC
solana account <PUBKEY> --url $RPC -v
solana logs <PROGRAM_ID> --url $RPC
spl-token display <MINT> --url $RPC
spl-token accounts --owner <OWNER> --url $RPC

# Anchor
anchor build
anchor test
anchor keys list

# Search
rg -n "declare_id!|seeds\s*=|close\s*=" programs
rg -n "invoke_signed|CpiContext|transfer_checked" programs
rg -n "UncheckedAccount|remaining_accounts" programs
```

Explorers: Solana Explorer, Solscan, custom cluster explorers.
IDL: Anchor IDL accounts, `.anchor/`, public GitHub `target/idl/*.json`.

---

## Appendix B - adversarial prompt pack (copy into subagent or self)

Use after Step 5 foundation map. One chunk + one angle per invocation.

1. Act as a malicious actor trying to drain vaults. Three exploit paths on the current instruction set.
2. How would you permanently lock user funds (close, freeze, ATA grief, wrong recipient)?
3. Assume Admin/Keeper is compromised. Max damage? What safeguards remain?
4. Analyze fee and decimal math. Rounding or free trades?
5. Donation into vault before migrate/snapshot. How does pricing react?
6. Can internal accounting desync from ATA balances after CPI?
7. Every state-writing instruction: missing signer or has_one?
8. Premature close or reclaim of rent on partial flows?
9. Type cosplay or UncheckedAccount owner gaps?
10. Token-2022 extensions on accepted mints?
11. Oracle feed id / staleness / confidence gaps?
12. CPI program id not pinned?
13. Init frontrun of global config?
14. Pause/blacklist bypass on alternate path?
15. Which Low, Medium, or High is not a Critical alone, but is a step on a path
    to one? Name the missing piece (operating rule 13).

---

## Appendix C - hunt session hygiene

- Keep private: INTAKE fills, program ids of live bugs, draft reports/DMs, live PoCs until patched.
- Master findings table stays updated when severity changes.
- Killed Critical candidates and killed chain leads listed in hunt notes
  (prevents re-opening bad claims).
- Open Low, Medium, and High chain leads stay on the master findings table at
  their real severity (operating rule 13).
- Prefer local exact-logic unit tests for accounting bugs; use live RPC for magnitude.
- **coverage.md** updated incrementally; low Z% stated openly; exclusions listed with reasons.

**Reminder:** simulator only, honest severity, keep Low / Medium / High chain
leads and report every confirmed Low, Medium, and High (operating rule 13), ask
don't threaten, kill your own bad findings, private until patched, stay
token-conservative and route mechanical work to smaller models. Map first,
multi-angle second, product-type deep dive, frontend check (Step 11), PoC before
Critical, **track coverage so thoroughness is real**. That discipline is the job.

deviykee
