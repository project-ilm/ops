# Contextual Contracts

Co-developers on this programme — humans and several AIs (Claude, ChatGPT,
Gemini) — **do not share a filesystem, an environment, or a session.** Every
prior breakage (a script that checked for files instead of writing them; a
`/tmp` artifact that vanished; a `pip install` that worked in one environment
and failed under PEP 668 in another; a "publish" that assumed the author held
the token) traces to an unstated assumption of shared context. These contracts
make those assumptions explicit so any party can act without the others present.

This extends `AI_SYNC_PROTOCOL.md` (the read→claim→work→PR→update→release loop)
and `FOUNDRY_SPEC_AND_LAUNCHPAD.md`. Where those govern *coordination*, this
governs *what an artifact must guarantee on its own*.

---

## C1 — Self-contained artifacts (no shared filesystem)

An artifact handed to another party must reconstruct everything it needs. It
may not reference paths only the author can see.

- Text/code ships as `cat > f <<'EOF'` or base64-embedded blocks that **write**
  the files, never as "verify these exist" checks against an assumed tree.
- Binaries that cannot live in a script (images, tarballs) travel **with** the
  artifact in one downloadable unit, and the script states where it looks for
  them and what it does when they are absent.
- An artifact run in an empty directory must either fully succeed or degrade
  loudly and safely. "MISSING — refusing to proceed" against files the author
  forgot to include is a contract violation, not an error message.

## C2 — Declared environment, never assumed

The executing environment is unknown to the author. State requirements; detect,
don't presume.

- Declare interpreter and host constraints (e.g. **PEP 668 externally-managed
  Python**, version, OS). For a CLI shipping a console-script, the install
  contract is **pipx-first**, venv as the named alternative — never bare
  `pip install` into system Python.
- Detect tool presence (`command -v`) and give the exact remediation when
  absent, rather than failing opaquely.

## C3 — Credentials by path, on the executing host only

Secrets never travel in artifacts, logs, or prompts. They live only on the host
that runs the side-effecting step, supplied at run time by path or environment.

- `ZENODO_TOKEN`, GitHub auth, PyPI tokens are the operator's, on the operator's
  machine. An authoring environment (including any AI sandbox) that lacks them
  **cannot** and must not attempt the authenticated action.

## C4 — Side effects execute where the credential lives

Minting a DOI, pushing to GitHub, uploading to PyPI — these run on the host that
holds the credential, not in the environment that authored the script. The
author's job is to make that host-side step a single, verified, idempotent
command. An AI that cannot reach the target service states so plainly and hands
over the one command; it does not pretend to have published.

## C5 — Safe by default, irreversible only on explicit opt-in

Running an artifact with no flags must have **zero** side effects: reconstruct,
validate, dry-run. Every irreversible action (mint, push, delete) is a named
flag and prompts for confirmation. Re-running must be safe (idempotent).

## C6 — Canonical locations, because there is no shared FS

"It's in my working dir" means nothing to another party. State the canonical
home for every artifact: the repo and path it belongs in
(`project-ilm/<repo>/<path>`), so any party places it identically. Artifacts
write into their own clearly-named subdirectory, never into the current
directory's existing trees.

## C7 — Verify before acting; abort on mismatch

Before a mutating step, verify the precondition (anchor text present, checksum
matches, branch clean) and abort with a clear message if not — never patch
blindly. String insertions check their anchor exists exactly once first.

---

## C8 — Gated at every boundary (zero drift)

These contracts are enforced mechanically by `bin/contract_check.sh` (the FPSS
gate) and re-verified at **every** handoff — agent→agent, agent→human,
human→human. No artifact crosses an edge with a failing gate.

- The producing party runs the gate and records the PASS in the handoff/PR note.
- The receiving party re-runs it (never trusts the claim) and, if an AI, restates
  these contracts in its own words before acting — a fresh agent re-derives the
  contract rather than inheriting an assumed one.
- A secret that appears in any transcript, log, or PR is treated as compromised
  and rotated immediately; detection is assumed imperfect, so exposure ⇒ rotation.

Rationale, methods, and the failure dataset are in `PROCESS_HARDENING.md`
(FPSS objective, INCOSE ilities, FMECA, FTA, HAZOP). That document and this one
are the contract; the checker is its enforcement.

## The one-line test

> If I hand this artifact to a collaborator who shares none of my state — no
> files, no environment, no tokens, no memory of this session — does it either
> do the right thing or fail loudly and safely, with the exact next step stated?

If yes, it satisfies these contracts. If it needs anything I have and they don't
without saying so, it does not.

© 1993-2026 Abhishek Choudhary. GPL-3.0-or-later.
