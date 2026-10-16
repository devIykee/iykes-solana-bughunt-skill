#!/usr/bin/env bash
# STEP 3.5 prep: dump a Solana program and basic metadata for decompilation.
# Usage: step3_5_decompile_prep.sh <RPC_URL> <PROGRAM_ID> [SLOT] [OUT_DIR]
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <RPC_URL> <PROGRAM_ID> [SLOT] [OUT_DIR]" >&2
  exit 2
fi

RPC="$1"
PROGRAM_ID="$2"
SLOT="${3:-}"
OUT_DIR="${4:-hunt-dir}"

mkdir -p "$OUT_DIR"
OUT_SO="$OUT_DIR/program.so"

echo "=== Dumping program $PROGRAM_ID from $RPC ==="
if [[ -n "$SLOT" ]]; then
  solana program dump "$PROGRAM_ID" --url "$RPC" --slot "$SLOT" "$OUT_SO" || {
    echo "Dump failed (slot $SLOT). Try without --slot or check RPC." >&2
    exit 1
  }
else
  solana program dump "$PROGRAM_ID" --url "$RPC" "$OUT_SO" || {
    echo "Dump failed. Check RPC and program id." >&2
    exit 1
  }
fi

echo
echo "=== File metadata ==="
file "$OUT_SO" || true
ls -la "$OUT_SO"
sha256sum "$OUT_SO" || shasum -a 256 "$OUT_SO" || true

echo
echo "=== ELF sections (if readelf available) ==="
readelf -S "$OUT_SO" 2>/dev/null | head -40 || echo "readelf not available"

echo
echo "=== Interesting strings (first 80) ==="
strings "$OUT_SO" | head -80 || true

echo
echo "=== Next ==="
echo "Binary: $OUT_SO"
echo "Proceed with STEP 3.5 in SKILL.md:"
echo "  - Binary Ninja + bn-ebpf-solana (or equivalent) for function map"
echo "  - Function-by-function Rust recovery scored against recompilation"
echo "  - Matching Solana platform-tools for byte-identical rebuild"
echo "Document recovered functions in coverage.md."
exit 0
