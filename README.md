# Iyke's Solana Bughunt Skill

End-to-end **Solana / Anchor / native Rust** bug-hunting playbook for turning a
real finding into a responsible, paid disclosure.

- Researcher: **deviykee**
- Companion (EVM): [iykes-web3-bughunt-skill](https://github.com/devIykee/iykes-web3-bughunt-skill)

## Install (Grok / agent skills)

```bash
# User-scoped skill
git clone git@github.com:devIykee/iykes-solana-bughunt-skill.git \
  ~/.grok/skills/iykes-solana-bughunt-skill

chmod +x ~/.grok/skills/iykes-solana-bughunt-skill/tools/*.sh
chmod +x ~/.grok/skills/iykes-solana-bughunt-skill/tools/*.py
```

Or copy this directory into `~/.grok/skills/iykes-solana-bughunt-skill`.

## Use

1. Fill the **INTAKE** block in `SKILL.md`.
2. Run Steps 1-10 top to bottom. Prefer `tools/*` for mechanical work.
3. Maintain `coverage.md` while reading programs.
4. Prove findings in a **local simulator only**. Never exploit mainnet.
5. Disclose privately (Step 10). No threats. Honest severity.

```bash
./tools/selftest.sh
./tools/step1_ground_truth.sh "https://api.mainnet-beta.solana.com"
./tools/step4_auth_triage.sh /path/to/programs
./tools/step7_poc_scaffold.sh ./poc anchor
```

## Layout

```
SKILL.md           # playbook (source of truth)
tools/             # mechanical scripts
CHANGELOG.md
README.md
```

## Rules (short)

- Simulator / bankstest / read-only only
- Honest severity with explicit bounds
- Kill your own finding if it does not hold
- Private until patched
- Track coverage; never imply a full audit when Z% is low
