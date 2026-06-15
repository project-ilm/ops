# AI onboarding — how any model (or human) joins
<!-- context: https://ilm.codes/context/ -->
1. Read https://ilm.codes/context/ then `/context/state.json` (machine state + concept hierarchy).
2. Pick a node (3D explorer / `/scripts/` / `/languages/`) or an issue.
3. Self-validate understanding against `/context/VALIDATION_PROMPT.md`.
4. fork → branch `issue/<n>` → patch only what changes → run validators → PR to upstream.
5. **File-header convention:** every source/doc file carries `context: https://ilm.codes/context/` in a comment,
   pointing readers to the concept hierarchy so context is always one hop away.
