#!/usr/bin/env bash
# =============================================================================
# step3_surface_map.sh
#
# Purpose:
#   Map a Solana program account: executable, owner, data length.
#
# Usage:
#   step3_surface_map.sh <RPC_URL> <PROGRAM_ID>
# =============================================================================
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: step3_surface_map.sh <RPC_URL> <PROGRAM_ID>

Print program account surface for Step 3.

Exit: 0 mapped; 1 RPC/account error; 2 usage
EOF
  exit 2
}

if [[ $# -eq 1 && ( "$1" == "-h" || "$1" == "--help" ) ]]; then usage; fi
[[ $# -eq 2 ]] || usage
RPC="$1"
PID="$2"
export TIMEOUT_SECS="${TIMEOUT_SECS:-25}"

run_timeout() {
  if command -v timeout >/dev/null 2>&1; then
    timeout "$TIMEOUT_SECS" "$@"
  else
    "$@"
  fi
}

echo "== STEP 3: program surface map =="
echo "RPC: $RPC"
echo "PROGRAM: $PID"

if command -v solana >/dev/null 2>&1; then
  set +e
  out=$(run_timeout solana program show "$PID" --url "$RPC" 2>&1)
  rc=$?
  set -e
  if [[ $rc -eq 0 ]]; then
    echo "$out"
    echo "GATE: OK - program show succeeded. Pull source/IDL next."
    exit 0
  fi
  echo "program show failed ($rc): $out"
  set +e
  acc=$(run_timeout solana account "$PID" --url "$RPC" 2>&1)
  rc2=$?
  set -e
  if [[ $rc2 -ne 0 ]]; then
    echo "GATE: FAIL - account not found or RPC error: $acc" >&2
    exit 1
  fi
  echo "$acc"
  echo "GATE: OK - account exists (may be non-program). Continue with source if any."
  exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "GATE: FAIL - need solana CLI or curl" >&2
  exit 1
fi

body=$(printf '{"jsonrpc":"2.0","id":1,"method":"getAccountInfo","params":["%s",{"encoding":"base64"}]}' "$PID")
set +e
resp=$(run_timeout curl -sS -X POST "$RPC" -H 'Content-Type: application/json' -d "$body" 2>&1)
rc=$?
set -e
if [[ $rc -ne 0 ]]; then
  echo "GATE: FAIL - curl error: $resp" >&2
  exit 1
fi
echo "$resp" | head -c 4000
echo
if echo "$resp" | grep -q '"value":null'; then
  echo "GATE: FAIL - account null (wrong id or cluster)" >&2
  exit 1
fi
echo "GATE: OK - getAccountInfo returned a value. Decode owner/dataLen offline."
exit 0
