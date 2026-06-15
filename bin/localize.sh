#!/usr/bin/env bash
# localize.sh — produce hi/ur/fa copies of the English specs. Set TRANSLATE_CMD to a stdin->stdout translator,
# e.g.: export TRANSLATE_CMD='trans -b en:hi'  (translate-shell). context: https://ilm.codes/context/
set -euo pipefail
W=~/work/11jun; S="$W/repos/language-specs"; LANGS="${LANGS:-hi ur fa}"
[ -d "$S/en" ] || { echo "run gen_specs.sh first"; exit 1; }
for L in $LANGS; do mkdir -p "$S/$L"
  for f in "$S/en"/*.md; do b=$(basename "$f")
    if [ -n "${TRANSLATE_CMD:-}" ]; then "${TRANSLATE_CMD/en:hi/en:$L}" < "$f" > "$S/$L/$b" || cp "$f" "$S/$L/$b"
    else { echo "<!-- TODO localize to $L : set TRANSLATE_CMD or paste Google-translated text -->"; cat "$f"; } > "$S/$L/$b"; fi
  done; echo "wrote $S/$L"
done
echo "Review, commit on a branch, open a PR (ops/docs/WORKFLOW.md)."
