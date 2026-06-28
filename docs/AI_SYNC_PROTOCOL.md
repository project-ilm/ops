<!-- context: https://ilm.codes/context/ -->
# ILM Multi-AI Sync & Convergence Protocol

**Audience:** ChatGPT (system setup, `~/work` management, org-wide repo orchestration).
**Pairs with:** `ops/docs/AI_ONBOARDING.md`, `ops/docs/HANDOFF.md`, `ops/docs/WORKFLOW.md`,
and the canonical context at `https://ilm.codes/context/` (REBUILD.md + state.json).
**Save as:** `ops/docs/AI_SYNC_PROTOCOL.md`, commit, reference from REBUILD.md §B.
**Author of this handoff:** Claude (Opus) session, 2026-06-27. © 1993–2026 Abhishek Choudhary.

---

## 0. Cold-start — read these before doing anything

In order, every session, no exceptions:

1. `https://ilm.codes/context/REBUILD.md`  — the consolidated context map (authoritative prose).
2. `https://ilm.codes/context/state.json` + `https://ilm.codes/status.json` — machine mirror.
3. `ops/queue.txt`, `ops/LOCAL_TASKS.md`, `ops/ilmd.status` — the live task ledger + daemon state.
4. `/mnt/transcripts/journal.txt` then the dated transcript bodies — session history.

If any of (1)–(3) disagree, **REBUILD.md wins for intent; the registries/code win for facts.**
Never trust state.json over measured reality (see §5 — it is currently stale).

---

## 1. Roles — who owns what (avoid collisions)

This is a division of *surface area*, not authority. One human (Abhishek) runs every script;
the AIs do not act autonomously. The split exists so two assistants don't redo or undo each other.

| Surface | Owner | Examples |
|---|---|---|
| Host / OS / toolchains | **ChatGPT** | `install_*.sh`, ASUS/Ubuntu stack, multiarch, containers, Docker storage |
| `~/work` filesystem hygiene | **ChatGPT** | dedup, archive, `.gitignore`, removing stale previews/venvs/`__pycache__` |
| Org-wide repo normalization | **ChatGPT** | the foundry seeder, CI scaffolds, per-repo bootstrap/validate/benchmark |
| Automation / daemons | **ChatGPT** | `ilmd` task runner, scheduled regen of state.json |
| Deep audit & verification-by-fetch | **Claude (Opus)** | this protocol, the context-rebuild verifier, correctness issues |
| Kernel / specs / reference impl | **Claude (Opus)** | Romenagri kernel review, langspec, HindiC++ spec, formal proofs |
| Targeted correctness issues | **Claude (Opus)** | the 8 specific defect issues filed 2026-06-27 |
| The shared ledger | **both** | `ops/queue.txt` is the single coordination point |

Funding-model corollary (REBUILD.md §G.6): **Opus for kernel/specs/refimpl; ChatGPT + Sonnet/Haiku
for the ~80% automatable batch.** Don't put the breadth-first model on kernel mappings, and don't
put the depth model on bulk boilerplate.

---

## 2. Single source of truth — the ops ledger

Do **not** invent new coordination files. The sync primitives already exist in `ops/`:

- `ops/queue.txt`        — the task queue (the lock). One task per line.
- `ops/LOCAL_TASKS.md`   — human-readable backlog / notes.
- `ops/ilmd.status`      — what the daemon is currently executing.
- `ops/doi_map.json`     — minted DOIs (append-only; never rewrite history).
- `state.json` / `REBUILD.md` — the convergence beacon + intent.

**Ledger line format** (adopt this in `ops/queue.txt`):

```
[STATUS] owner=<claude|chatgpt|gemini|human> claimed=<UTC-ISO> task="<short>" pr=<url|->
# STATUS ∈ TODO | CLAIMED | PR-OPEN | MERGED | BLOCKED
```

**Claiming rule:** before working a task, set it `CLAIMED owner=<you> claimed=<now>`. If it is
already `CLAIMED` by someone else and < 24h old, pick a different task. This is enough mutual
exclusion for a single-operator, async-AI setup.

---

## 3. The sync↔work loop (the convergence cycle)

Every unit of work, regardless of which AI, follows the same six beats:

```
READ    → load §0 context; pull latest on all repos.
CLAIM   → mark one ops/queue.txt line CLAIMED owner=<you>.
WORK    → auditable `cat > file <<'EOF' … EOF` script committed to ops (rule B.1).
          Verify by EXECUTION. Honest figures. Flag, don't fake.
PR      → fork → fix → PR → review → merge. PRs LOUD: print the URL, never swallow `gh`.
UPDATE  → regenerate state.json/status.json from MEASURED reality; append to REBUILD.md §E/§F.
RELEASE → set the ops/queue.txt line MERGED pr=<url>. Pick next.
```

The loop is closed only when **UPDATE** runs. A merge that doesn't refresh state.json leaves the
beacon lying — which is exactly today's drift (§5). No exceptions: every merge regenerates state.

---

## 4. Non-negotiable guardrails

Carried from REBUILD.md §B, with additions surfaced by today's runs. Violating any of these
breaks convergence or trust:

1. **Never touch the fixed kernel mappings by regeneration.** The Hindawi lexers ARE the mapping
   (`chintamani/Hindawi/<dir>/{<host>2h.uhin, h2<host>.uhin}`). Read them; never synthesize thin
   tables. The foundry "normalize everything" pass must skip kernel table generation entirely.
2. **The three-axis architecture (Script / Language / Standard) is never collapsed.** Counts
   (currently 74 scripts, 58 languages) are *measured state*, not ceilings.
3. **Invariant: N tables + 1 fixed kernel, never N².** The kernel never changes.
4. **No irreversible step without explicit human confirmation:** DOI minting, deletions,
   force-push, history rewrite, mass-close of issues. Confirm inputs first.
5. **Tokens by path only** (`ops/.zenodo_token`). The previously-leaked Zenodo token must be
   **rotated** — track it. `dump_state.sh` must keep refusing to snapshot secret-like content.
6. **All artifacts under `~/work`.** Logs go to a known `~/work` path
   (suggest `~/work/logs/<tool>.<UTC>.log`), **never `/tmp`**. (Operator called this out explicitly.)
7. **Verify by execution; honest figures; flag don't fake.** Every generated file carries the
   `<!-- context: https://ilm.codes/context/ -->` header.

---

## 5. Immediate actions for ChatGPT (from the 2026-06-27 runs)

Concrete, do-now items the verifier + PR query exposed:

1. **Regenerate the stale machine mirror.** `status.json` is `mtime 2026-06-15`, field
   `"updated":"2026-06-14"` — two weeks behind `REBUILD.md` (`mtime 2026-06-27`, PR#7). Same for
   `/context/state.json`. Build a generator that derives both from `registry/*.tsv` + measured
   results, and a **drift-guard CI/pre-commit check that fails if REBUILD.md is newer than
   status.json.** (This is Claude-filed issue `ilm.codes#9` — automation is your surface.)

2. **Scope the foundry seeder — it is currently too broad.** It runs `gh repo list --limit 1000`
   and files 9 generic engineering issues on *every* repo, including:
   - `romenagri` (the **kernel** — special review rules; generic "Containers/Bootstrap" boilerplate
     is wrong there),
   - `chintamani` (frozen 2003–04 **lineage** — do not normalize),
   - `cognitive-fabric` and other **non-ILM** repos (the avatar/TTS stack — out of the convergence core).

   Add an **exclude-list** (`romenagri chintamani legacy cognitive-fabric foundry`) and a
   **per-repo applicability gate** (only seed bootstrap/containers where the repo actually builds
   something). Otherwise the trackers drown and the real defects get buried.

3. **De-duplicate against Claude's 8 specific issues** before/while seeding. Where a generic
   "Engineering: Documentation" overlaps a specific defect (e.g. the corrupted hi/ur/fa specs,
   `language-specs#4`), cross-reference rather than file a parallel ticket. Convention: generic
   normalization issues link to the specific correctness issue, not vice-versa.

4. **Standardize labels across both streams.** Both seeders create a `documentation` label with
   different colors via `--force` (last-write-wins). Pick one palette in `ops/docs/` and have both
   scripts read it, so labels stop flapping.

5. **Close the §G correction threads as PRs land** — don't let REBUILD.md §G accumulate. Each §G
   item should map to exactly one tracked issue (Claude filed §G.1 as `language-specs#5`).

---

## 6. Convergence definition (measurable "done")

The system has **converged** (the completion Abhishek is driving toward) when *all* hold, checkable
by re-running `check_ilm_context.sh`:

- [ ] `state.json` / `status.json` == measured reality (drift-guard CI green; UPDATE beat enforced).
- [ ] Registry counts reconcile: `scripts.tsv` seeded == status.json (74/74 ✓ today);
      `languages.tsv` seeded == status.json (58 ✓ today). Keep them equal as they grow.
- [ ] Every **ILM-core** repo passes its own bootstrap + validation (foundry issues resolved,
      scoped to applicable repos).
- [ ] All REBUILD.md §G correction threads closed (issues merged).
- [ ] The cold-start test passes: a fresh AI given only `ilm.codes/context/` + `VALIDATION_PROMPT.md`
      can rebuild full working context and resume — verified, not assumed.
- [ ] Context-handoff pages degrade without JS (Claude-filed `ilm.codes#8`, `#10`) so *any* agent,
      not just JS browsers, can pick up.

Convergence is a property of the **beacon matching reality**, not of any one repo. The loop (§3)
is the mechanism; state.json is the gauge.

---

## 7. Issue taxonomy (so the two streams never collide)

- **Specific / correctness** (Claude): a named defect, a verified inconsistency, a kernel/spec
  concern. Labels: `bug`, `consistency`, `governance`, `context-handoff`, `correction`, `seo`.
- **Generic / normalization** (ChatGPT foundry): repo hygiene scaffolding. Labels: `engineering`,
  `bootstrap`, `containers`, `validation`, `benchmark`, `documentation`, `inventory`, `recovery`,
  `automation`, `technical-debt`.

Rule: **generic issues reference specific ones**, scoped only to repos that need them. A repo's
correctness issues are blockers; its normalization issues are hygiene. Don't file hygiene on the
kernel or the lineage.

---

## Handshake for the next AI session (paste-ready)

> Read `ilm.codes/context/REBUILD.md` + `state.json` + `ops/queue.txt` + this protocol. Pull all
> repos. Claim one `TODO` line in `ops/queue.txt` (set CLAIMED owner=<you>). Do it via an auditable
> `cat > file` script committed to `ops`, verify by execution, open a LOUD PR, merge, then
> regenerate `state.json`/`status.json` from measured reality and append to REBUILD.md §E/§F.
> Set the queue line MERGED. Never touch the fixed kernel by regeneration; tokens by path only;
> all artifacts under `~/work`, logs never in `/tmp`. Stop and ask before any irreversible step.
