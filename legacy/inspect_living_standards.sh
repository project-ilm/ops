#!/usr/bin/env bash

set -e

ROOT="${1:-.}"

echo
echo "========================================"
echo "SEARCHING FOR LIVING STANDARDS FILES"
echo "========================================"
echo

find "$ROOT" \
    -type f \
    \( \
       -name "living_standards_generator.py" \
       -o -name "review_tool.py" \
    \)

echo
echo "========================================"
echo "LOCATING FILES"
echo "========================================"
echo

GEN=$(find "$ROOT" -type f -name "living_standards_generator.py" | head -1)
REV=$(find "$ROOT" -type f -name "review_tool.py" | head -1)

echo "GENERATOR: $GEN"
echo "REVIEW:    $REV"

echo
echo "========================================"
echo "GENERATOR HEADER"
echo "========================================"
echo

if [ -f "$GEN" ]; then
    head -100 "$GEN"
fi

echo
echo "========================================"
echo "REVIEW HEADER"
echo "========================================"
echo

if [ -f "$REV" ]; then
    head -100 "$REV"
fi

echo
echo "========================================"
echo "ARGPARSE / SYSARGV"
echo "========================================"
echo

if [ -f "$GEN" ]; then
    grep -nE "argparse|sys.argv|__main__" "$GEN" || true
fi

if [ -f "$REV" ]; then
    grep -nE "argparse|sys.argv|__main__" "$REV" || true
fi

echo
echo "========================================"
echo "FUNCTIONS"
echo "========================================"
echo

if [ -f "$GEN" ]; then
    grep -n "^def " "$GEN" || true
fi

if [ -f "$REV" ]; then
    grep -n "^def " "$REV" || true
fi

echo
echo "========================================"
echo "PYTHON COMPILE CHECK"
echo "========================================"
echo

if [ -f "$GEN" ]; then
    echo "Checking generator..."
    python3 -m py_compile "$GEN" \
        && echo "Generator compiles OK" \
        || echo "Generator compile FAILED"
fi

if [ -f "$REV" ]; then
    echo "Checking review tool..."
    python3 -m py_compile "$REV" \
        && echo "Review tool compiles OK" \
        || echo "Review tool compile FAILED"
fi

echo
echo "========================================"
echo "TRYING --help"
echo "========================================"
echo

if [ -f "$GEN" ]; then
    python3 "$GEN" --help 2>&1 || true
fi

echo
echo

if [ -f "$REV" ]; then
    python3 "$REV" --help 2>&1 || true
fi

echo
echo "========================================"
echo "DONE"
echo "========================================"

