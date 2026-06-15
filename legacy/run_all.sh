#!/usr/bin/env bash
set -uo pipefail
cd ~/work/11jun
echo "[STATUS] RUN START $(date)" | tee -a logs/run.log
for s in 00_preflight 10_fetch 20_build 30_roundtrip 40_compression 50_licenses_push; do
  echo "──────────────────────────────────────"
  echo "[STATUS] >>> $s"
  bash scripts/$s.sh || { echo "[STATUS] HALTED at $s — see logs/run.log"; exit 1; }
done
echo "[STATUS] RUN COMPLETE $(date)"
echo "[STATUS] results/: "; ls -la results/
