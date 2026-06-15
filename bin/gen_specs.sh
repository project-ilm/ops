#!/usr/bin/env bash
# gen_specs.sh — scaffold the formal specification set into language-specs/en + a reusable template.
# context: https://ilm.codes/context/
set -euo pipefail
W=~/work/11jun; source "$W/ops/bin/lib.sh"
S="$(ilm_repo language-specs)"; ilm_branch "$S" ai/spec-set; mkdir -p "$S/en" "$S/templates"
cat > "$S/templates/SPEC_TEMPLATE.md" <<'T'
<!-- context: https://ilm.codes/context/ | ILM specification template (RFC-like). Localize via localize.sh -->
# {TITLE}
**Status:** Draft · **Layer:** {LAYER} · **Traces to:** ILM Architecture Specification (IAS)
## Abstract
{ABSTRACT}
## 1. Scope
## 2. Normative references
*Cite host standards normatively; do not reproduce their text. Localized deltas are defined here and copyrighted as the emergent work.*
## 3. Definitions ## 4. Requirements (normative) ## 5. Conformance ## 6. Security & privacy ## 7. IP & licensing
GPL-3.0-or-later / CC-BY-4.0 as applicable · © 1993-2026 Abhishek Choudhary.
T
python3 - "$S" <<'PYE'
import sys,os
S=sys.argv[1]; tmpl=open(os.path.join(S,"templates","SPEC_TEMPLATE.md")).read()
specs=[
("ias","0","ILM Architecture Specification (IAS)","The architectural constitution of Project ILM: it defines what ILM is, its subsystems, the protocol boundaries, what the master programme and each pillar own, the interfaces, invariants, extension points, what constitutes protocol conformance, and what is intentionally out of scope. Every PDD, protocol specification, reference implementation, certification criterion and research work package traces back to this document."),
("semp","1","Systems Engineering Management Plan (SEMP)","Defines how the ILM programme is engineered and managed: lifecycle, work breakdown, reviews, configuration and interface control, verification and validation, risk, quality, and the federated multi-stakeholder governance under which independent contributors deliver protocol-compliant artefacts."),
("icd","1","Interface Control Document (ICD)","Specifies the common interface and protocol layer shared by Pillar I and Pillar II: the canonical computational identity, registries and identifiers, transliteration protocol, metadata, validation and conformance interfaces — the contract neither pillar owns but both implement."),
("vv","1","Verification & Validation Master Plan","Defines how ILM artefacts are verified and validated: round-trip transliteration fidelity, canonical-identity preservation, compiler and machine compatibility, protocol conformance, and the test-suite and statistical-confidence regime."),
("risk","1","Risk Register","Enumerates programme risks (data scarcity, linguistic viscosity, toolchain complexity, funding continuity, technology shifts, adoption) with mitigations, owners and review cadence."),
("gov","1","Governance & Standards Lifecycle","Defines the standards lifecycle (open, proposed, accepted, active, review, completed, versioned, published), the working groups, and the multi-level governance that keeps the federation interoperable without centralization."),
("ip","1","Intellectual Property Strategy","States how ILM cites host standards normatively without reproducing them, copyrights the emergent localized languages and specifications, and licenses artefacts while protecting provenance and priority."),
("ccid","2","Canonical Computational Identity Specification","Defines the invariant computational identity that survives projection across scripts, orthographies, transliterations, encodings and storage — the linking identity for languages, scripts, representations, executables, verification and knowledge graphs."),
("romenagri","2","Romenagri Specification","Specifies the reversible canonical transliteration layer originating in Hindawi (2003-2004): grammar, phoneme model, reversibility profile and ASCII-7 canonical form, generalized across script families."),
("shaili","2","Shaili Language Specification","Specifies the Shaili family of localized programming-language realizations as a delta over a normatively-cited host standard plus an apply tool, with the emergent localized language copyrighted as the new work."),
]
for slug,layer,title,abs in specs:
    out=tmpl.replace("{TITLE}",title).replace("{LAYER}",layer).replace("{ABSTRACT}",abs)
    open(os.path.join(S,"en",slug+".md"),"w").write(out)
print("wrote",len(specs),"specs to en/")
PYE
git -C "$S" add -A
git -C "$S" commit -q -m "feat(specs): RFC-like spec set (IAS, SEMP, ICD, V&V, Risk, Governance, IP, CCID, Romenagri, Shaili) + template" || echo "(no change)"
ilm_pr "$S" ai/spec-set "feat(specs): formal specification set + template" \
"English masters + reusable RFC-like template. IAS is the architectural constitution; every other doc traces to it. Localize to hi/ur/fa with ops/bin/localize.sh."
