#!/usr/bin/env bash
###############################################################################
#  mirror_forges.sh — break the GitHub single-point-of-failure by mirroring
#  every repo to additional forges across geographies/jurisdictions.
#
#  Model: GitHub stays the working origin; each other forge is a PUSH MIRROR
#  (full --mirror push: all branches, tags, refs). Run on a schedule (cron) or
#  after releases. Idempotent: re-running force-syncs mirrors to match origin.
#
#  Config: a TSV mapping forge -> remote URL base. Create ~/.config/ilm/forges.tsv:
#     # forge        base_url (your namespace)                     enabled(1/0)
#     gitlab         git@gitlab.com:abhishek-ns                    1
#     codeberg       git@codeberg.org:abhishek-ns                  1
#     savannah       ssh://user@git.sv.gnu.org:/srv/git            0
#     openforge      git@openforge.gov.in:abhishek-ns              0
#     sourcehut      git@git.sr.ht:~abhishek-ns                    0
#  (Use SSH deploy keys per forge; never tokens in this file — by-path only.)
#
#  Usage:
#     mirror_forges.sh --org project-ilm                 mirror every repo in an org
#     mirror_forges.sh --repo project-ilm/misty-doi      mirror one repo
#     mirror_forges.sh --org project-ilm --dry-run       show what would push, do nothing
#  © 1993-2026 Abhishek Choudhary. GPL-3.0-or-later.
###############################################################################
set -euo pipefail
CFG="${ILM_FORGES_TSV:-$HOME/.config/ilm/forges.tsv}"
ORGS=(); REPOS=(); DRY=0
while [ $# -gt 0 ]; do case "$1" in
  --org) ORGS+=("$2"); shift 2;;
  --repo) REPOS+=("$2"); shift 2;;
  --dry-run) DRY=1; shift;;
  *) echo "unknown arg: $1"; exit 2;; esac; done

say(){ printf '\n\033[1;33m=== %s ===\033[0m\n' "$*"; }
loud(){ printf '\033[1;36m  %s\033[0m\n' "$*"; }
warn(){ printf '\033[1;31m  !! %s\033[0m\n' "$*"; }

[ -f "$CFG" ] || { warn "no forge config at $CFG — see header for the TSV format."; exit 1; }
command -v git >/dev/null 2>&1 || { warn "git not found"; exit 1; }

# expand orgs -> repos via gh
if [ "${#ORGS[@]}" -gt 0 ]; then
  command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 || { warn "gh not authed for --org"; exit 1; }
  for org in "${ORGS[@]}"; do
    while read -r r; do REPOS+=("$r"); done < <(gh repo list "$org" --limit 200 --json nameWithOwner -q '.[].nameWithOwner')
  done
fi
[ "${#REPOS[@]}" -gt 0 ] || { warn "no repos resolved"; exit 1; }

# read enabled forges
mapfile -t FORGES < <(grep -vE '^\s*#|^\s*$' "$CFG" | awk -F'\t' '$3==1{print $1"\t"$2}')
[ "${#FORGES[@]}" -gt 0 ] || { warn "no enabled forges in $CFG"; exit 1; }
say "FORGES"; for f in "${FORGES[@]}"; do loud "$(echo "$f" | tr '\t' ' ')"; done

WORK="$(mktemp -d)"
say "MIRRORING ${#REPOS[@]} repo(s) -> ${#FORGES[@]} forge(s)"
for repo in "${REPOS[@]}"; do
  name="${repo##*/}"
  loud "── $repo"
  if [ "$DRY" -eq 1 ]; then
    for f in "${FORGES[@]}"; do base="$(echo "$f" | cut -f2)"; loud "   would push -> $base/$name.git"; done
    continue
  fi
  git clone --mirror "https://github.com/$repo.git" "$WORK/$name.git" >/dev/null 2>&1 || { warn "clone failed: $repo"; continue; }
  ( cd "$WORK/$name.git"
    for f in "${FORGES[@]}"; do
      forge="$(echo "$f" | cut -f1)"; base="$(echo "$f" | cut -f2)"; url="$base/$name.git"
      git remote add "$forge" "$url" 2>/dev/null || git remote set-url "$forge" "$url"
      if git push --mirror "$forge" >/dev/null 2>&1; then loud "   ✓ $forge  $url"
      else warn "   ✗ $forge  $url  (create the empty repo / check deploy key)"; fi
    done
  )
  rm -rf "$WORK/$name.git"
done
say "DONE"
loud "Mirrors force-synced to match GitHub. Schedule via cron for continuous safety."
