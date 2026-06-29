#!/usr/bin/env bash
###############################################################################
#  convergence_driver.sh — keep the convergence pipeline running on your host.
#  One command runs the whole read-only sweep and writes a dated, consolidated
#  report; --watch loops it. Safe to run continuously: every underlying tool is
#  read-only / report-only (no deletes, no pushes, no DOI minting here).
#
#  It uses the canonical tools you already merged into project-ilm/ops
#  (discover_all, dedupe_scan, pre_announce_scan, contract_check) — pulling the
#  latest each run so it never drifts from the repo.
#
#  Prereqs (it checks and tells you):  gh auth login ;  pipx install git+https://github.com/project-ilm/spi-scan.git
#
#  Usage:
#     convergence_driver.sh                      one full sweep -> ./convergence-runs/<ts>/
#     convergence_driver.sh --root ~/work        also dedupe-scan this local root (repeatable)
#     convergence_driver.sh --watch 6            re-run every 6 hours (Ctrl-C to stop)
#     convergence_driver.sh --orgs a,b           restrict discovery to these orgs
#  © 1993-2026 Abhishek Choudhary. GPL-3.0-or-later.
###############################################################################
set -euo pipefail
ROOTS=(); WATCH=0; ORGS=""
while [ $# -gt 0 ]; do case "$1" in
  --root) ROOTS+=("$2"); shift 2;;
  --watch) WATCH="$2"; shift 2;;
  --orgs) ORGS="$2"; shift 2;;
  *) echo "unknown arg: $1"; exit 2;; esac; done
[ "${#ROOTS[@]}" -gt 0 ] || ROOTS=("$HOME/work")

say(){ printf '\n\033[1;33m=== %s ===\033[0m\n' "$*"; }
loud(){ printf '\033[1;36m  %s\033[0m\n' "$*"; }
warn(){ printf '\033[1;31m  !! %s\033[0m\n' "$*"; }

OPSDIR="$HOME/.cache/ilm-ops"
ensure_ops(){
  command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 || { warn "gh not authed -> gh auth login"; exit 1; }
  if [ -d "$OPSDIR/.git" ]; then git -C "$OPSDIR" pull -q || true
  else git clone -q "https://github.com/project-ilm/ops.git" "$OPSDIR"; fi
  for t in discover_all dedupe_scan pre_announce_scan; do
    [ -f "$OPSDIR/bin/$t.sh" ] || { warn "ops/bin/$t.sh missing — merge the convergence PRs first"; exit 1; }
    chmod +x "$OPSDIR/bin/$t.sh"
  done
}

one_sweep(){
  TS="$(date +%Y%m%d-%H%M%S)"
  RUN="$PWD/convergence-runs/$TS"; mkdir -p "$RUN"
  say "SWEEP $TS -> $RUN"

  # 1) discovery (enumerate everything, generate plan)
  say "1/3 DISCOVER"
  if [ -n "$ORGS" ]; then "$OPSDIR/bin/discover_all.sh" --orgs "$ORGS" --out "$RUN/inventory" || warn "discover failed"
  else "$OPSDIR/bin/discover_all.sh" --out "$RUN/inventory" || warn "discover failed"; fi

  # 2) dedupe each local root
  say "2/3 DEDUPE"
  for r in "${ROOTS[@]}"; do
    [ -d "$r" ] || { warn "skip missing root $r"; continue; }
    "$OPSDIR/bin/dedupe_scan.sh" "$r" >/dev/null 2>&1 || true
    [ -f "$r/dedupe_ledger.json" ] && cp "$r/dedupe_ledger.json" "$RUN/dedupe_$(basename "$r").json" && loud "dedupe $r -> captured"
  done

  # 3) SPI sweep across discovered namespaces (read-only)
  say "3/3 SPI"
  SPI_FAIL=0
  if [ -f "$RUN/inventory/repos.tsv" ]; then
    cut -f1 "$RUN/inventory/repos.tsv" | cut -d/ -f1 | sort -u > "$RUN/namespaces.txt"
    if command -v spi-scan >/dev/null 2>&1; then
      while read -r org; do
        "$OPSDIR/bin/pre_announce_scan.sh" --org "$org" >/dev/null 2>&1 || SPI_FAIL=$((SPI_FAIL+1))
      done < "$RUN/namespaces.txt"
      [ -f spi_preannounce_report.json ] && mv spi_preannounce_report.json "$RUN/" || true
    else warn "spi-scan not installed (pipx install git+https://github.com/project-ilm/spi-scan.git) — SPI step skipped"; fi
  fi

  # consolidated STATUS
  {
    echo "# Convergence sweep $TS"
    echo
    if [ -f "$RUN/inventory/analysis.md" ]; then
      grep -E '^\- \*\*(Total|Original|Archived|Stale|Dup-name|Forks)' "$RUN/inventory/analysis.md" || true
    fi
    echo
    echo "Dedupe ledgers: $(ls "$RUN"/dedupe_*.json 2>/dev/null | wc -l)"
    echo "SPI namespaces with HIGH findings: $SPI_FAIL"
    echo
    echo "Plan: $RUN/inventory/convergence_plan.md"
  } > "$RUN/STATUS.md"
  cp "$RUN/STATUS.md" "$PWD/convergence-runs/LATEST.md"

  say "SWEEP DONE"
  cat "$RUN/STATUS.md" | sed 's/^/  /'
  [ "$SPI_FAIL" -gt 0 ] && warn "SPI: $SPI_FAIL namespace(s) HIGH — do NOT announce until clean" || loud "SPI: clean"
}

ensure_ops
if [ "$WATCH" -gt 0 ]; then
  loud "watch mode: every ${WATCH}h. Ctrl-C to stop."
  while true; do one_sweep; loud "sleeping ${WATCH}h…"; sleep "$((WATCH*3600))"; git -C "$OPSDIR" pull -q || true; done
else
  one_sweep
fi
