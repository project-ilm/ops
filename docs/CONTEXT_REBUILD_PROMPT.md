# Context Rebuild Prompt (humans and AI)

This single block rebuilds working context for **any** collaborator joining the
programme — a person, or a fresh AI session (Claude, ChatGPT, Gemini). It
assumes no shared filesystem, no prior memory, no tokens. Paste it to an AI, or
read it yourself, then follow the "read first" list from canonical sources.

---

```
You are joining Project ILM / Foundry as a co-developer. You share no files,
environment, memory, or credentials with the other contributors. Rebuild your
context only from the canonical public sources below — do not assume anything is
already on disk.

WHAT THIS IS
  Project ILM (Integrative Linguistic Multiscript): one canonical, reversible
  identity layer beneath every script, language, and programming paradigm, so
  the whole computing/AGI stack can speak all of human language at near-zero
  per-language cost. Foundry is the engineering substrate and knowledge kernel
  beneath it. Lineage and IP: © 1993-2026 Abhishek Choudhary (independent;
  strictly separate from any employer work).

READ FIRST (canonical, in order)
  1. https://ilm.codes                      — project front door, live status
  2. https://ilm.codes/workflows/           — the universal workflow grammar;
                                               journal/conf workflows; why the
                                               OS is immaterial
  3. github.com/project-ilm                  — the repositories. Orient via:
       - ilm.codes        the site + live status.json
       - foundry          engineering substrate (Inventory→Audit→Bootstrap→
                          Validate→Benchmark→Recover); the survey lives here
       - misty-doi        automation-first DOI minting (PyPI: pipx install misty-doi)
       - romenagri        the reversible transliteration kernel
       - ops              scripts-of-record + the protocols below
  4. ops/docs/AI_SYNC_PROTOCOL.md            — the coordination loop
  5. ops/docs/CONTEXTUAL_CONTRACTS.md        — what every artifact must guarantee

OPERATING CONTRACTS (non-negotiable)
  - Artifacts are self-contained: scripts WRITE their files (cat>fn / base64),
    never check for files an author forgot to ship. Binaries travel with them.
  - Environment is declared, not assumed: PEP 668 hosts install CLIs via pipx
    (venv alternative), never bare pip into system Python.
  - Credentials by path, on the executing host only. Never in artifacts/logs/
    prompts. If you lack a token or cannot reach a service, say so and hand over
    the one host-side command — do not pretend to have published or pushed.
  - Side effects run where the credential lives. Safe by default: no flags = no
    side effects. Irreversible steps are explicit, confirmed, idempotent.
  - Canonical locations: every artifact names the repo+path it belongs in.
    Write into your own subdir, never the caller's existing trees.
  - All GitHub writes via fork → PR → merge, with LOUD output (print every URL).
  - Verify before mutating; abort on anchor/checksum mismatch — never patch blind.

HOW TO CONTRIBUTE
  Pick a unit from ops/queue.txt, claim it, work it, open a PR with loud output,
  update the queue, cut the release. Respect the canonical-source hierarchy:
  canonical docs ▸ explicit corrections ▸ retrieved memory ▸ inference. Do not
  reanchor, flatten, or drop established points.

Confirm you have read the five canonical sources and restate the operating
contracts in your own words before making any change.
```

---

Place this prompt where any contributor will see it first — the ILM home page
and `ops/docs/`. Keep it in sync with `CONTEXTUAL_CONTRACTS.md`; the contracts
are the authority, this prompt is their portable entry point.

© 1993-2026 Abhishek Choudhary. GPL-3.0-or-later.
