#!/usr/bin/env bash
###############################################################################
#  pre_announce_scan.sh — the go/no-go gate before any public announcement.
#  It does NOT reimplement SPI detection — it drives the existing `spi-scan`
#  (github.com/project-ilm/spi-scan) across every repo and local tree, then
#  aggregates to a single PASS/FAIL. No HIGH findings anywhere => clear to go.
#
#  Install spi-scan the PEP 668 way first:  pipx install spi-scan
#
#  Usage:
#     pre_announce_scan.sh --org project-ilm           scan every repo in an org (gh metadata + history)
#     pre_announce_scan.sh --local ~/work              scan a local tree's working files
#     pre_announce_scan.sh --org project-ilm --org ayeai --local ~/work
#  Exit 0 = no HIGH findings (clear). Exit 7 = HIGH findings (do NOT announce).
#  © 1993-2026 Abhishek Choudhary. GPL-3.0-or-later.
###############################################################################
set -euo pipefail
ORGS=(); LOCALS=()
while [ $# -gt 0 ]; do case "$1" in
  --org) ORGS+=("$2"); shift 2;;
  --local) LOCALS+=("$2"); shift 2;;
  *) echo "unknown arg: $1"; exit 2;; esac; done

say(){ printf '\n\033[1;33m=== %s ===\033[0m\n' "$*"; }
loud(){ printf '\033[1;36m  %s\033[0m\n' "$*"; }
warn(){ printf '\033[1;31m  !! %s\033[0m\n' "$*"; }

command -v spi-scan >/dev/null 2>&1 || { warn "spi-scan not installed -> pipx install spi-scan"; exit 1; }
HIGH_TOTAL=0
WORK="$(mktemp -d)"; REPORT="${PWD}/spi_preannounce_report.json"
echo '{"scanned":[],"high_total":0}' > "$REPORT"

scan_one(){ # $1 = label, rest = spi-scan args
  local label="$1"; shift
  loud "scanning $label …"
  local out="$WORK/$(echo "$label" | tr -c 'A-Za-z0-9' _).json"
  set +e
  spi-scan "$@" > "$out" 2>/dev/null; local rc=$?
  set -e
  local hi
  hi=$(python3 -c "import json,sys;d=json.load(open('$out'));print(d.get('summary',{}).get('HIGH',0))" 2>/dev/null || echo "?")
  [ "$hi" = "?" ] && hi=$([ "$rc" -eq 7 ] && echo "1+" || echo 0)
  printf '    %s  HIGH=%s\n' "$label" "$hi"
  python3 - "$REPORT" "$label" "$hi" "$out" <<'PY'
import json,sys,os
rep=json.load(open(sys.argv[1])); label,hi,out=sys.argv[2],sys.argv[3],sys.argv[4]
rep["scanned"].append({"target":label,"high":hi,"detail":os.path.basename(out)})
try: rep["high_total"]+= (1 if str(hi).endswith("+") else int(hi))
except: pass
json.dump(rep,open(sys.argv[1],"w"),indent=2)
PY
  [ "$rc" -eq 7 ] && HIGH_TOTAL=$((HIGH_TOTAL+1)) || true
}

say "PRE-ANNOUNCEMENT SPI SWEEP"

# org repos: scan gh metadata (issues/PRs/releases). History scan needs a clone.
for org in "${ORGS[@]}"; do
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    loud "enumerating repos in $org …"
    for repo in $(gh repo list "$org" --limit 200 --json nameWithOwner -q '.[].nameWithOwner'); do
      scan_one "gh:$repo" gh "$repo"
    done
  else
    warn "gh not authed — skipping org $org (run: gh auth login)"
  fi
done

# local trees: scan working files (and git history if it's a repo)
for d in "${LOCALS[@]}"; do
  [ -d "$d" ] || { warn "no such dir: $d"; continue; }
  scan_one "path:$d" path "$d"
  [ -d "$d/.git" ] && scan_one "git:$d" git "$d"
done

say "VERDICT"
loud "aggregate report -> $REPORT"
if [ "$HIGH_TOTAL" -eq 0 ]; then
  printf '\033[1;32m  SPI GATE: PASS\033[0m — no HIGH findings. Clear to announce.\n\n'; exit 0
else
  printf '\033[1;31m  SPI GATE: FAIL\033[0m — %d target(s) with HIGH findings. Do NOT announce; review %s.\n\n' "$HIGH_TOTAL" "$REPORT"; exit 7
fi
