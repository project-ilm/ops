#!/usr/bin/env bash
set -uo pipefail
cd ~/work/11jun
for s in 60_families 65_perso_arabic 66_nw_semitic; do
  echo "──────────────"; echo "[STATUS] >>> $s"
  bash scripts/$s.sh || echo "[STATUS] WARN $s exited nonzero — see logs/run.log"
done
echo "[STATUS] FAMILY SUITE COMPLETE"; ls -la results/FAMILIES/
