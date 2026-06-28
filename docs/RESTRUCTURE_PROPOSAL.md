# Repository Restructuring & Convergence Proposal

A proposal, not a prescription. It converges two overlapping orgs
(`project-ilm`, `ayeai` + sub-orgs) into a legible structure, names the dedup
candidates, and sequences the moves so nothing public happens before an SPI
sweep. Items I could not confirm are marked **[confirm]** rather than guessed —
that is the FPSS discipline, not hedging.

Hard constraints carried throughout: independent IP stays strictly separate from
any employer work; **archive, never delete**; no public move before
`pre_announce_scan.sh` returns PASS; every transfer via the gated flow.

---

## 1. Current state (from the live inventory)

Two orgs grew in parallel and now overlap:

- **`project-ilm`** — the newer, ILM-focused home. The clean `ilm-*` layer stack
  (phonology→interface), the tooling (`misty-doi`, `spi-scan`, `ops`, `foundry`,
  `ai-scratch`), `romenagri`, `cognitive-fabric`, plus site repos.
- **`ayeai`** (+ `ayepy`, `ayegames`, `ayerunner`, `ayevdi`) — the older, broader
  home: products (`ayeam`, `opssi`, `athena`/GSF VIKRAM), `chintamani`
  ("HindawiAI in Telugu"), dev utilities, and a large set of **third-party forks**
  (qiskit, sway, FHIR, ART, runc, …).

Overlap and friction points:
- Two site repos: **`ilm-site`** and **`ilm.codes`** — one is canonical, the other
  is likely stale. Dedup candidate #1.
- **`legacy`** (fork of Project Hindawi) vs the living `ilm-*` stack — lineage root
  vs current implementation; placement should make that relationship explicit.
- **`chintamani`** (HindawiAI/Telugu, in `ayerunner`) is ILM-lineage but lives in
  the AyeAI tree — convergence candidate.
- Original IP and third-party forks are intermixed in `ayeai`, making "what is
  ours" hard to read at a glance.
- **[confirm]** actual scope/status of `chuha`, `upload`, `ayeq`, `unani` — their
  repo descriptions weren't conclusive; I won't place them until you confirm.

---

## 2. Target structure

Five buckets, each with one clear purpose. Orgs stay as the top-level boundary;
the buckets are how repos are tagged/grouped and described, not necessarily new
orgs.

1. **ILM Core** (`project-ilm`) — the canonical layer stack and language assets:
   `ilm-phonology … ilm-interface`, `ilm-data`, `ilm-validation`, `ilm-lsp`,
   `language-specs`, `romenagri`. The reversible-identity substrate. Nothing here
   depends on AyeAI products.

2. **ILM Tooling** (`project-ilm`) — reusable, project-neutral tools published for
   anyone: `misty-doi`, `spi-scan`, `foundry`, `ops`, `ai-scratch`,
   `ilm-devtools`, `vscode-ilm`. These are *consumers* of Core, not Core.

3. **Site & Docs** (`project-ilm`) — exactly one canonical site: **`ilm.codes`**.
   Retire/redirect `ilm-site` (archive it, keep history). `ilm-meta` holds
   vision/architecture.

4. **AyeAI Products** (`ayeai` + sub-orgs) — the applied systems: `ayeam`,
   `opssi`, `athena`, `ayepy`, games, `ayevdi`. Each states its dependency on ILM
   Core/Tooling explicitly so the boundary is visible.

5. **Vendored Forks** (`ayeai`, clearly segregated) — every third-party fork moved
   under an obvious naming/topic convention (e.g. topic `upstream-fork`) so
   "ours vs borrowed" is unambiguous. This directly serves the "what have we
   created" question that recurs across the multi-AI inventory.

Cross-cutting: **GramSheel Foundation / NGO** assets (`athena`/VIKRAM and kin)
tagged as such, since their governance and funding context differ from the IP.

---

## 3. Dedup candidates (concrete)

| # | Candidate | Action |
| --- | --- | --- |
| 1 | `ilm-site` vs `ilm.codes` | keep `ilm.codes`; archive `ilm-site` with a redirect note |
| 2 | `legacy` (Hindawi fork) | keep as the named lineage root; link it from `ilm-meta`, don't let it masquerade as current |
| 3 | `chintamani` (Telugu HindawiAI) | converge under ILM Core/Products with explicit ILM lineage |
| 4 | local `~/work` sprawl | run `dedupe_scan.sh ~/work` — many tarballs/scripts are redundant copies of committed content |
| 5 | duplicate keyword/registry tables | the N-tables-1-kernel invariant work; converge to the single canonical kernel |

The local filesystem dedup (#4) is the one I can hand you a tool for now;
`dedupe_scan.sh` reports duplicate groups by content hash and reclaimable space,
report-only until you pass `--clean`.

---

## 4. Convergence sequence (gated)

Order matters; each step gates the next.

1. **Inventory freeze** — snapshot both orgs' repo lists (the multi-AI inventory
   is the seed; reconcile Claude/ChatGPT/Gemini versions into one).
2. **Local dedup** — `dedupe_scan.sh ~/work`, reclaim space, identify what's
   already in git vs loose.
3. **SPI sweep** — `pre_announce_scan.sh --org project-ilm --org ayeai --local ~/work`.
   **No public move proceeds while this returns FAIL.** (This is also where the
   leaked Zenodo token would surface in history.)
4. **Forge mirrors up** — `mirror_forges.sh` to GitLab/Codeberg/Savannah/etc., so
   resilience exists *before* visibility increases.
5. **Restructure** — archive `ilm-site`, segregate forks, converge `chintamani`,
   tag NGO assets. Each move via fork→PR or `gh repo` with loud output.
6. **Announce** — only after 3 is PASS and 4 is in place.

---

## 5. What needs your input before execution

- Confirm scope of `chuha`, `upload`, `ayeq`, `unani` (placement undecided).
- Confirm `ilm.codes` is the canonical site (assumed) and `ilm-site` is the one to
  archive.
- Confirm whether forks should stay in `ayeai` under a topic, or move to a
  dedicated `*-vendor` space.
- AtlasViz location — still unlocated in the public listing; private or renamed?

© 1993-2026 Abhishek Choudhary. GPL-3.0-or-later.
