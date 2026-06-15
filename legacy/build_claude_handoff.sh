#!/usr/bin/env bash

set -e

OUT="CLAUDE_ARCHITECTURE_HANDOFF.txt"
TAROUT="claude_evidence_bundle.tar.gz"

rm -f "$OUT"
rm -f "$TAROUT"

append_file() {
    local f="$1"

    if [ ! -f "$f" ]; then
        echo "[WARN] Missing: $f"
        return
    fi

    echo >> "$OUT"
    echo "############################################################" >> "$OUT"
    echo "FILE: $f" >> "$OUT"
    echo "############################################################" >> "$OUT"
    echo >> "$OUT"

    cat "$f" >> "$OUT"

    echo >> "$OUT"
    echo >> "$OUT"
}

echo "============================================================"
echo "Building architecture handoff"
echo "============================================================"

FILES="
RUNBOOK.md
ZENODO_INSTRUCTIONS.md

repos/romenagri/CONTINUITY.md
repos/romenagri/README.md

repos/ilm.codes/README.md

repos/chintamani/README.md
repos/legacy/README.md

repos/legacy/rti_20241211.md

repos/ilm.codes/data/ilm-semantic.csv

repos/ilm.codes/data/ilm-basic-keywords-mapping.csv
repos/ilm.codes/data/ilm-c-keywords-mapping.csv
repos/ilm.codes/data/ilm-cpp-keywords-mapping.csv
repos/ilm.codes/data/ilm-python-keywords-mapping.csv
repos/ilm.codes/data/ilm-js-keywords-mapping.csv
repos/ilm.codes/data/ilm-lex-keywords-mapping.csv
repos/ilm.codes/data/ilm-yacc-keywords-mapping.csv
repos/ilm.codes/data/ilm-logo-keywords-mapping.csv
repos/ilm.codes/data/ilm-gcc-x86_64-asm-keywords-mapping.csv

repos/romenagri/bindings/c/acii2rmn.c
repos/romenagri/bindings/c/rmn2acii.c

repos/romenagri/bindings/c/acii2rmn.h
repos/romenagri/bindings/c/rmn2acii.h
repos/romenagri/bindings/c/acii.h
"

for f in $FILES
do
    echo "[ADD] $f"
    append_file "$f"
done

echo
echo "============================================================"
echo "Building evidence bundle"
echo "============================================================"

tar czf "$TAROUT" \
    repos/chintamani/Hindawi \
    repos/legacy/Hindawi \
    repos/romenagri/demos \
    repos/legacy/samples \
    repos/chintamani/Notebooks \
    2>/dev/null || true

echo
echo "============================================================"
echo "Building repo inventory"
echo "============================================================"

{
    echo "############################################################"
    echo "# TREE"
    echo "############################################################"
    echo

    find repos -type f | sort

    echo
    echo
    echo "############################################################"
    echo "# LINE COUNTS"
    echo "############################################################"
    echo

    find repos -type f \
        \( \
            -name "*.c" -o \
            -name "*.h" -o \
            -name "*.cpp" -o \
            -name "*.awk" -o \
            -name "*.lex" -o \
            -name "*.csv" -o \
            -name "*.md" \
        \) \
        -exec wc -l {} \;

} > REPO_INVENTORY.txt

echo
echo "============================================================"
echo "RESULTS"
echo "============================================================"

ls -lh "$OUT" || true
ls -lh "$TAROUT" || true
ls -lh REPO_INVENTORY.txt || true

echo
echo "Line counts:"
wc -l "$OUT" || true
wc -l REPO_INVENTORY.txt || true

echo
echo "============================================================"
echo "CLAUDE PROMPT"
echo "============================================================"

cat << 'PROMPT'

Please access the previous conversation on Hindawi, Romenagri, ILM and rebuild what you can.

Read the files in this order:

1. CLAUDE_ARCHITECTURE_HANDOFF.txt
2. REPO_INVENTORY.txt
3. claude_evidence_bundle.tar.gz

Important architectural understanding:

- ILM is the umbrella architecture.
- Hindawi Programming System (HPS) is an Indic subset of ILM.
- Romenagri is the canonical reversible linguistic substrate.
- The objective is Linguistic Equity across the entire computing stack.
- Existing ecosystems are reused rather than reinvented.
- Existing programming language standards are localized.
- Keywords are translated.
- Execution semantics are not reinvented.
- The architecture relies on 100% reversible canonical mappings.
- Construct identity is preserved.
- Existing toolchains remain usable.
- GCC, LLVM, debuggers, SCM, IDEs and existing libraries remain intact.
- Localization is a presentation and ontology problem rather than a compiler reinvention problem.

Please reconstruct:

1. Architecture
2. Historical evolution
3. Romenagri design
4. Acii/ISCII layer
5. Construct ontology
6. Hindawi language family
7. ILM keyword mapping architecture
8. Linguistic Equity proof
9. Missing gaps
10. Future roadmap

PROMPT

echo
echo "[DONE]"
