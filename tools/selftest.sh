#!/usr/bin/env bash
# Smoke-check tools: --help / usage exits without hanging.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

fail=0
check() {
  local name="$1"; shift
  set +e
  out=$("$@" 2>&1)
  rc=$?
  set -e
  # usage should be 2; some may be 0 with help text
  if [[ $rc -eq 2 || $rc -eq 0 ]]; then
    echo "OK  $name (exit $rc)"
  else
    echo "FAIL $name (exit $rc): $out" >&2
    fail=1
  fi
}

check step1 ./step1_ground_truth.sh --help
check step2 ./step2_bundle_grep.sh --help
check step3p ./step3_surface_map.sh --help
check step3a ./step3_account_map.sh --help
check step4 ./step4_auth_triage.sh --help
check step7 ./step7_poc_scaffold.sh --help
check step9 python3 ./step9_report_skeleton.py --help
check step10 python3 ./step10_dm_skeleton.py --help

# filler dry-run
python3 ./step9_report_skeleton.py \
  --project t --severity High --title "test" --cluster mainnet-beta >/dev/null
python3 ./step10_dm_skeleton.py \
  --project t --severity High --component "x" --impact "y" >/dev/null
echo "OK  fillers dry-run"

# scaffold into temp
TMP=$(mktemp -d)
./step7_poc_scaffold.sh "$TMP/poc" anchor >/dev/null
./step7_poc_scaffold.sh "$TMP/poc2" native >/dev/null
rm -rf "$TMP"
echo "OK  step7 scaffold"

if [[ $fail -ne 0 ]]; then
  echo "SELFTEST FAILED" >&2
  exit 1
fi
echo "SELFTEST PASSED"
exit 0
