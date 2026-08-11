#!/usr/bin/env python3
# =============================================================================
# step9_report_skeleton.py
#
# Purpose:
#   Fill the Step 9 report markdown skeleton from INTAKE + severity fields.
#   Mechanical only - does not judge severity or invent root cause.
# =============================================================================
"""STEP 9 - Fill the Solana report markdown skeleton."""
from __future__ import annotations

import argparse
import sys
from pathlib import Path


def main() -> int:
    p = argparse.ArgumentParser(
        description="Fill Step 9 Solana report skeleton (researcher: deviykee).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("--project", required=True)
    p.add_argument("--severity", required=True)
    p.add_argument("--title", required=True)
    p.add_argument("--cluster", default="mainnet-beta")
    p.add_argument("--program", default="", help="Core program id")
    p.add_argument("--program-role", default="core program")
    p.add_argument("--bound", default="")
    p.add_argument("--rpc", default="<RPC>")
    p.add_argument("--root-cause", default="<exact code quoted: constraints, seeds, CPI>")
    p.add_argument(
        "--plain",
        default=(
            "<Explain the danger for non-technical readers: what users thought was safe, what "
            "can go wrong, who loses money, that no admin key is needed if that is true, and "
            "what the bound is. Use a simple analogy if helpful. No em dashes.>"
        ),
    )
    p.add_argument("--summary", default="<the one wrong assumption, plain language>")
    p.add_argument("--attack", default="1. ... 2. ... 3. ...")
    p.add_argument(
        "--impact",
        default="Auth: none | Capital: <flash/zero> | Frequency: <once/every cycle> | Victims: <who> | Magnitude: <number/%>",
    )
    p.add_argument("--poc-result", default="<result: attacker gained X / Y locked>")
    p.add_argument("--fix", default="<one or more concrete options>")
    p.add_argument("-o", "--output", default="-")
    args = p.parse_args()

    sev_line = args.severity
    if args.bound:
        sev_line = f"{args.severity} - {args.bound}"

    prog_row = (
        f"| {args.program_role} | {args.program} |"
        if args.program
        else "| <core program> | <ProgramId> |"
    )

    body = f"""# {args.project} - {args.severity}: {args.title}
**Researcher:** deviykee
**Severity:** {sev_line}
**Status:** Verified in local simulator / Anchor test. No mainnet state touched.
**Disclosure:** Private. Live-exploitable now.  <!-- if applicable -->

## What this means in plain language (read this first)
{args.plain}

## Affected programs ({args.cluster})
| Role | Program ID / Account |
|---|---|
{prog_row}

## Summary
{args.summary}

## Root cause
{args.root_cause}

## Attack
{args.attack}

## Impact
{args.impact}

## Proof of concept
`anchor test` / `cargo test` in `poc/`  -> {args.poc_result}

## Fix
{args.fix}

## Disclosure & compensation
Good-faith private disclosure. I'd appreciate a bounty commensurate with a
{args.severity}. I am NOT conditioning the disclosure or fix on payment act on it now.
Happy to walk the team through it and review the fix.
deviykee
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
