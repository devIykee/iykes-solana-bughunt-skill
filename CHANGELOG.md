# Changelog

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
