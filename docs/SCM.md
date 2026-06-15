# SCM — configuration management
<!-- context: https://ilm.codes/context/ -->
Surface = scripts (~226 ISO 15924) × human languages (~7,867 ISO 639-3) × paradigms/layers (L0..L9).
**Do not make a repo per cell.** Data-driven: registries + per-node manifests generate every artifact.
- **Node id:** `script:<Code>` or `lang:<iso639-3>@<layer>` (e.g. `lang:san@L4`).
- **Manifest** (`manifests/<id>.json`): {status, spec, binding, doi, refs[], install, updated}.
- **Versioning:** semver per artifact; the registry pins which manifest version is current.
- **Generated, never hand-forked:** node pages, specs, bindings, grammars, DOIs all rebuild from manifests.
