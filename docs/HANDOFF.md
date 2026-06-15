# Handoff — to Gemini / ChatGPT / a human
<!-- context: https://ilm.codes/context/ -->
Handing work off = **open an issue**, not a chat dump. The issue carries:
1. **Node + goal** (which script/language×layer, what artifact).
2. **Bootstrap prompt** — a *pointer*, not a payload (the context does not fit in a URL):
   > Continue Project ILM. Build context by reading, in order: https://ilm.codes/context/ ,
   > https://ilm.codes/context/state.json , and the node page <NODE_URL>. Self-check against
   > https://ilm.codes/context/VALIDATION_PROMPT.md . If the artifact exists, surface it; else scaffold it
   > under the Shaili/Charter rules and open a fork→PR.
3. **Check-in contract:** fork `<org>/<repo>`, branch `issue/<n>`, validate, PR to upstream, reference this issue.
The agent *fetches* the URLs to build context — a fresh session, because it won't fit in one prompt.
