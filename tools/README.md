# Bug-hunt playbook tools

Mechanical helpers for **Iyke's Solana Bughunt Skill** (`iykes-solana-bughunt-skill`).
Judgment (severity, root cause, disclosure strategy) stays in `SKILL.md`. These
scripts only run the repeatable shell/python steps.

## Prerequisites

```bash
# Solana CLI (solana, spl-token)
sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"
# ensure ~/.local/share/solana/install/active_release/bin is on PATH

# Optional but recommended for source hunts:
# - anchor CLI (avm)
# - cargo / rustup
# - node + yarn (Anchor tests)

# Python 3 (stdlib only for the fillers)
# curl (usually preinstalled)
# gh is optional (only for Step 10 private disclosure repo creation)
```

Make scripts executable once:

```bash
chmod +x tools/*.sh tools/*.py
```

Smoke-check graceful failures:

```bash
./tools/selftest.sh
```

## Scripts

### `step1_ground_truth.sh` - Step 1

**Purpose:** Confirm RPC alive; print slot / version.

**Usage:** `step1_ground_truth.sh <RPC_URL>`

**Exit:** `0` pass · `1` RPC error · `2` usage

---

### `step2_bundle_grep.sh` - Step 2B

**Purpose:** Grep Vite/Next JS bundles for base58-like pubkeys and program config keys.

**Usage:** `step2_bundle_grep.sh <WEBSITE_URL>`

---

### `step3_surface_map.sh` - Step 3

**Purpose:** Program account surface (executable, owner, data length).

**Usage:** `step3_surface_map.sh <RPC_URL> <PROGRAM_ID>`

---

### `step3_account_map.sh` - Step 3

**Purpose:** Map a single account (config, vault, mint, ATA).

**Usage:** `step3_account_map.sh <RPC_URL> <PUBKEY> [label]`

---

### `step4_auth_triage.sh` - Step 4

**Purpose:** Grep source tree for high-signal auth / PDA / CPI / close patterns.

**Usage:** `step4_auth_triage.sh <SRC_ROOT>`

---

### `step7_poc_scaffold.sh` - Step 7

**Purpose:** Scaffold local sim-only PoC (anchor or native cargo test stub).

**Usage:** `step7_poc_scaffold.sh <POC_DIR> [anchor|native]`

---

### `step9_report_skeleton.py` - Step 9

**Purpose:** Fill report markdown skeleton.

---

### `step10_contact_hunt.sh` - Step 10A

**Purpose:** Fetch official docs/forum pages and print candidate security inboxes
(emails, Immunefi/HackerOne/Cantina/Code4rena links) with nearby quote lines.
Decodes Cloudflare `data-cfemail`. Does not send mail; you still write
`reports/contacts.md` with URL + exact quote and reject lookalikes.

**Usage:** `step10_contact_hunt.sh <URL> [URL ...]`

**Exit:** `0` some fetch ok · `1` all fetches failed · `2` usage

---

### `step10_dm_skeleton.py` - Step 10

**Purpose:** Fill first private DM text.

---

### `step11_frontend_security.sh` - Step 11

**Purpose:** Scan the web frontend bundle for hardcoded secrets (API keys, bearer
tokens, leaked keypairs, RPC/relayer keys, Solana pubkeys, DB strings). Created
inline from the heredoc in `SKILL.md` Step 11A on first run.

**Usage:** `step11_frontend_security.sh <WEBSITE> [OUTPUT_DIR]`

---

### `selftest.sh`

Usage/exit smoke for all tools (no live RPC required for most checks).
