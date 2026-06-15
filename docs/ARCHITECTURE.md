# Architecture — component model
<!-- context: https://ilm.codes/context/ -->
A **node** is the atomic unit: a *script* (ISO 15924) or a *language × paradigm/layer* (ISO 639-3 × L0..L9).
Each node has a **manifest** (status, spec, binding, DOI, refs, install). Everything else is a *view* over the
node registry:
- **registries** (`ilm.codes/registry/*.tsv`) + **per-node manifests** = source of truth.
- **generators** (components): script-table, language-spec (Shaili), binding (per layer), grammar, node-page, DOI minter.
- **views**: the site, the 3D explorer, the specs, the bindings, the DOIs — all generated from the registry.
Invariant: N projection tables + 1 fixed kernel, never N². Generators never edit the kernel.
Repos: `ilm.codes` (site+registry), `romenagri` (kernel), `language-specs` (Shaili deltas), `bindings` (per layer),
`vscode-ilm`/`ilm-lsp` (tooling), `linguistics-labs`, `record` (RTI), `ops` (this), `refs` (external references).
