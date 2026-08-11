#!/usr/bin/env python3
# =============================================================================
# step10_dm_skeleton.py
#
# Purpose:
#   Fill the Step 10 first private DM template from INTAKE + report fields.
# =============================================================================
"""STEP 10 - Fill the first private DM template (Solana)."""
from __future__ import annotations

import argparse
import sys
from pathlib import Path


def main() -> int:
    p = argparse.ArgumentParser(
        description="Fill Step 10 first-DM skeleton (voice: Iyke / deviykee).",
    )
    p.add_argument("--project", required=True)
    p.add_argument("--severity", required=True)
    p.add_argument("--cluster", default="mainnet-beta")
    p.add_argument("--component", required=True)
    p.add_argument("--impact", required=True)
    p.add_argument("--scope", default="the affected programs")
    p.add_argument(
        "--poc-note",
        default="",
        help="Optional clause after 'on-chain', e.g. ', with 2 working PoCs'",
    )
    p.add_argument("-o", "--output", default="-")
    args = p.parse_args()

    poc_extra = args.poc_note or ""
    body = f"""Hey {args.project}.

I'm Iyke, a security researcher. (http://x.com/deviykee)

I've found and verified a {args.severity} vulnerability in {args.project}'s {args.component} on Solana ({args.cluster}) that {args.impact}. It's live-exploitable right now on {args.scope}, so it's time-sensitive.

I reproduced it in a local Anchor / program-test PoC, nothing was touched on-chain{poc_extra}.

I want to share the full private write-up with whoever owns the programs.

Who's the right person, or who do I talk to on the team?
"""

    if args.output == "-":
        sys.stdout.write(body)
    else:
        out = Path(args.output)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(body, encoding="utf-8")
        print(f"Wrote {out}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
