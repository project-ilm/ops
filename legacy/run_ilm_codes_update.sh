#!/usr/bin/env bash
# run_ilm_codes_update.sh — ONE-SHOT: decompress ilm_codes_update.tar.gz, install the registry data
# + the site generator, run it (migration banner, /context/, /scripts/, /languages/), commit + push.
# Place THIS file and ilm_codes_update.tar.gz in ~/work/11jun/, then:  bash run_ilm_codes_update.sh
# (C) 1993-2026 Abhishek Choudhary, GPL-3.0-or-later
set -uo pipefail
W=~/work/11jun
mkdir -p "$W/logs" "$W/scripts"; L="$W/logs/run.log"; st(){ echo "[STATUS] $*" | tee -a "$L"; }
fail(){ echo "[FAIL] $*" | tee -a "$L"; exit 1; }
st "=== ILM.codes site update one-shot $(date) ==="

TB=""
for d in "$(dirname "$0")" "$W" ~/Downloads ~/snap/firefox/common/Downloads .; do
  [ -f "$d/ilm_codes_update.tar.gz" ] && TB="$d/ilm_codes_update.tar.gz" && break
done
[ -n "$TB" ] || fail "ilm_codes_update.tar.gz not found (put it beside this script or in ~/work/11jun)"
st "1. decompress $TB"; TMP="$(mktemp -d)"; tar xzf "$TB" -C "$TMP" || fail "tar extract"
SRC="$TMP/ilm_codes_update"; [ -d "$SRC/registry" ] || fail "tarball layout unexpected"

# ensure the ilm.codes repo is present (clone if missing)
S="$W/repos/ilm.codes"; mkdir -p "$W/repos"
if [ ! -f "$S/index.html" ]; then
  st "2. ilm.codes repo missing — cloning"
  git clone https://github.com/project-ilm/ilm.codes.git "$S" >>"$L" 2>&1 || fail "clone ilm.codes"
else st "2. ilm.codes repo present"; fi

st "3. install registry data + generator"
mkdir -p "$S/registry"
cp "$SRC"/registry/*.tsv "$SRC"/registry/summary.json "$S/registry/" || fail "copy registry"
mkdir -p "$W/data"; cp "$SRC"/data/iso15924.txt "$W/data/" 2>/dev/null || true
cp "$SRC"/scripts/130_ilm_codes_site.sh "$W/scripts/"; chmod +x "$W/scripts/130_ilm_codes_site.sh"
cp "$SRC/README.md" "$W/README_ilm_codes_update.md" 2>/dev/null || true

st "4. run the site generator"
bash "$W/scripts/130_ilm_codes_site.sh" || fail "130"
rm -rf "$TMP"
st "=== DONE ==="
echo; echo "Pages already serve from project-ilm/ilm.codes (CNAME=ilm.codes)."
echo "New pages:  /context/  /context/state.json  /scripts/  /languages/  /registry/*.tsv"
echo "When ilmcodes.com / .net are ready: repoint DNS to GitHub Pages + edit the CNAME file."
