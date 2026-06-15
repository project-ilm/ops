#!/usr/bin/env bash
# run_ilm_codes_futuristic.sh — ONE-SHOT: decompress ilm_codes_futuristic.tar.gz and overlay the
# futuristic site onto repos/ilm.codes/, then commit + push. These are static presentation files
# (not measured results), so no regeneration is needed — just install + push.
# Place THIS file and ilm_codes_futuristic.tar.gz in ~/work/11jun/, then: bash run_ilm_codes_futuristic.sh
# (C) 1993-2026 Abhishek Choudhary, GPL-3.0-or-later
set -uo pipefail
W=~/work/11jun
mkdir -p "$W/logs"; L="$W/logs/run.log"; st(){ echo "[STATUS] $*" | tee -a "$L"; }
fail(){ echo "[FAIL] $*" | tee -a "$L"; exit 1; }
st "=== ILM.codes futuristic rebuild one-shot $(date) ==="

TB=""
for d in "$(dirname "$0")" "$W" ~/Downloads ~/snap/firefox/common/Downloads .; do
  [ -f "$d/ilm_codes_futuristic.tar.gz" ] && TB="$d/ilm_codes_futuristic.tar.gz" && break
done
[ -n "$TB" ] || fail "ilm_codes_futuristic.tar.gz not found (put it beside this script or in ~/work/11jun)"
st "1. decompress $TB"; TMP="$(mktemp -d)"; tar xzf "$TB" -C "$TMP" || fail "tar extract"
SRC="$TMP/ilm_codes_futuristic/site"; [ -d "$SRC" ] || fail "tarball layout unexpected (no site/)"

S="$W/repos/ilm.codes"; mkdir -p "$W/repos"
if [ ! -f "$S/index.html" ]; then
  st "2. ilm.codes repo missing — cloning"
  git clone https://github.com/project-ilm/ilm.codes.git "$S" >>"$L" 2>&1 || fail "clone ilm.codes"
else st "2. ilm.codes repo present"; fi

st "3. back up current index.html -> index_prev.html, then overlay site/"
[ -f "$S/index.html" ] && cp "$S/index.html" "$S/index_prev.html"
# copy overlay (dotfiles too: .github)
cp -r "$SRC"/. "$S"/ || fail "overlay copy"
cp "$TMP/ilm_codes_futuristic/README.md" "$W/README_ilm_codes_futuristic.md" 2>/dev/null || true
rm -rf "$TMP"

st "4. sanity: key pages present"
for f in index.html status.json explore/index.html charter/index.html contribute/index.html posters/index.html context/index.html context/VALIDATION_PROMPT.md assets/site.css assets/anim.js assets/posters/manifest.json; do
  [ -f "$S/$f" ] || fail "missing after overlay: $f"
done
python3 -c "import json;[json.load(open('$S/'+p)) for p in ['status.json','context/state.json','assets/posters/manifest.json']]" 2>/dev/null \
  && st "   JSON valid" || st "   WARN: JSON check skipped/failed"

st "5. commit + push"
cd "$S"
git add -A >>"$L" 2>&1
git commit -m "Futuristic site: animated home + live status dashboard, 3D explorer (scripts x languages x AGI stack), ILM Charter, Contribute (GitHub concepts + AI-help + issue templates), poster gallery (10), rebuilt /context/ + VALIDATION_PROMPT, process docs" >>"$L" 2>&1
git push >>"$L" 2>&1 && st "   pushed" || st "   WARN push failed (auth? gh auth login / PAT — see $L)"
st "=== DONE ==="
echo
echo "Live (already served from project-ilm/ilm.codes, CNAME=ilm.codes):"
echo "  /            futuristic home + live status dashboard"
echo "  /explore/    3D scripts x languages x AGI-stack explorer"
echo "  /charter/    the ILM Charter        /contribute/  GitHub concepts + how-to + AI help"
echo "  /posters/    academic poster gallery (10)"
echo "  /context/    rebuilt context + state.json + VALIDATION_PROMPT.md"
echo "When ilmcodes.com / .net are ready: repoint DNS to GitHub Pages + edit the CNAME file."
