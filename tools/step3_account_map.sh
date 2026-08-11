#!/usr/bin/env bash
# =============================================================================
# step3_account_map.sh
#
# Purpose:
#   Map a single account (config, vault, mint, ATA).
#
# Usage:
#   step3_account_map.sh <RPC_URL> <PUBKEY> [label]
# =============================================================================
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: step3_account_map.sh <RPC_URL> <PUBKEY> [label]

Print account info for Step 3 mapping.

Exit: 0 mapped; 1 error; 2 usage
EOF
  exit 2
}

if [[ $# -ge 1 && ( "$1" == "-h" || "$1" == "--help" ) ]]; then usage; fi
[[ $# -ge 2 && $# -le 3 ]] || usage
RPC="$1"
KEY="$2"
LABEL="${3:-account}"
export TIMEOUT_SECS="${TIMEOUT_SECS:-25}"

run_timeout() {
  if command -v timeout >/dev/null 2>&1; then
    timeout "$TIMEOUT_SECS" "$@"
  else
    "$@"
  fi
}

echo "== STEP 3: account map ($LABEL) =="
echo "RPC: $RPC"
echo "PUBKEY: $KEY"

if command -v solana >/dev/null 2>&1; then
  set +e
  out=$(run_timeout solana account "$KEY" --url "$RPC" -v 2>&1)
  rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    echo "GATE: FAIL - $out" >&2
    exit 1
  fi
  echo "$out"
  echo "GATE: OK - $LABEL mapped."
  exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "GATE: FAIL - need solana CLI or curl" >&2
  exit 1
fi

body=$(printf '{"jsonrpc":"2.0","id":1,"method":"getAccountInfo","params":["%s",{"encoding":"jsonParsed"}]}' "$KEY")
set +e
resp=$(run_timeout curl -sS -X POST "$RPC" -H 'Content-Type: application/json' -d "$body" 2>&1)
rc=$?
set -e
[[ $rc -eq 0 ]] || { echo "GATE: FAIL - $resp" >&2; exit 1; }
echo "$resp" | head -c 4000
echo
echo "GATE: OK - raw getAccountInfo for $LABEL."
exit 0
