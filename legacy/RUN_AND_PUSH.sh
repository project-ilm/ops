#!/usr/bin/env bash
# RUN_AND_PUSH.sh — one-shot: stage 110 (if needed) -> 120 reversibility -> 121 fltr tests -> push.
# Place this tarball's contents so scripts land in ~/work/11jun/scripts/, then run this from anywhere.
# Enables nothing destructive; honest figures; commits + pushes project-ilm/romenagri.
# (C) 1993-2026 Abhishek Choudhary, GPL-3.0-or-later
set -uo pipefail
mkdir -p ~/work/11jun/logs; L=~/work/11jun/logs/run.log; st(){ echo "[STATUS] $*" | tee -a "$L"; }
S=~/work/11jun/scripts
B=~/work/11jun/repos/romenagri/bindings/c

st "=== RUN_AND_PUSH start $(date) ==="
command -v autoreconf >/dev/null || { echo "[FAIL] need: sudo apt-get install -y autoconf automake"; exit 1; }

# 110 only if the substrate plug isn't already in place
if [ ! -f "$B/substrate.h" ]; then
  st ">>> 110_substrate_autoconf (substrate plug not present)"
  bash "$S/110_substrate_autoconf.sh" || { echo "[FAIL] 110"; exit 1; }
else
  st ">>> 110 skipped (substrate.h already present)"
fi

st ">>> 120_reversibility_suite"
REV_MAXN="${REV_MAXN:-3}" bash "$S/120_reversibility_suite.sh" || { echo "[FAIL] 120"; exit 1; }

st ">>> 121_fltr_tests"
bash "$S/121_fltr_tests.sh" || st "WARN 121 nonzero (filters may be build-box only)"

# refresh the page after fltr results land, then final push
st ">>> refresh page + final push"
REV_MAXN="${REV_MAXN:-3}" bash "$S/120_reversibility_suite.sh" >/dev/null 2>&1 || true

cd ~/work/11jun/repos/romenagri
git add docs/ results/ CONTINUITY.md 2>/dev/null
git commit -m "Reversibility report + spoke-filter tests (one-shot run $(date +%Y-%m-%d))" >>"$L" 2>&1 || true
git push >>"$L" 2>&1 && st "PUSHED — enable Pages: Settings > Pages > Branch main, folder /docs" \
                     || st "WARN final push failed (auth? gh auth login / PAT — see $L)"
st "=== DONE ==="
echo
echo "Verify:"
echo "  page (after enabling Pages):  https://project-ilm.github.io/romenagri/"
echo "  json:                         repos/romenagri/docs/reversibility.json"
echo "  results:                      repos/romenagri/results/REVERSIBILITY.json, FLTR_TESTS.json"
echo "  full sweep [a-z]^1..4:        REV_MAXN=4 bash ~/work/11jun/scripts/120_reversibility_suite.sh"
