#!/usr/bin/env bash
# =============================================================================
# step4_auth_triage.sh
#
# Purpose:
#   Grep Solana/Anchor source for high-signal auth, PDA, close, CPI patterns.
#
# Usage:
#   step4_auth_triage.sh <SRC_ROOT>
# =============================================================================
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: step4_auth_triage.sh <SRC_ROOT>

Greps programs for UncheckedAccount, seeds, close=, CPI, token transfers, etc.
Prints a scoreboard. Manual confirmation still required.

Exit: 0 always if root exists; 2 usage
EOF
  exit 2
}

if [[ $# -eq 1 && ( "$1" == "-h" || "$1" == "--help" ) ]]; then usage; fi
[[ $# -eq 1 ]] || usage
ROOT="$1"
[[ -d "$ROOT" ]] || { echo "GATE: FAIL - not a directory: $ROOT" >&2; exit 1; }

RG=rg
if ! command -v rg >/dev/null 2>&1; then
  RG=grep
fi

echo "== STEP 4: auth triage (source greps) =="
echo "ROOT: $ROOT"
echo

section() { echo; echo "### $1"; }

run_grep() {
  local pat="$1"
  if [[ "$RG" == "rg" ]]; then
    rg -n --glob '*.rs' "$pat" "$ROOT" 2>/dev/null | head -40 || true
  else
    grep -Rn --include='*.rs' -E "$pat" "$ROOT" 2>/dev/null | head -40 || true
  fi
}

section "UncheckedAccount / bare AccountInfo"
run_grep 'UncheckedAccount|AccountInfo<'

section "close = (premature close risk)"
run_grep 'close\s*='

section "init ATA / init_if_needed"
run_grep 'init_if_needed|associated_token::|token::mint'

section "seeds / bump"
run_grep 'seeds\s*='

section "has_one / constraint / signer"
run_grep 'has_one|constraint\s*=|Signer<'

section "CPI / invoke_signed"
run_grep 'invoke_signed|invoke\(|CpiContext'

section "transfer / transfer_checked / token interface"
run_grep 'transfer_checked|token::transfer|token_interface|spl_token'

section "Token-2022 / extensions"
run_grep 'Token-2022|token_2022|TransferFee|transfer_fee|permanent_delegate|freeze_authority|ExtensionType'

section "remaining_accounts"
run_grep 'remaining_accounts'

section "oracle / pyth / switchboard"
run_grep 'pyth|switchboard|Oracle|price_feed|PriceUpdate'

echo
echo "GATE: Review hits above. Mark OPEN vs guarded in hunt notes."
echo "Any value-moving ix without signer/has_one/seeds-bound owner = CHECK FIRST."
exit 0
