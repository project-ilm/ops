<!-- context: https://ilm.codes/context/ -->
# Foundry Specification v1 — Design Review + ILM Launchpad Sequence

**From:** Claude (Opus), 2026-06-27 — correctness/spec surface.
**Re:** ChatGPT's "normalize operations, not repositories" proposal.
**Verdict:** Adopt the core. Apply the four corrections below first. Then run the gated launchpad sequence.
**Save as:** `ops/docs/FOUNDRY_SPEC_AND_LAUNCHPAD.md`. © 1993–2026 Abhishek Choudhary.

---

## 0. The three layers (Foundry is one of them, not the whole thing)

| Layer | Artifact | Governs |
|---|---|---|
| Coordination | `AI_SYNC_PROTOCOL.md` | *how* agents claim/work/merge (process) |
| Repo shape | **Foundry Spec v1** (this) | *what shape* each repo converges to |
| Truth/beacon | `state.json` + per-repo `STATE/` | *what is actually true* (the gauge) |

They compose. Foundry's per-repo `STATE/` is the decentralized version of `ilm.codes/context/`.

---

## 1. THE key correction — conformance profiles by repo class

A single uniform contract is wrong. The required surface derives from a declared **class**.
Every repo sets `foundry.class` in `MANIFEST.yaml`; the validator checks against that class only.

| Class | Required surface | Examples | Rule |
|---|---|---|---|
| **core** | Full contract: operational interface, `STATE/`, CI, AGENTS.md, MANIFEST, CAPABILITIES, docs set | `romenagri`*, `ilm.codes`, `language-specs`, `ops`, `vscode-ilm`, `misty-doi` | full convergence |
| **library** | README, LICENSE, CITATION, MANIFEST, CAPABILITIES, `validate.sh` — lighter CI, no full bootstrap if header-only | binding/table repos, keyword packs | proportionate |
| **archival** | Metadata + `NOTICE` (points to canonical successor) + Wayback snapshot + DOI. **NO operational interface. NO refactor.** | `chintamani` (2003–04 lineage), SourceForge-era repos, award-evidence repos | **frozen = evidentiary** |
| **out-of-scope** | Own track; not ILM convergence core | `cognitive-fabric`, avatar/TTS, health/legal repos | excluded from Foundry epics |

\* **`romenagri` is `core` but special:** its `validate.sh` runs the reversibility invariant
(98.68% kernel postguard), NOT generic smoke tests. Auto-generated boilerplate must never touch
the fixed Hindawi mappings (rule B.5 — the lexers ARE the mapping).

**Why this is non-negotiable:** forcing CI/containers/CONTRIBUTING onto a frozen 2003–04 repo
destroys the provenance value you are about to publish. Archival repos are normalized *only* by
adding metadata + a successor pointer + a DOI — never by editing their contents.

---

## 2. Foundry must ship with a conformance validator (or it's a wish)

A spec with no test is aspirational. The artifact that makes "compliant" real:

```
foundry-validate <repo>
  → reads MANIFEST.yaml (foundry.class, foundry.version)
  → checks the required surface for that class
  → emits: compliance score, missing items, a badge (foundry: core 9/9)
```

Ship it as a reusable **GitHub Action** every repo's CI runs. Without an enforcement gate,
"Foundry-compliant" rots exactly like `status.json` drifted two weeks behind reality. The validator
IS the difference between a standard and a slogan (cf. SPDX has a linter; REUSE has `reuse lint`).

---

## 3. Single-source context — thin AI overlays

`AGENTS.md` is **canonical** (one file, the instructions). `CLAUDE.md` / `CODEX.md` / `GEMINI.md`
are **thin overlays**: "read AGENTS.md, plus these tool-specific notes." Never parallel copies —
four diverging context files × N repos is a drift explosion, the exact thing the beacon prevents.

Same for `TERMINOLOGY.md` (semantic-drift guard) and `ARCHITECTURE.md` (ontology-drift guard):
canonical content lives once per repo; the ecosystem-wide canonical lives at `ilm.codes/context/`
and repos *reference* it rather than fork it.

---

## 4. MANIFEST.yaml / CAPABILITIES.yaml (schema sketch)

```yaml
# MANIFEST.yaml — machine-readable repo identity
foundry: { version: 1, class: core }        # class drives required surface
id: project-ilm/romenagri
canonical_successor: null                    # archival repos point forward
provenance: { since: 1993, dois: [10.5281/zenodo.20695751] }
operational_interface: [bootstrap, validate, benchmark, doctor, status, inventory]
state_dir: STATE/
```

```yaml
# CAPABILITIES.yaml — what the repo CAN DO (not what it needs)
capabilities:
  - transliterate: { scripts: 74, reversible: true }
  - compile: { hosts: [c, cpp, basic, lex, yacc, asm, java, python] }
```

CAPABILITIES (not dependencies) is the sharp insight — it's the per-repo analog of `state.json`:
it lets any agent answer "what can this repo do?" without reading the code.

---

## 5. Issue model — one epic, profiled subtasks

Replace the 9 flat issues with **one `Foundry Compliance` epic per repo**, subtasks gated by class:

```
EPIC: Foundry Compliance (class: core)
  ├─ Metadata (MANIFEST, CAPABILITIES, CITATION)      [all classes]
  ├─ Docs set (README..SECURITY, ARCHITECTURE, TERMINOLOGY, FAILURE_MODES, RECOVERY)
  ├─ STATE/ (CURRENT, NEXT, KNOWN_ISSUES, ROADMAP)
  ├─ Operational interface (bootstrap/validate/benchmark/doctor/status/inventory)
  ├─ AI context (AGENTS canonical + thin overlays)
  ├─ CI (incl. foundry-validate action)
  └─ Containers / Bootstrap                            [core/library only]
```

Archival repos get a 1-subtask epic: **Archive + DOI + successor-NOTICE.** Nothing else.
Generic subtasks reference the specific correctness issues Claude filed (don't duplicate them).

---

## 6. The launchpad sequence — gated, two steps irreversible

Your four goals are a dependency chain, not parallel work. Order matters for **reputation**, not
just engineering — pointing your professional/academic audience at non-conformant repos backfires.

```
1. CLASSIFY          (cheap, reversible)
   Tag every repo across every org with foundry.class. Extend the existing chatgpt inventory
   into a registry. Output: which repos are core / library / archival / out-of-scope.

2. ARCHIVE + DOI     ⚠ IRREVERSIBLE — HUMAN GATE
   For the archival set (SourceForge-era, lineage, evidence):
     • Wayback "Save Page Now" snapshot (permanent)
     • mint DOI via misty-doi (v1.0.1) → record in ops/doi_map.json
     • add NOTICE pointing to the canonical successor repo
   Confirm every input before minting. A DOI is forever. Do NOT batch-mint unreviewed.

3. CONFORM CORE      (reversible, PR-gated)
   Bring the ~6–8 core repos to full Foundry conformance via the sync loop.
   One Foundry Compliance epic each. foundry-validate green before a repo is "done".

4. CROSS-LINK        (reversible)
   Wire the graph: repo→repo (related/successor), repo→ecosystem-site (ilm.codes),
   site→repos. Bidirectional. This is what turns a pile of repos into an ecosystem.

5. PUBLISH + LINKEDIN   ⚠ SEMI-IRREVERSIBLE — REPUTATIONAL GATE
   Only after (3) core repos are clean AND (2) archival repos are DOI'd.
   Provenance dossier + LinkedIn posts point at the stabilized graph + DOIs.
   Gate: never point the public audience at a non-conformant core repo.

6. ILM LAUNCH
   The stable launchpad exists once 1–5 hold and the cold-start test passes ecosystem-wide
   (a fresh AI, given only ilm.codes/context/ + a repo's STATE/, can resume).
```

**The credibility logic:** archived historical work (Wayback) + permanent identifiers (DOIs) +
clean core repos + a cross-linked graph = verifiable provenance. *That* is the launchpad foundation
— the dossier ties old-work→DOI→public-link→LinkedIn into one inspectable whole. Skipping (2)/(3)
to rush (5) is the one sequencing error that costs reputation rather than time.

---

## 7. Division of next work

- **ChatGPT (breadth/infra):** draft Foundry Spec v1 text; build `foundry-validate` + the GH Action;
  the per-repo bootstrap/template generators; run CLASSIFY (step 1); scaffold core-repo conformance.
- **Claude (depth/correctness):** review the spec text (esp. the class profiles + kernel exception);
  own romenagri's reversibility `validate.sh`; gate the ARCHIVE+DOI step (step 2) inputs before any
  mint; verify the cold-start test (step 6).
- **Both:** every change flows through the AI_SYNC_PROTOCOL loop; one Foundry Compliance epic per repo;
  state.json/STATE/ regenerated on every merge.

---

## Handshake line

> Foundry v1 = a repo *specification* with **conformance profiles by class** (core/library/archival/
> out-of-scope) and a machine `foundry-validate` gate. Archival repos are frozen — metadata + DOI +
> successor-NOTICE only, never refactored. AGENTS.md canonical; AI files are thin overlays. Launchpad
> is gated: classify → (⚠ archive+DOI) → conform core → cross-link → (⚠ publish+LinkedIn) → launch.
> Two steps irreversible; both human-gated. All via the sync loop; one Foundry epic per repo.
