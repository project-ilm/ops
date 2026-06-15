#!/usr/bin/env bash

set -e

OUT="HINDAWI_COMPLETE_HANDOFF.txt"

rm -f "$OUT"

append_file() {
    local f="$1"

    echo >> "$OUT"
    echo "############################################################" >> "$OUT"
    echo "FILE: $f" >> "$OUT"
    echo "############################################################" >> "$OUT"
    echo >> "$OUT"

    cat "$f" >> "$OUT" 2>/dev/null || true

    echo >> "$OUT"
    echo >> "$OUT"
}

echo "[INFO] Locating Hindawi trees..."

find repos \
    \( -iname "*hindawi*" -o -iname "*hind*" \) \
    -type d \
    > hindawi_dirs.txt

echo
echo "[INFO] Directories found:"
cat hindawi_dirs.txt

echo
echo "[INFO] Building inventory..."

{
    echo "############################################################"
    echo "# INVENTORY"
    echo "############################################################"
    echo

    while read d
    do
        echo
        echo "===== $d ====="
        find "$d" -type f | sort
    done < hindawi_dirs.txt

} > HINDAWI_INVENTORY.txt

echo
echo "[INFO] Extracting source..."

while read d
do

    find "$d" -type f \
        \( \
            -name "*.c" \
            -o -name "*.h" \
            -o -name "*.cpp" \
            -o -name "*.hpp" \
            -o -name "*.l" \
            -o -name "*.lex" \
            -o -name "*.y" \
            -o -name "*.yacc" \
            -o -name "*.uhin" \
            -o -name "*.txt" \
            -o -name "*.md" \
            -o -name "*.csv" \
            -o -name "*.ini" \
            -o -name "*.cfg" \
            -o -name "*.mak" \
            -o -name "Makefile" \
            -o -name "*.sh" \
        \) \
        | sort \
        | while read f
          do
              append_file "$f"
          done

done < hindawi_dirs.txt

echo
echo "[INFO] Building shaili inventory..."

grep -RIn \
    -E "shaili|shailee|shraeni|guru|yantra|kritrima|praatha|wyaaka|soochee|hindrv|hincc|h2c|c2h|h2cpp|cpp2h|h2j|j2h|h2b|b2h|lex|yacc" \
    repos \
    > HINDAWI_REFERENCES.txt || true

echo
echo "[INFO] Creating source archive..."

tar czf hindawi_complete_sources.tar.gz \
    $(cat hindawi_dirs.txt) \
    2>/dev/null || true

echo
echo "============================================================"
echo "RESULTS"
echo "============================================================"

ls -lh HINDAWI_COMPLETE_HANDOFF.txt
ls -lh HINDAWI_INVENTORY.txt
ls -lh HINDAWI_REFERENCES.txt
ls -lh hindawi_complete_sources.tar.gz

echo
wc -l HINDAWI_COMPLETE_HANDOFF.txt
wc -l HINDAWI_REFERENCES.txt

echo
echo "[DONE]"

