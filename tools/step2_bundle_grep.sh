#!/usr/bin/env bash
# =============================================================================
# step2_bundle_grep.sh
#
# Purpose:
#   Fetch site HTML + linked JS and grep for Solana program ids / pubkeys.
#
# Usage:
#   step2_bundle_grep.sh <WEBSITE_URL>
# =============================================================================
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: step2_bundle_grep.sh <WEBSITE_URL>

Fetch HTML + script assets and grep for base58-like pubkeys and config keys.

Exit: 0 HTML fetched (hits optional); 1 fetch failed; 2 usage
EOF
  exit 2
}

if [[ $# -eq 1 && ( "$1" == "-h" || "$1" == "--help" ) ]]; then usage; fi
[[ $# -eq 1 ]] || usage
URL="$1"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "== STEP 2B: bundle grep =="
echo "URL: $URL"

if ! command -v curl >/dev/null 2>&1; then
  echo "GATE: FAIL - curl required" >&2
  exit 1
fi

set +e
html=$(curl -sSL --max-time 30 "$URL" 2>"$TMP/err")
rc=$?
set -e
if [[ $rc -ne 0 || -z "$html" ]]; then
  echo "GATE: FAIL - could not fetch HTML: $(cat "$TMP/err" 2>/dev/null)" >&2
  exit 1
fi
printf '%s' "$html" >"$TMP/index.html"
echo "Fetched HTML bytes: $(wc -c <"$TMP/index.html")"

# Collect script srcs (relative + absolute)
mapfile -t SCRIPTS < <(grep -oE 'src="[^"]+\.js[^"]*"' "$TMP/index.html" | sed 's/src="//;s/"$//' | head -40 || true)

fetch_one() {
  local src="$1"
  local out="$2"
  local full="$src"
  if [[ "$src" == //* ]]; then full="https:$src"; fi
  if [[ "$src" == /* ]]; then
    # origin + path
    local origin
    origin=$(printf '%s' "$URL" | sed -E 's|(https?://[^/]+).*|\1|')
    full="$origin$src"
  elif [[ "$src" != http* ]]; then
    local base
    base=$(printf '%s' "$URL" | sed -E 's|/[^/]*$|/|')
    full="$base$src"
  fi
  curl -sSL --max-time 30 "$full" -o "$out" 2>/dev/null || true
}

n=0
for s in "${SCRIPTS[@]:-}"; do
  [[ -z "$s" ]] && continue
  n=$((n + 1))
  fetch_one "$s" "$TMP/asset_$n.js"
done
# Also scan inline HTML
cp "$TMP/index.html" "$TMP/asset_0.js"

echo "-- matches (programId / pubkey-ish / common keys) --"
# Base58-ish 32-44 chars; filter obvious noise lightly
grep -RhoE '(programId|program_id|PROGRAM_ID|PROGRAM|IDL|idl|bondingCurve|vault|config)["'\'']?\s*[:=]\s*["'\''][1-9A-HJ-NP-Za-km-z]{32,44}["'\'']' "$TMP"/asset_*.js 2>/dev/null | sort -u | head -80 || true
grep -RhoE '["'\''][1-9A-HJ-NP-Za-km-z]{32,44}["'\'']' "$TMP"/asset_*.js 2>/dev/null \
  | tr -d "\"'" \
  | grep -E '^[1-9A-HJ-NP-Za-km-z]{32,44}$' \
  | sort -u \
  | head -80 || true

hits=$(grep -RhoE '[1-9A-HJ-NP-Za-km-z]{32,44}' "$TMP"/asset_*.js 2>/dev/null | wc -l | tr -d ' ')
if [[ "${hits:-0}" -eq 0 ]]; then
  echo "GATE: WARN - no base58-like hits. Try browser network tab or docs."
else
  echo "GATE: OK - saw ~$hits base58-like tokens (triage manually; many are noise)."
fi
exit 0
