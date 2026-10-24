## 2026-10-24

- Step 11: explicitly hunt unauthenticated server/API/database access (writes, IDOR, open Firebase/Supabase/GraphQL) as a primary frontend objective, not only leaked keys.

# Changelog

## [v0.3.0] - 2026-10-16

### Added

- **STEP 3.5 - Closed-source decompilation.** When no source is available, recover
  Rust that recompiles to the on-chain binary (or high-fidelity equivalent).
  Based on the OtterSec GoonFi V2 methodology (Oct 2026): function-by-function
  recovery, deterministic instruction scoring against recompilation, architect +
  worker agents, judge that only merges score improvements with no cheating
  constructs, and final global fixes (function order, panic locations). Tooling
  pointers: Binary Ninja + bn-ebpf-solana, patina-research style pipeline, sbpf
  disassembler, matching Solana platform-tools. New optional prep helper
  referenced in the tools table. Operating rule 12 and the Step 3 gate now
  direct closed-source paths here. Description frontmatter mentions the
  capability.

### Changed

- Step 3 "No source" gate now routes to Step 3.5 before falling back to IDL /
  transaction analysis.

## [v0.2.0] - 2026-10-12

### Added

- **Operating rule 13, chain leads to a Critical.** Hunt and keep a Low, Medium,
  or High when it is a usable step toward unauthenticated theft, a freeze, or
  unbounded loss. Record it at its honest severity, name the missing piece, try
  the chain before closing the path, and report every confirmed Low, Medium, and
  High at that severity (sim/bankstest PoC = chain severity). Pointers in Steps
  6.5, 8, the Step 9 findings table (`chain-to-critical` column), Appendix B
  prompt 15, and Appendix C. Description frontmatter mentions the same rule.
- **Operating rule 12, overcome blockers proactively.** Install/use decompilers,
  explorers, RPC providers, APIs, or scripts instead of stopping at "no source"
  or "tool not installed".
- **Step 10A official contacts (mandatory):** hunt the real security inbox from
  official docs / SECURITY.md / security.txt / bounty platform / verified org X
  before any DM. Write `reports/contacts.md` with URL + exact quote. New
  `tools/step10_contact_hunt.sh` fetches pages, extracts emails/bounty links/
  quotes, and decodes Cloudflare `data-cfemail`. INTAKE fields `SECURITY_EMAIL`
  and `DISCLOSURE`.
- **Step 11 Frontend Security Audit (always check):** scan the web bundle for
  exposed API keys, bearer tokens, leaked keypairs, RPC/relayer keys, Solana
  pubkeys, DB strings, and localStorage leakage; financial-impact calc for
  relayer/fee-sponsorship keys; responsible read-only testing (never sign with a
  leaked keypair); report template; coverage update. Inline
  `tools/step11_frontend_security.sh` scanner and operating rules 14-16.
- Severity placeholders in Step 9 now span `Low/Medium/High/Critical`.

### Changed

- Report/DM researcher identity points to the security-research repo.

## [v0.1.1] - 2026-08-11

### Changed

- README and companion wording are agent-agnostic (any coding agent or human),
  not tied to a single host product or install path.

## [v0.1.0] - 2026-08-11

### Added

- Initial Solana / Anchor / native Rust bug-hunt playbook modeled on the EVM
  `iykes-web3-bughunt-skill` structure (INTAKE, Steps 1-10, coverage, disclosure).
- Bug classes distilled from public Solana audit report corpus: premature PDA
  close, ATA init grief, unconstrained fee wallets, PDA seed collisions,
  migration frontrun, Token-2022 insolvency, oracle feed checks, keeper grief,
  push-payment locks, pause/blacklist bypass, type cosplay, CPI program pinning,
  rent refund mistakes, bridge/message bounds, share/exchange-rate inflation.
- Product-type deep dives: launchpad/bonding-curve, AMM, vault/LST, lending,
  perps, OTC/escrow, bridge/OFT, staking/governance.
- Mechanical tools: ground truth RPC, bundle grep, program/account surface map,
  auth triage greps, PoC scaffold (anchor/native), report + DM skeletons, selftest.
- Mandatory `coverage.md` tracking and honest low-coverage gate.
- Operating rules: simulator-only verification, honest severity, private
  disclosure, no extortion, token-conservative model routing.
