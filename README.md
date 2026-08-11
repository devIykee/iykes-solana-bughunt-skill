# Iyke's Solana Bughunt Skill

End-to-end playbook for hunting bugs in **Solana / Anchor / native Rust programs**,
then turning a verified finding into a **responsible, private disclosure**.

Fill the INTAKE block in [`SKILL.md`](SKILL.md), run Steps 1-10 in order, and use
the scripts in [`tools/`](tools/) for every mechanical probe (RPC checks, program
discovery, surface map, auth triage, PoC scaffold, report/DM skeletons). Judgment
calls - severity, root cause, exploit design, disclosure strategy - stay manual.

**Researcher identity for reports and DMs:** [deviykee](https://x.com/deviykee) / **Iyke**.

| | |
|---|---|
| Skill id | `iykes-solana-bughunt-skill` |
| Companion (EVM) | [iykes-web3-bughunt-skill](https://github.com/devIykee/iykes-web3-bughunt-skill) |
| Changelog | [CHANGELOG.md](CHANGELOG.md) |

---

## What this is

A **copy-paste operational playbook** plus **CLI tools** so you (or any coding
agent) do not re-derive the same bash every hunt:

1. **Ground truth** - is the RPC/cluster real?
2. **Find core programs** - docs, bundle grep, browser, explorer
3. **Surface map** - program/account layout (+ set coverage denominator Y)
4. **Auth triage** - constraints, seeds, signers, close/CPI greps
5. **Foundation map** - who-writes, instruction graph, token paths, PDA table, checklist
5.5 **Multi-angle adversarial pass** - drain/freeze/admin, economic, state, edges, externals (chunked)
5.6 **Product-type deep dives** - launchpad, AMM, vault/LST, lending, perps, OTC, bridge, governance
6. **Attack questions + bug-class playbook** (Solana-specific patterns)
7. **Local sim PoC** (Anchor / banks-client / LiteSVM - never mainnet exploit)
8. **Honest severity** + second-opinion gate
9. **Report** (template + master findings table + **coverage.md** honesty + optional filler script)
10. **Private first DM** (template + optional filler script)

**Coverage:** every hunt maintains `coverage.md` (files opened, paths traced, X/Y %, exclusions), updated as work proceeds - not only at the end.

**Best fit:** Anchor and native Solana programs (launchpads, AMMs, vaults, lending, perps, OTC, bridges). Also strong for **source/pre-deploy** repo hunts with local unit PoCs.

Optional companions (if available in your environment): broader smart-contract audit checklists, Anchor pattern libraries, critical-only severity rubrics. This playbook remains the lead for intake, gates, severity honesty, and private disclosure.

This repo is **tooling only**. Do not commit filled INTAKE blocks, live hunt program ids, draft reports/DMs, or `poc/` build artifacts. Keep hunt work in a private workspace.

---

## Repository layout

```text
.
├── SKILL.md           # Playbook: INTAKE, rules, Steps 1-10, templates
├── CHANGELOG.md
├── README.md
└── tools/
    ├── README.md
    ├── selftest.sh
    ├── step1_ground_truth.sh
    ├── step2_bundle_grep.sh
    ├── step3_surface_map.sh
    ├── step3_account_map.sh
    ├── step4_auth_triage.sh
    ├── step7_poc_scaffold.sh
    ├── step9_report_skeleton.py
    └── step10_dm_skeleton.py
```

---

## Prerequisites

```bash
# Solana CLI (solana, spl-token)
sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"
# put the install bin dir on PATH

# Optional for source hunts / PoCs:
# - rustup + cargo
# - anchor CLI (avm)
# - node + yarn (Anchor tests)

# Python 3 + curl
# Debian/Ubuntu:
sudo apt-get update && sudo apt-get install -y python3 curl
# macOS: brew install python3 curl

# Optional: GitHub CLI (private disclosure repo in Step 10)
# https://github.com/cli/cli#installation  then: gh auth login
```

---

## Quick start

```bash
git clone https://github.com/devIykee/iykes-solana-bughunt-skill.git
cd iykes-solana-bughunt-skill
chmod +x tools/*.sh tools/*.py
./tools/selftest.sh
```

Then open [`SKILL.md`](SKILL.md), fill INTAKE, and run the steps. Point any coding
agent (Claude, Cursor, Codex, Windsurf, Aider, OpenCode, etc.) at this repo or
paste/load `SKILL.md` as the hunt playbook - the steps and tools are the same.

```bash
./tools/step1_ground_truth.sh "https://api.mainnet-beta.solana.com"
./tools/step4_auth_triage.sh /path/to/programs
./tools/step7_poc_scaffold.sh ./poc anchor
```

---

## Rules (short)

- Simulator / bankstest / read-only only - never exploit mainnet
- Honest severity with explicit bounds
- Kill your own finding if it does not hold
- Private until patched; ask, never threaten
- Track coverage; never imply a full audit when Z% is low
