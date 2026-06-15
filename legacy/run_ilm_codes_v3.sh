#!/usr/bin/env bash
# run_ilm_codes_v3.sh — decompress ilm_codes_v3.tar.gz, move RTI out, overlay v3, commit + push.
# Place THIS + ilm_codes_v3.tar.gz in ~/work/11jun/, then: bash run_ilm_codes_v3.sh
# (C) 1993-2026 Abhishek Choudhary, GPL-3.0-or-later
set -uo pipefail
W=~/work/11jun; mkdir -p "$W/logs" "$W/seed"; L="$W/logs/run.log"
st(){ echo "[STATUS] $*" | tee -a "$L"; }; fail(){ echo "[FAIL] $*" | tee -a "$L"; exit 1; }
st "=== ILM.codes v3 one-shot $(date) ==="
TB=""; for d in "$(dirname "$0")" "$W" ~/Downloads .; do [ -f "$d/ilm_codes_v3.tar.gz" ] && TB="$d/ilm_codes_v3.tar.gz" && break; done
[ -n "$TB" ] || fail "ilm_codes_v3.tar.gz not found"
st "1. decompress $TB"; TMP="$(mktemp -d)"; tar xzf "$TB" -C "$TMP" || fail "extract"
SRC="$TMP/ilm_codes_v3/site"; [ -d "$SRC" ] || fail "bad layout"
S="$W/repos/ilm.codes"; [ -f "$S/index.html" ] || { st "cloning ilm.codes"; git clone https://github.com/project-ilm/ilm.codes.git "$S" >>"$L" 2>&1 || fail clone; }
st "2. back up home -> index_prev_v3.html"; cp "$S/index.html" "$S/index_prev_v3.html" 2>/dev/null || true
if [ -d "$S/rti" ]; then
  st "3. move RTI out of the site -> $W/seed/record/ (kept for the 'record' repo)"
  mkdir -p "$W/seed/record"; cp -r "$S/rti/." "$W/seed/record/" 2>/dev/null || true
  ( cd "$S" && git rm -r -q rti 2>/dev/null || rm -rf rti )
else st "3. no rti/ in site (already moved)"; fi
# also drop the bundled rti copy into seed/record as a fallback
cp -r "$TMP/ilm_codes_v3/record/." "$W/seed/record/" 2>/dev/null || true
st "4. overlay v3 files"; cp -r "$SRC"/. "$S"/ || fail "overlay"
cp "$TMP/ilm_codes_v3/README.md" "$W/README_ilm_codes_v3.md" 2>/dev/null || true
rm -rf "$TMP"
st "5. sanity"; for f in index.html map.html disclaimers/index.html privacy/index.html security/index.html calculations/index.html sitemap.xml; do [ -f "$S/$f" ] || fail "missing $f"; done
grep -q '<h1>ILM</h1>' "$S/index.html" && st "   hero retitled" || st "   WARN hero title"
[ -d "$S/rti" ] && st "   WARN rti still present" || st "   rti removed from site"
st "6. commit + push"; cd "$S"; git add -A >>"$L" 2>&1
git commit -m "v3: retitle hero (ILM); map.html keyword-localization honesty note; move RTI to separate repo; privacy(DPDP+GDPR)/security/disclaimers; naming, official+disambiguation, ecosystem; support(grants), VYOMA, ILM Institute, history+roadmap, calculations, /fix/ (FIX-BLOCK); SEO (meta/OG/JSON-LD/sitemap/robots)" >>"$L" 2>&1
git push >>"$L" 2>&1 && st "   pushed" || st "   WARN push failed (gh auth login / PAT — see $L)"
st "=== DONE ==="
echo; echo "Next (tools bundle, on your box):"
echo "  bash seed_repos.sh      # creates record (RTI), vscode-ilm, ilm-lsp, language-specs, linguistics-labs"
echo "  ZENODO_TOKEN=… CONCEPT_ID=20651857 bash zenodo_update.sh   # new DOI version"
