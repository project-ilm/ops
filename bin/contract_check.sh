#!/usr/bin/env bash
###############################################################################
#  contract_check.sh — the FPSS gate. Mechanically verifies that an artifact
#  (a shell script, or a bundle directory containing one) conforms to the
#  Contextual Contracts BEFORE it is handed across any boundary (agent->agent,
#  agent->human, human->human). Zero-drift enforcement: every handoff runs this.
#
#  This is DETECTION (the D in FMECA), heuristic not proof. A PASS lowers the
#  probability of a first-pass failure; a FAIL means a known failure mode is
#  present. Exit 0 = gate passed (no FAIL). Exit 1 = gate failed.
#
#  Usage:  contract_check.sh <script.sh | bundle_dir/> [--strict]
#          --strict treats WARN as FAIL.
#  © 1993-2026 Abhishek Choudhary. GPL-3.0-or-later.
###############################################################################
set -uo pipefail

STRICT=0
TARGET=""
for a in "$@"; do case "$a" in
  --strict) STRICT=1;; *) TARGET="$a";; esac; done
[ -n "$TARGET" ] || { echo "usage: contract_check.sh <script.sh|dir> [--strict]"; exit 2; }

# Resolve the primary script to lint
if [ -d "$TARGET" ]; then
  SCRIPT="$(find "$TARGET" -maxdepth 2 -name '*.sh' | grep -Ei 'seed|push|publish|run|release' | head -1)"
  [ -n "$SCRIPT" ] || SCRIPT="$(find "$TARGET" -maxdepth 2 -name '*.sh' | head -1)"
elif [ -f "$TARGET" ]; then
  SCRIPT="$TARGET"
elif [ -f "./$TARGET" ]; then
  SCRIPT="./$TARGET"
else
  SCRIPT="$TARGET"
fi
[ -f "$SCRIPT" ] || { echo "no script found in $TARGET"; exit 2; }

PASS=0; WARN=0; FAIL=0
green(){ printf '  \033[1;32mPASS\033[0m  %-22s %s\n' "$1" "$2"; PASS=$((PASS+1)); }
amber(){ printf '  \033[1;33mWARN\033[0m  %-22s %s\n' "$1" "$2"; WARN=$((WARN+1)); }
red(){   printf '  \033[1;31mFAIL\033[0m  %-22s %s\n' "$1" "$2"; FAIL=$((FAIL+1)); }
# grep the file directly — robust on large bodies (piping a 79 KB var mis-greps)
has(){ grep -Eq "$1" "$SCRIPT"; }

printf '\n\033[1;36m=== CONTRACT CHECK: %s ===\033[0m\n' "$SCRIPT"

# CHK-01  Usability — a usage/help/header doc must exist (the instruction failure)
if has '(--help|usage:|RUN_ME|^#.*[Uu]sage)'; then green "CHK-01 usability" "usage/help present"
else red "CHK-01 usability" "no usage/help/header — caller won't know how to run it"; fi

# CHK-02  Self-containment — writes its own files; must NOT refuse on missing inputs it should write
if has "(<<'?[A-Za-z0-9_]+'?|base64 -d|cat > )"; then
  if has '(MISSING|refusing to proceed|bundle incomplete)'; then
    red "CHK-02 self-contained" "checks for files instead of writing them (the seed v1 bug)"
  else green "CHK-02 self-contained" "reconstructs its own artifacts (heredoc/base64)"; fi
else amber "CHK-02 self-contained" "no heredoc/base64 writers found — verify inputs travel with it"; fi

# CHK-03a Environment — no bare 'pip install' (PEP 668)
if has 'pip[0-9]? +install'; then
  if has '(pipx|--break-system-packages|venv|virtualenv|/bin/pip)'; then
    green "CHK-03 environment" "pip use is PEP 668-safe (pipx/venv/flag)"
  else red "CHK-03 environment" "bare 'pip install' — fails on externally-managed hosts"; fi
else green "CHK-03 environment" "no fragile pip install"; fi

# CHK-03b Tool presence checked before use
if has 'command -v '; then green "CHK-03 tool-probe" "checks tool presence before use"
else amber "CHK-03 tool-probe" "no 'command -v' guard — may fail opaquely if a tool is absent"; fi

# CHK-04  Secrets — no hardcoded credentials
if grep -Eiq '(TOKEN|SECRET|PASSWORD|API_?KEY)\s*=\s*["'"'"']?[A-Za-z0-9_\-]{20,}' "$SCRIPT"; then
  red "CHK-04 secrets" "hardcoded credential-like value present — must be by-path/env only"
else green "CHK-04 secrets" "no hardcoded secrets"; fi

# CHK-05  Safe by default — side effects must be gated, not unconditional
SIDE_RE='(misty +publish[^-]|git +push|gh +pr +create|curl +-[^ ]*X +POST|rm +-rf)'
if has "$SIDE_RE"; then
  # every side-effect should sit under a flag/condition (DO_*/if/case) — heuristic: presence of flag gating
  if has '(DO_[A-Z]+|--publish|--push|--pages|if \[|\$\{[A-Z_]+:-)'; then
    green "CHK-05 safe-default" "side effects appear flag/condition-gated"
  else red "CHK-05 safe-default" "side effects look unconditional — no-flag run must be inert"; fi
else green "CHK-05 safe-default" "no side effects (pure reconstruct/validate)"; fi

# CHK-06  Confirmation before irreversible
if has '(misty +publish[^-]|gh +pr +create|rm +-rf|actions/publish)'; then
  if has '(confirm|read -r|type YES|\[ +"\$[a-zA-Z_]+" += +YES)'; then
    green "CHK-06 confirm-gate" "irreversible action prompts for confirmation"
  else amber "CHK-06 confirm-gate" "irreversible action without explicit confirm prompt"; fi
else green "CHK-06 confirm-gate" "nothing irreversible to gate"; fi

# CHK-07  Idempotency — writes into a named subdir, not generic dirs in CWD
if has 'mkdir -p (docs|scripts|posters|build)( |$)' && ! has 'OUT='; then
  red "CHK-07 idempotency" "mkdir generic dirs in CWD — can clobber caller's tree"
elif has '(OUT=|mktemp -d|/[A-Za-z0-9_-]+/(docs|scripts))'; then
  green "CHK-07 idempotency" "writes into its own named subdir/tmp"
else amber "CHK-07 idempotency" "destination scoping unclear — confirm it won't clobber CWD"; fi

# CHK-08  Loud output — prints URLs/result of mutating ops
if has '(grep -Eo .https://|PR:|DOI :|record_url|page_url)'; then green "CHK-08 loud-output" "prints URLs/results"
elif has "$SIDE_RE"; then amber "CHK-08 loud-output" "mutating ops but no obvious URL echo"
else green "CHK-08 loud-output" "n/a (no mutating ops)"; fi

# CHK-09  Verifiability — dry-run and/or checksums
if has '(--dry-run|dry.?run|sha256|checksum|md5)'; then green "CHK-09 verifiability" "dry-run/checksum present"
else amber "CHK-09 verifiability" "no dry-run/checksum path"; fi

# CHK-10  Fail-fast
if has 'set -[a-z]*e[a-z]*'; then green "CHK-10 fail-fast" "set -e present"
else red "CHK-10 fail-fast" "no 'set -e' — errors won't halt the run"; fi

# Verdict
EFFECTIVE_FAIL=$FAIL
[ "$STRICT" -eq 1 ] && EFFECTIVE_FAIL=$((FAIL+WARN))
printf '\n\033[1;36m--- %d PASS · %d WARN · %d FAIL%s ---\033[0m\n' "$PASS" "$WARN" "$FAIL" "$([ "$STRICT" -eq 1 ] && echo ' (strict)')"
if [ "$EFFECTIVE_FAIL" -eq 0 ]; then
  printf '\033[1;32m  FPSS GATE: PASS\033[0m — cleared for handoff.\n\n'; exit 0
else
  printf '\033[1;31m  FPSS GATE: FAIL\033[0m — fix the FAIL items before handing off.\n\n'; exit 1
fi
