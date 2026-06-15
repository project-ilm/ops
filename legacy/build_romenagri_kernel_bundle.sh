#!/usr/bin/env bash

set -e

OUT="ROMENAGRI_KERNEL_HANDOFF.txt"

rm -f "$OUT"

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

FILES="
repos/romenagri/README.md
repos/romenagri/CONTINUITY.md

repos/romenagri/src/acii.h
repos/romenagri/src/acii2rmn.h
repos/romenagri/src/acii2rmn.c
repos/romenagri/src/rmn2acii.h
repos/romenagri/src/rmn2acii.c
repos/romenagri/src/stack.h
repos/romenagri/src/stack.c

repos/romenagri/bindings/c/acii.h
repos/romenagri/bindings/c/acii2rmn.h
repos/romenagri/bindings/c/acii2rmn.c
repos/romenagri/bindings/c/rmn2acii.h
repos/romenagri/bindings/c/rmn2acii.c
repos/romenagri/bindings/c/stack.h
repos/romenagri/bindings/c/stack.c
"

for f in $FILES
do
    append_file "$f"
done

echo
echo "############################################################" >> "$OUT"
echo "TABLE INVENTORY" >> "$OUT"
echo "############################################################" >> "$OUT"
echo >> "$OUT"

find repos/romenagri/tables -type f 2>/dev/null | sort \
>> "$OUT"

echo
echo "Built:"
echo "$OUT"

wc -l "$OUT"
ls -lh "$OUT"

echo
echo "Creating source tarball..."

tar czf romenagri_kernel_sources.tar.gz \
    repos/romenagri/src \
    repos/romenagri/bindings/c \
    repos/romenagri/tables \
    2>/dev/null || true

ls -lh romenagri_kernel_sources.tar.gz
