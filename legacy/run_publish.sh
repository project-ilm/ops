#!/usr/bin/env bash
set -uo pipefail
cd ~/work/11jun
for s in 70_brahmi_all 80_bindings 85_langspec_demo 88_site 90_push; do
  echo "──────────────"; echo "[STATUS] >>> $s"
  bash scripts/$s.sh || echo "[STATUS] WARN $s nonzero — see logs/run.log"
done
echo "[STATUS] PUBLISH RUN COMPLETE"
echo "[STATUS] verify: https://github.com/project-ilm/romenagri  +  https://ilm.codes/research/"
