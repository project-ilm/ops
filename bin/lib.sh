#!/usr/bin/env bash
# lib.sh — shared helpers for ILM ops scripts. context: https://ilm.codes/context/
set -euo pipefail
W="${W:-$HOME/work/11jun}"; ORG="${ORG:-project-ilm}"
need(){ command -v "$1" >/dev/null || { echo "missing: $1"; exit 1; }; }
need git; need gh
ilm_repo(){ local n="$1" d="$W/repos/$1"
  [ -d "$d/.git" ] || gh repo clone "$ORG/$n" "$d"
  git -C "$d" fetch origin -q || true
  git -C "$d" checkout main -q 2>/dev/null || git -C "$d" checkout -b main -q
  git -C "$d" pull --ff-only -q || true
  echo "$d"; }
ilm_branch(){ git -C "$1" checkout -B "$2"; }
ilm_pr(){ local d="$1" b="$2" t="$3" body="$4"
  git -C "$d" push -u origin "$b" --force-with-lease
  if gh pr view "$b" -R "$ORG/$(basename "$d")" >/dev/null 2>&1; then
    echo "PR exists: $(gh pr view "$b" -R "$ORG/$(basename "$d")" --json url -q .url)"
  else
    gh pr create -R "$ORG/$(basename "$d")" --base main --head "$b" --title "$t" --body "$body"
  fi
  echo ">> review the diff, then:  gh pr merge $b -R $ORG/$(basename "$d") --squash --delete-branch"; }
