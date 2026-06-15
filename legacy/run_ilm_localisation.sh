#!/usr/bin/env bash
# run_ilm_localisation.sh — ONE-SHOT: decompress ilm_localisation.tar.gz, install scripts,
# run the localisation chain, regenerate the academic results page, commit + push.
# Place THIS file and ilm_localisation.tar.gz in ~/work/11jun/ , then:  bash run_ilm_localisation.sh
# (C) 1993-2026 Abhishek Choudhary, GPL-3.0-or-later
set -uo pipefail
W=~/work/11jun
mkdir -p "$W/logs" "$W/scripts"; L="$W/logs/run.log"; st(){ echo "[STATUS] $*" | tee -a "$L"; }
fail(){ echo "[FAIL] $*" | tee -a "$L"; exit 1; }

st "=== ILM localisation one-shot $(date) ==="

# 1. locate + DECOMPRESS the tarball (look next to this script, then in ~/work/11jun, then Downloads)
TB=""
for d in "$(dirname "$0")" "$W" ~/Downloads ~/snap/firefox/common/Downloads .; do
  [ -f "$d/ilm_localisation.tar.gz" ] && TB="$d/ilm_localisation.tar.gz" && break
done
[ -n "$TB" ] || fail "ilm_localisation.tar.gz not found (put it beside this script or in ~/work/11jun)"
st "1. decompress $TB"
TMP="$(mktemp -d)"; tar xzf "$TB" -C "$TMP" || fail "tar extract"
SRC="$TMP/ilm_localisation"
[ -d "$SRC/scripts" ] || fail "tarball layout unexpected (no ilm_localisation/scripts)"

st "2. install scripts 125..129 into $W/scripts/"
cp "$SRC"/scripts/12[5-9]_*.sh "$W/scripts/" || fail "copy scripts"
chmod +x "$W/scripts/"12[5-9]_*.sh
cp "$SRC/README.md" "$W/README_ilm_localisation.md" 2>/dev/null || true

# 3. preconditions from the earlier delivery (run only if present & needed)
B="$W/repos/romenagri/bindings/c"
command -v autoreconf >/dev/null || st "   note: autoconf/automake recommended (sudo apt-get install -y autoconf automake)"
if [ -f "$W/scripts/110_substrate_autoconf.sh" ] && [ ! -f "$B/substrate.h" ]; then
  st "3a. 110_substrate_autoconf (substrate plug missing)"; bash "$W/scripts/110_substrate_autoconf.sh" || st "   WARN 110 nonzero"
else
  st "3a. 110 skipped (substrate.h present or 110 not installed)"
fi
if [ -f "$W/scripts/120_reversibility_suite.sh" ] && [ ! -f "$W/results/REVERSIBILITY.json" ]; then
  st "3b. 120_reversibility_suite (reversibility data missing)"; REV_MAXN="${REV_MAXN:-3}" bash "$W/scripts/120_reversibility_suite.sh" || st "   WARN 120 nonzero"
else
  st "3b. 120 skipped (REVERSIBILITY.json present or 120 not installed)"
fi
[ -f "$B/substrate.h" ] || fail "bindings/c has no substrate.h — run 110 first (from the substrate delivery)"

# 4. run the localisation chain
for s in 125_roman_heuristic 126_perso_arabic_heuristic 127_all_script_families 128_langspec_system; do
  st "4. >>> $s"; bash "$W/scripts/$s.sh" || fail "$s"
done

# 5. (re)generate the academic page LAST so it sees every result
st "5. >>> 129_results_page (academic GitHub Pages companion)"; bash "$W/scripts/129_results_page.sh" || fail "129"

# 6. final push
st "6. final commit + push"
cd "$W/repos/romenagri"
git add docs/ results/ filters/ tables/ langspec/ CONTINUITY.md 2>/dev/null
git commit -m "ILM localisation: Roman/Perso-Arabic heuristics, all script families, langspec generator, academic results page (one-shot $(date +%Y-%m-%d))" >>"$L" 2>&1 || true
git push >>"$L" 2>&1 && st "PUSHED" || st "WARN push failed (gh auth login / PAT — see $L)"
rm -rf "$TMP"
st "=== DONE ==="
echo
echo "Enable Pages:  Settings > Pages > Branch main, folder /docs"
echo "Live page:     https://project-ilm.github.io/romenagri/"
echo "Results JSON:  repos/romenagri/results/{ROMAN_HEURISTIC,PERSO_ARABIC,SCRIPT_FAMILIES,LANGSPEC}.json"
