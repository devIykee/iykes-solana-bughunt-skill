#!/usr/bin/env bash
# =============================================================================
# step7_poc_scaffold.sh
#
# Purpose:
#   Scaffold a local sim-only PoC directory (Anchor test stub or native cargo).
#
# Usage:
#   step7_poc_scaffold.sh <POC_DIR> [anchor|native]
# =============================================================================
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: step7_poc_scaffold.sh <POC_DIR> [anchor|native]

Creates a SAFE local-only PoC skeleton. Never targets mainnet.

Exit: 0 written; 2 usage
EOF
  exit 2
}

if [[ $# -ge 1 && ( "$1" == "-h" || "$1" == "--help" ) ]]; then usage; fi
[[ $# -ge 1 && $# -le 2 ]] || usage
POC="${1%/}"
KIND="${2:-anchor}"

mkdir -p "$POC"
README="$POC/README.md"
cat >"$README" <<'EOF'
# PoC (SAFE - local simulator only)

This directory is for **local** Anchor tests or `solana-program-test` / LiteSVM
proofs. Do **not** send exploit transactions to mainnet.

Fill the test with:

1. Setup: program, mints, vaults, attacker/victim keypairs
2. Victim state: deposits / open offer / position
3. Attacker sequence
4. Assert: attacker gain, victim loss, or permanent lock (residual + closed PDA)

Run:

```bash
# anchor
anchor test

# native
cargo test -- --nocapture
```
EOF

if [[ "$KIND" == "native" ]]; then
  mkdir -p "$POC/tests"
  cat >"$POC/tests/poc.rs" <<'EOF'
// SAFE local PoC stub. Wire to solana-program-test or LiteSVM in your workspace.
// This file is intentionally incomplete until you copy program deps into Cargo.toml.

#[test]
fn test_exploit_placeholder() {
    // 1. arrange accounts
    // 2. victim deposits / opens position
    // 3. attacker executes value-moving sequence
    // 4. assert net profit or permanent lock
    assert!(true, "replace with real assertions that fail when bug is fixed");
}
EOF
  cat >"$POC/Cargo.toml" <<'EOF'
[package]
name = "solana-bughunt-poc"
version = "0.1.0"
edition = "2021"
publish = false

[dev-dependencies]
# Add: solana-program-test, solana-sdk, anchor-client, litesvm, etc. as needed
EOF
  echo "Wrote native stub under $POC"
  echo "Next: add program deps and implement tests/poc.rs"
  echo "GATE: OK - scaffold ready. Prove on simulator only."
  exit 0
fi

# default: anchor-style test stub (works inside an existing Anchor workspace if copied)
mkdir -p "$POC/tests"
cat >"$POC/tests/poc.ts" <<'EOF'
/**
 * SAFE local PoC stub for Anchor.
 * Run inside the target Anchor workspace (or copy program into this scaffold).
 * Never points at mainnet exploit sends.
 */
import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { assert } from "chai";

describe("bughunt-poc", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  it("proves the finding with assertions that fail if fixed", async () => {
    // 1. load program + derive PDAs
    // 2. set up victim state (deposit / offer / position)
    // 3. attacker sequence
    // 4. assert balances / account closed / residual locked
    assert.ok(true, "replace with real balance assertions");
  });
});
EOF

cat >"$POC/Anchor.toml.example" <<'EOF'
# Copy relevant [programs.localnet] entries from the target repo.
# [provider]
# cluster = "Localnet"
# wallet = "~/.config/solana/id.json"

# [scripts]
# test = "yarn run ts-mocha -p ./tsconfig.json -t 1000000 tests/**/*.ts"
EOF

echo "Wrote Anchor-style stub under $POC/tests/poc.ts"
echo "Next: drop into the target Anchor workspace or wire program id + IDL."
echo "Run: anchor test   (from the program workspace)"
echo "GATE: OK - scaffold ready. Prove on simulator only."
exit 0
