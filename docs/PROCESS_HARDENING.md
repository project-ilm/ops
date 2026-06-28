# Process Hardening — FPSS, INCOSE ilities, FMECA / FTA / HAZOP

The co-development process (agent↔agent, agent↔human, human↔human) is treated as
a **safety- and reliability-critical system**, not a convenience. Its failures
in the 28-Jun session — a script that refused on files it should have written, an
unclear run path, a host clobber risk, a PEP 668 install break, a stale-symlink
respin, and a live token pasted into a shared channel — are the dataset this
hardening is built from. Every clause below maps to an observed failure and to a
mechanical check in `bin/contract_check.sh`.

Authority order: this doc and `CONTEXTUAL_CONTRACTS.md` are the contract;
`contract_check.sh` is its machine enforcement; everything else is downstream.

---

## 1. FPSS — the objective

**First-Pass Success (FPSS).** Borrowed from First-Pass Silicon Success: a chip
respin costs months, so the design is exhaustively verified *before* tape-out.
An artifact handed across a boundary is a tape-out. The recipient — human or AI,
sharing none of the author's state — must get a correct result on the **first**
execution. Iteration ("flaky") is a respin, and respins are the defect.

The gate is the design-rule check before tape-out: an artifact is not handed off
until `contract_check.sh` returns PASS. No PASS, no handoff.

---

## 2. INCOSE ilities — requirement and verification

Each non-functional quality is a requirement with a *mechanical* verification,
not an aspiration.

| Ility | Requirement on every artifact | Verified by |
| --- | --- | --- |
| Reliability | Works first time on a clean host; no unstated preconditions | CHK-02, CHK-10 |
| Usability | Recipient learns to run it from the artifact itself | CHK-01 |
| Portability | Runs across host/OS/Python; declares env, never assumes | CHK-03 |
| Reproducibility | Reconstructs its own artifacts byte-identically | CHK-02, CHK-09 |
| Maintainability | Self-describing; canonical home stated | CHK-01, contract C6 |
| Testability | Has a dry-run / no-op path exercisable without side effects | CHK-05, CHK-09 |
| Recoverability | Re-runnable; aborts on mismatch; restores cleanly | CHK-07 |
| Security | No secret crosses a boundary in the artifact | CHK-04 |
| Safety | No-flag run is inert; irreversible acts gated + confirmed | CHK-05, CHK-06 |
| Observability | Prints every URL/result of a mutating action | CHK-08 |
| Idempotency | Second run is safe; writes into its own scope | CHK-07 |
| Interoperability | Stable I/O contract (env in, JSON/exit out) | misty contract |

A future requirement (his standing aim): the load-bearing ilities should be
*formally proven*, not only checked. The checker is detection (lowers
probability); proof is the next tier. Stated honestly so the gap is visible.

---

## 3. FMECA — failure mode, effects, criticality (from real data)

S = severity, O = occurrence, D = detectability (1 best – 5 worst). RPN = S·O·D.
Every mode below was *observed this session*; the mitigation is now a contract +
a check, which is what drops O and D on the next pass.

| ID | Failure mode | Effect | S | O | D | RPN | Mitigation (now enforced) |
| --- | --- | --- | :-: | :-: | :-: | :-: | --- |
| FM1 | Script checks for inputs instead of writing them | Hard stop; recipient blocked | 4 | 5 | 1 | 20 | C1 self-contained; **CHK-02** |
| FM2 | No run instructions; run from wrong dir | Failure + confusion | 3 | 4 | 2 | 24 | C1/usability; **CHK-01**, RUN_ME |
| FM3 | `mkdir` generic dirs in CWD | Clobbers recipient's tree | 5 | 3 | 3 | 45 | C6 own-subdir; **CHK-07** |
| FM4 | Bare `pip install` on PEP 668 host | Install fails | 3 | 5 | 1 | 15 | C2 declared env (pipx); **CHK-03** |
| FM5 | Stale host state (symlink) not detected | Respin, needs sudo | 2 | 3 | 4 | 24 | C2 detect-don't-assume; **CHK-03 tool-probe** |
| FM6 | Confirm requires exact token; near-miss input | Action skipped (safe) | 1 | 3 | 1 | 3 | Acceptable; safe-fail by design |
| FM7 | **Live token pasted into shared channel** | Credential disclosure | 5 | 3 | 2 | 30 | C3 secrets-by-path; **CHK-04**; rotate-on-exposure runbook |

Highest RPNs (FM3 clobber, FM7 secret) get the strongest controls: hard-FAIL
checks, not warnings. FM7 additionally carries an operational rule: **any secret
that appears in a transcript, log, or PR is treated as compromised and rotated
immediately** — detection is assumed imperfect, so exposure ⇒ rotation, always.

---

## 4. FTA — fault trees for the top events

Top events and their AND/OR decomposition. A control on any cut-set leaf breaks
the path to the top event.

```
TE1  Irreversible wrong action (wrong DOI / wrong repo / data loss)
  OR ── no confirmation gate            ──► CHK-06 (confirm before irreversible)
  OR ── side effect on a no-flag run    ──► CHK-05 (safe by default)
  OR ── wrong target not echoed/checked ──► CHK-08 (loud) + C7 (verify before mutate)

TE2  Credential disclosure
  OR ── secret embedded in artifact     ──► CHK-04 (no hardcoded secrets)
  OR ── secret printed to a shared log  ──► C3 + log hygiene (env only, never echo)
  OR ── secret reaches a PR/transcript  ──► rotate-on-exposure runbook (FM7)

TE3  Silent drift across a handoff
  AND ─ contract not re-verified at boundary  ──► stage-gate §5 (gate at every edge)
  AND ─ artifact not self-describing/canonical ──► C6 + CHK-01

TE4  Non-reproducible artifact
  OR ── depends on author-only files    ──► CHK-02 (self-contained)
  OR ── no checksum/dry-run to verify    ──► CHK-09
```

---

## 5. HAZOP — deviation analysis at each handoff edge

The handoff pipeline has four nodes: **Author → Gate → Recipient → Execute.**
Guidewords applied to the artifact crossing each edge:

| Guideword | Deviation | Control |
| --- | --- | --- |
| NO / NONE | artifact arrives with no instructions / no gate run | CHK-01; gate is mandatory (§6) |
| MORE | does more than stated (hidden side effect) | CHK-05 safe-default |
| LESS | does less (silently skips a step) | LOUD output CHK-08; exit codes |
| AS WELL AS | also writes the recipient's existing files | CHK-07 own-subdir |
| PART OF | only part of the bundle arrives (binary missing) | CHK-02 + explicit "where I look / what I do if absent" |
| REVERSE | runs an irreversible step before a reversible check | safe-by-default ordering: validate/dry-run always precede mint |
| OTHER THAN | runs in a different env than assumed | CHK-03 declare + detect |
| EARLY / LATE | publishes before review / token set | confirm gate + env preconditions |

---

## 6. The zero-drift stage gate (revise contracts at every boundary)

Contracts are not signed once; they are **re-verified at every edge**. Drift is
prevented by making the gate a precondition of crossing, regardless of who is on
either side.

**Agent → Agent.** The producing agent runs `contract_check.sh` and records the
PASS in the PR/handoff note. The receiving agent re-runs it (does not trust the
claim) and restates the contracts in its own words before acting — this is the
CIIO/identity-override guard: a fresh agent re-derives the contract rather than
inheriting an assumed one.

**Agent → Human.** Gate must PASS; a RUN_ME/usage path must exist (CHK-01); the
artifact and its logs are scrubbed of secrets (CHK-04). The human receives one
verified command, not a tree of options.

**Human → Human.** Same gate, plus provenance: canonical repo+path stated (C6),
so the next human places it identically. No "it's in my working dir."

**Invariant:** *no artifact crosses any edge with a failing gate.* That single
rule is what converts the contracts from documentation into zero-drift
enforcement. The gate runs at the boundary every time — that is the whole point.

---

## 7. Operating it

```bash
# before any handoff (CI step, pre-push hook, or by hand):
ops/bin/contract_check.sh path/to/artifact.sh           # PASS required
ops/bin/contract_check.sh path/to/bundle/  --strict     # WARN treated as FAIL
```

Wire it as a required check on PRs that add `*.sh` seed/push/release scripts, and
as a `pre-push` hook locally. A red gate blocks the handoff; that is success, not
obstruction — it is the respin caught before tape-out.

© 1993-2026 Abhishek Choudhary. GPL-3.0-or-later.
