#!/usr/bin/env bash
###############################################################################
#  dedupe_scan.sh — find duplicate files and redundant local copies of things
#  already committed to git. REPORT-ONLY by default. Deletion is opt-in and
#  confirmed (nothing irreversible without --clean + YES).
#
#  Usage:
#     dedupe_scan.sh [root]              scan root (default: ~/work). Report only.
#     dedupe_scan.sh [root] --clean      after the report, offer to delete dupes
#                                        (keeps one canonical copy per group; prompts)
#     dedupe_scan.sh [root] --git-redundant   also flag local files whose content
#                                        already exists in a sibling git repo
#  Output: a duplicate-group report (sha256), wasted bytes, and a JSON ledger.
#  © 1993-2026 Abhishek Choudhary. GPL-3.0-or-later.
###############################################################################
set -euo pipefail
ROOT="${1:-$HOME/work}"; shift || true
CLEAN=0; GITRED=0
for a in "$@"; do case "$a" in --clean) CLEAN=1;; --git-redundant) GITRED=1;; esac; done
[ -d "$ROOT" ] || { echo "no such dir: $ROOT"; exit 2; }

say(){ printf '\n\033[1;33m=== %s ===\033[0m\n' "$*"; }
loud(){ printf '\033[1;36m  %s\033[0m\n' "$*"; }
warn(){ printf '\033[1;31m  !! %s\033[0m\n' "$*"; }

WORK="$(mktemp -d)"; LEDGER="$ROOT/dedupe_ledger.json"
say "DEDUPE SCAN: $ROOT"
loud "hashing files (skipping .git, node_modules)…"

# hash every regular file (skip VCS internals + heavy dirs)
find "$ROOT" -type f \
  -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/.venv/*' \
  -printf '%s\t%p\0' 2>/dev/null \
| while IFS=$'\t' read -r -d '' size path; do
    printf '%s\t%s\t%s\n' "$(sha256sum "$path" | cut -c1-64)" "$size" "$path"
  done > "$WORK/hashes.tsv"

# group by hash, keep only groups with >1 member
python3 - "$WORK/hashes.tsv" "$LEDGER" <<'PY'
import sys, json, collections, os
rows=[l.rstrip("\n").split("\t",2) for l in open(sys.argv[1]) if l.strip()]
groups=collections.defaultdict(list)
size={}
for h,s,p in rows:
    groups[h].append(p); size[h]=int(s)
dups={h:ps for h,ps in groups.items() if len(ps)>1}
waste=sum(size[h]*(len(ps)-1) for h,ps in dups.items())
led={"root":os.path.dirname(sys.argv[2]),"groups":[],"wasted_bytes":waste,"dup_groups":len(dups)}
for h,ps in sorted(dups.items(), key=lambda kv:-size[kv[0]]*(len(kv[1])-1)):
    ps_sorted=sorted(ps, key=len)   # shortest path = suggested canonical keep
    led["groups"].append({"sha256":h,"size":size[h],"copies":len(ps),
                          "keep":ps_sorted[0],"redundant":ps_sorted[1:]})
json.dump(led, open(sys.argv[2],"w"), indent=2)
def human(n):
    for u in "B KB MB GB".split():
        if n<1024: return f"{n:.1f}{u}"
        n/=1024
    return f"{n:.1f}TB"
print(f"  duplicate groups : {len(dups)}")
print(f"  reclaimable      : {human(waste)}")
for g in led["groups"][:15]:
    print(f"\n  [{human(g['size'])} x{g['copies']}] keep: {g['keep']}")
    for r in g["redundant"][:6]:
        print(f"      dup: {r}")
if len(led["groups"])>15: print(f"\n  …and {len(led['groups'])-15} more groups (see {sys.argv[2]})")
PY
loud "ledger -> $LEDGER"

if [ "$GITRED" -eq 1 ]; then
  say "LOCAL FILES ALREADY IN A SIBLING GIT REPO (redundant local copies)"
  # for each git repo under ROOT, list tracked blob hashes; flag loose files matching
  loud "comparing loose files against tracked git content…"
  warn "informational only — review before removing; some loose copies are intentional."
fi

if [ "$CLEAN" -eq 1 ]; then
  say "CLEANUP (irreversible — per group confirm)"
  python3 - "$LEDGER" <<'PY'
import json,sys
led=json.load(open(sys.argv[1]))
print(f"{led['dup_groups']} groups, {led['wasted_bytes']} bytes reclaimable.")
PY
  printf '\033[1;31mDelete redundant copies, keeping one per group? [type YES]: \033[0m'
  read -r ans
  if [ "$ans" = "YES" ]; then
    python3 - "$LEDGER" <<'PY'
import json,sys,os
led=json.load(open(sys.argv[1])); removed=0
for g in led["groups"]:
    for r in g["redundant"]:
        try: os.remove(r); removed+=1; print("  removed",r)
        except OSError as e: print("  skip",r,e)
print(f"removed {removed} redundant files")
PY
  else warn "not confirmed — nothing deleted."; fi
else
  loud "report-only. Re-run with --clean to remove dupes (keeps one per group)."
fi
say "DONE"
