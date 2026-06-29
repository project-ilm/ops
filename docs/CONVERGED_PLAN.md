# The Converged Plan — Project ILM ∴ AyeAI

Convergence in the operative sense: **canonical continuity preservation across
heterogeneous transforms** — one fixed kernel, many surfaces, no drift. Not
coherence, not flattening. This document is the single pick-up point: the
three-layer structure, the deduplication execution, the free automation that
makes it self-sustaining, distribution, monetization, the announcement sequence,
and what runs on a limited box.

Hard rules carried throughout: preserve structure/sequencing/compressions
exactly; per-item DOIs; date the lineage from 1993; **no individual/partner names
and no past employers in public-facing materials**; verify by execution; archive,
never delete; nothing public before the SPI gate is green.

---

## 1. The three layers (DO NOT FLATTEN)

The footprint is one lineage but three governance/funding regimes. Earlier I
collapsed these into a single open-source pile — that was the flattening you
called out. They are distinct:

### Layer A — Open Source (GPL-3.0)
The released public commons. Anyone can use it.
- **ILM / Hindawi / Romenagri** — the reversible multiscript kernel + the eight
  bidirectional host lexers (the source of truth in `chintamani`).
- **Tooling** — `misty-doi`, `spi-scan`, `foundry`, `ops`, the workflow engines
  (`publish_paper.sh`, `patent_track.sh`), the convergence toolchain.
- Surfaces: `ilm.codes`, the registries, the DOIs.
- Funding posture: GitHub Sponsors + Buy Me a Coffee + grant/credit programs.

### Layer B — Commercial (the AyeAI Triad)
The monetized intelligence architecture. **Separate from the GPL commons.**
- **AyeAI** (cognition) · **AyeCNSe** (causal nervous system / coherence) ·
  **AyeAM** (embodiment) — a single causal loop; remove one and it collapses.
- **CEMs** (Cognitive Enablement Module, Synthetiform — pre-singularity) and
  **CEMb** (Cognitive Enhancement Module, Bioforms — post-singularity),
  converging via Quantum Neuromorphic BCI.
- Entities: **AyeAI Consulting, Interglial Healthcare, Vyas Labs, Indicybers.**
- Surfaces: ayeai.xyz, ayecnse.net, icansee.life, ayeam.* (to register),
  cems.ai / interglial.com (commercial-facing).
- Monetization: consulting, productized modules, **IP licensing** of the patent
  estate, dual-licensing of otherwise-GPL components for commercial use.

### Layer C — NGO / Civic
Distinct governance, distinct funding (grants/CSR), not commercial.
- **GramSheel Foundation**, **Project VIKRAM** (with AyeATROS), **TWISHA** health
  initiative, **AyeLearn** pedagogy ladder.
- Surfaces: projectvikram.github.io, gsftwisha.github.io.

The convergence keeps these legible and **linked but not merged** — a repo, a
DOI, a domain each declares which layer it belongs to.

---

## 2. Deduplication & restructuring — execution (from real data)

Ground truth from `discover_all.sh`: **457 repos · 94 namespaces · 190 original ·
267 forks (58%) · 0 archived · 10 empty · 18 private · 418 stale · 27 name-collision
groups · 114 site candidates.**

Execution order (mechanical first — biggest surface reduction per unit effort):

1. **Segregate the 267 forks.** Tag every fork `upstream-fork`. This alone makes
   "ours vs borrowed" a one-query distinction and removes 58% of the noise from
   every later view. (`mirror_forges.sh`/topic pass; no deletion.)
2. **Archive the dead surface.** 418 stale (>1y) + 10 empty → archive (reversible),
   shrinking the *active* set to the few dozen repos that actually move.
3. **Resolve the 27 name-collisions**, worst first:
   `icd102018 ×17` → `ayevdi ×4` → `healthcare ×4` → `ayepagesgithubio ×3` →
   `education ×3` → `hindawi2016 ×3` → … For each: pick one canonical, redirect/
   archive the rest. The 17-way `icd102018` collision is the single highest-value
   cleanup.
4. **Assign each survivor to a layer** (A/B/C above) via a repo topic, then cluster
   originals into the five buckets (ILM Core / Tooling / Site / Products / NGO).
5. **Sites:** 114 candidates → choose the canonical site per layer; archive
   duplicate Pages repos; ensure each live site has a CNAME + the Pages workflow.

Gate: `pre_announce_scan.sh` over all namespaces must return **PASS** (spi-scan is
now installed) before any of this goes public-loud.

---

## 3. Free automation / CI-CD (the gap you flagged)

All free on GitHub. Delivered as three workflows:

- **`pypi-publish.yml`** — tag `v*` → build → publish to PyPI via **OIDC Trusted
  Publishing (no stored token)**. Applied to `misty-doi` and `spi-scan`; this is
  what finally makes `pip install spi-scan` work. One-time: add the GitHub trusted
  publisher on each PyPI project.
- **`pages.yml`** — push to `main` → deploy `ilm.codes`. **This ends the
  manual-regeneration-clobber problem**: `main` becomes the deployed source, so the
  `/workflows/`, `/tools/`, `/convergence-map/` pages stay live.
- **`release.yml`** — tag `v*` → GitHub Release with built artifacts + auto notes;
  pairs with Zenodo's GitHub integration for an automatic per-release DOI.

Next: enable Zenodo↔GitHub on the release-bearing repos so every tagged release
mints a DOI with zero manual steps (replaces hand-minting).

---

## 4. Distribution beyond PyPI

What the application layer uses these days, and where each tool fits:

| Channel | Ecosystem | Use it for |
| --- | --- | --- |
| **PyPI** | Python | misty-doi, spi-scan (primary) |
| **crates.io** | Rust | a future fast reversible-kernel core (Romenagri in Rust) |
| **Julia General** | Julia | numeric/linguistic analysis packages, if/when |
| **npm** | JS/TS | a browser/JS binding for misty/romenagri (web-first surfaces) |
| **conda-forge** | cross | research users who live in conda |
| **Homebrew tap** | macOS/Linux | `brew install` for the CLIs |
| **Docker / GHCR** | containers | reproducible runner images; free on GHCR |
| **Zenodo** | archival | the citable DOI of record (already in use) |

Recommended near-term: PyPI (done via CI), a **Homebrew tap** (cheap, high-reach
for CLIs), and **GHCR images** (free, makes the tools reproducible anywhere). Rust/
Julia/npm only when there's a real second implementation to publish — not as
box-ticking.

---

## 5. Run it on a limited box — small models + free cloud

- **Local (Ollama)** via `local_models_setup.sh`: a curated *happy small* set —
  `qwen2.5:0.5b`, `gemma2:2b`, `llama3.2:1b` (very low RAM), and `qwen2.5:3b`,
  `phi3:mini`, `llama3.2:3b` (4–8 GB). Good enough for the CIIO/DPE/CLACE bias
  harness, local drafting, and keeping the laptop busy. Point runners at
  `http://localhost:11434`.
- **Free cloud (Colab/Kaggle)**: `notebooks/ilm_quickstart.ipynb` ships with
  **Open-in-Colab / Open-in-Kaggle badges** so anything heavy runs on free GPUs
  without touching your box. Drop the same badge pair into each repo's README.

---

## 6. Monetization (de-flattened, Layer B)

- **GitHub Sponsors** + **Buy Me a Coffee** on the OSS repos (Layer A) — supports
  the commons without commercializing it.
- **Consulting** (AyeAI Consulting) — architecture/systems engagements.
- **IP licensing** — the patent estate (PEDLER/ICAML, Romenagri 2.0, CLACE Decision
  Safety Kernel, HMSEI v2) licensed commercially; the master provisional splits
  into non-provisionals within 12 months.
- **Dual licensing** — GPL for the commons; commercial license for closed use of
  the same components (standard OSS revenue model; keeps Layer A honest while
  funding Layer B).
- **Productized modules** — CEMs/CEMb and Interglial Healthcare products.

---

## 7. Social presence & the release announcement

Stubs/channels (already partly live; do NOT name individuals or employers):
LinkedIn (the **VIDYA** newsletter is running), **X/Twitter** (8-tweet thread),
**Instagram @ayeai.ilm**, **Bluesky**, **Mastodon** (linguistics.social),
**LINGUIST List**, **arXiv** (via endorsement). A `SOCIAL_MEDIA_SCRIPTS.md`
already exists from the release-plan work — reuse it, don't rewrite.

Announcement sequence (gated): **(0)** SPI gate PASS + token rotated → **(1)**
push, CI green, Pages live, tags cut → **(2)** Zenodo DOIs auto-minted →
**(3)** GitHub release notes → **(4)** LinkedIn/VIDYA + X thread → **(5)** Instagram
/ Bluesky / Mastodon → **(6)** LINGUIST List + arXiv. Per-item DOIs throughout;
each post links the DOI, not a vendor page.

---

## 8. Context continuity

`context/REBUILD.md` is the cold-start map; it was **stale at 15 Jun** (tested).
`context/REBUILD_ADDENDUM_20260629.md` carries it to today (the misty-doi/foundry/
hardening/convergence/CI-CD arc + this three-layer split). Cold-start order:
REBUILD.md → addendum → resume from §G'. The Pages workflow keeps the live
`ilm.codes/context/` in sync automatically once merged.

---

## 9. Immediate next actions (ordered)

1. Merge the CI/CD + context-addendum + notebook PRs (below).
2. Configure PyPI Trusted Publishing on misty-doi + spi-scan; cut `v1.0.2` tags →
   auto-publish (and `pip install spi-scan` starts working).
3. Turn on GitHub Pages "deploy from Actions" for ilm.codes (the `pages.yml` path).
4. Run the dedup execution (§2) — forks first, then stale, then `icd102018`.
5. `pre_announce_scan.sh` all namespaces → PASS; rotate the leaked Zenodo token.
6. Enable Zenodo↔GitHub; cut releases; run the announcement sequence (§7).

© 1993–2026 Abhishek Choudhary · GPL-3.0-or-later / CC-BY-4.0 as applicable.
Layer B (AyeAI Triad / CEMs / CEMb) is commercial and separately licensed.
