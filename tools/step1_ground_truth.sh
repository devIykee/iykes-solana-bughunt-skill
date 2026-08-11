#!/usr/bin/env bash
# =============================================================================
# step1_ground_truth.sh
#
# Purpose:
#   Confirm the Solana RPC is alive (playbook Step 1).
#
# Usage:
#   step1_ground_truth.sh <RPC_URL>
#
# Exit codes:
#   0  RPC usable (GATE PASS)
#   1  RPC error (GATE FAIL / STOP)
#   2  bad usage / --help
# =============================================================================
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: step1_ground_truth.sh <RPC_URL>

Confirm the Solana RPC is reachable and returns a slot / health.

Args:
  RPC_URL  JSON-RPC endpoint (from INTAKE RPC)

Example:
  ./tools/step1_ground_truth.sh "https://api.mainnet-beta.solana.com"

Exit: 0 pass; 1 RPC error; 2 usage
EOF
  exit 2
}

if [[ $# -eq 1 && ( "$1" == "-h" || "$1" == "--help" ) ]]; then usage; fi
[[ $# -eq 1 ]] || usage
RPC="$1"
export TIMEOUT_SECS="${TIMEOUT_SECS:-20}"

run_timeout() {
  if command -v timeout >/dev/null 2>&1; then
    timeout "$TIMEOUT_SECS" "$@"
  else
    "$@"
  fi
}

echo "== STEP 1: ground truth (Solana) =="
echo "RPC: $RPC"

# Prefer solana CLI when present; fall back to raw JSON-RPC.
if command -v solana >/dev/null 2>&1; then
  set +e
  slot=$(run_timeout solana slot --url "$RPC" 2>&1)
  rc_slot=$?
  set -e
  if [[ $rc_slot -ne 0 ]]; then
    echo "GATE: FAIL - solana slot error: $slot" >&2
    echo "STOP. Likely vaporware/scam or bad RPC. Do not sink hours." >&2
    exit 1
  fi
  echo "solana slot: $slot"

  set +e
  ver=$(run_timeout solana cluster-version --url "$RPC" 2>&1)
  rc_ver=$?
  set -e
  if [[ $rc_ver -eq 0 ]]; then
    echo "solana cluster-version: $ver"
  else
    echo "solana cluster-version: (unavailable) $ver"
  fi

  echo "GATE: PASS - Real cluster confirmed (slot=$slot). Continue."
  exit 0
fi

# curl JSON-RPC fallback
if ! command -v curl >/dev/null 2>&1; then
  echo "GATE: FAIL - neither solana CLI nor curl available" >&2
  exit 1
fi

body='{"jsonrpc":"2.0","id":1,"method":"getSlot"}'
set +e
resp=$(run_timeout curl -sS -X POST "$RPC" -H 'Content-Type: application/json' -d "$body" 2>&1)
rc=$?
set -e
if [[ $rc -ne 0 ]]; then
  echo "GATE: FAIL - curl error: $resp" >&2
  exit 1
fi
if ! echo "$resp" | grep -q '"result"'; then
  echo "GATE: FAIL - unexpected RPC response: $resp" >&2
  echo "STOP. Likely vaporware/scam or bad RPC. Do not sink hours." >&2
  exit 1
fi
echo "getSlot response: $resp"
echo "GATE: PASS - Real cluster confirmed via JSON-RPC. Continue."
exit 0
