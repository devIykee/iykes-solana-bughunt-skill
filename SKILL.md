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
  conditions). Maintain coverage.md incrementally (files opened, paths traced,
  %, exclusions); never imply a complete audit when coverage is low.
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
| `tools/step4_auth_triage.sh` | 4 | `<SRC_ROOT>` | constraint/signer/CPI grep scoreboard | Free-win missing-auth / loose seeds |
| `tools/step7_poc_scaffold.sh` | 7 | `<POC_DIR> [anchor\|native]` | Anchor or banks-client PoC skeleton | Repeatable sim-only proof setup |
| `tools/step9_report_skeleton.py` | 9 | INTAKE + severity + title (+ optional) | filled Step 9 report skeleton | Same report shape every hunt |
| `tools/step10_dm_skeleton.py` | 10 | project/severity/cluster/component/impact | filled first DM text | Consistent private first contact |
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
- **No source** -> continue with IDL (if any), account layouts from explorers,
  and transaction history; severity claims need stronger PoC discipline.
- **Source-only / pre-deploy** -> treat repo as scope; local unit PoCs; note
  pre-launch in the report Status line.

After inventory: list exclusions (clients, generated, vendor crates you will not
re-audit). Update coverage as each source file is read.

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

---

## STEP 9 - Report (fill-in template)

Always use researcher name **deviykee**. Open every report with a plain-language
"What this means" section so a non-technical reader understands the danger before
any code. Do not use em dashes.

Keep a **master findings table** for the hunt (ID, severity, status, component)
and update it when findings are killed or reclassified.

**Coverage honesty in the report:** cite `coverage.md` summary (`Coverage: X/Y
(Z%)`). If Z is low or core modules were only partially traced, state that the
review is path-scoped, not a full audit.

Scaffold:
```bash
python3 ./tools/step9_report_skeleton.py \
  --project "<PROJECT_NAME>" \
  --severity "<High/Med/Crit>" \
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
**Severity:** <High/Med/Crit> - <why; state the bound>
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

---

## STEP 10 - Disclose and get paid

Run this **after** the report file exists. Write the first DM as a separate file
(e.g. `reports/dm-<project>.md`). Do not put full exploit steps in the first DM.

1. **Find the private channel** from X_HANDLE (verified account / security email).
   Never a public thread while it's live.
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

---

## Appendix C - hunt session hygiene

- Keep private: INTAKE fills, program ids of live bugs, draft reports/DMs, live PoCs until patched.
- Master findings table stays updated when severity changes.
- Killed Critical candidates listed in hunt notes (prevents re-opening bad claims).
- Prefer local exact-logic unit tests for accounting bugs; use live RPC for magnitude.
- **coverage.md** updated incrementally; low Z% stated openly; exclusions listed with reasons.

**Reminder:** simulator only, honest severity, ask don't threaten, kill your own bad
findings, private until patched, stay token-conservative and route mechanical
work to smaller models. Map first, multi-angle second, product-type deep dive,
PoC before Critical, **track coverage so thoroughness is real**. That discipline
is the job.

deviykee
