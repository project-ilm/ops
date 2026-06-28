#!/usr/bin/env bash
###############################################################################
#  discover_all.sh — enumerate EVERY org and repo you can see, find every Pages
#  site, and GENERATE a convergence plan from the real data. Built for scale:
#  100+ orgs, 400-500 repos. Read-only against GitHub; writes only local files.
#
#  Runs on your host (needs gh auth — only you can see your private orgs).
#  Rate-safe: one paginated org call + one repo-list call per org. No per-repo
#  calls. Dependencies: gh + python3 only (no jq).
#
#  Usage:
#     discover_all.sh                 enumerate orgs you belong to + your user
#     discover_all.sh --orgs a,b,c    restrict to these orgs
#     discover_all.sh --out DIR       output dir (default ./ilm-inventory)
#
#  Outputs (the canonical convergence dataset):
#     orgs.tsv  repos.tsv  repos.json  sites.tsv  analysis.md  convergence_plan.md
#  © 1993-2026 Abhishek Choudhary. GPL-3.0-or-later.
###############################################################################
set -euo pipefail
OUT="ilm-inventory"; ONLY=""
while [ $# -gt 0 ]; do case "$1" in
  --out) OUT="$2"; shift 2;;
  --orgs) ONLY="$2"; shift 2;;
  *) echo "unknown arg: $1"; exit 2;; esac; done

say(){ printf '\n\033[1;33m=== %s ===\033[0m\n' "$*"; }
loud(){ printf '\033[1;36m  %s\033[0m\n' "$*"; }
warn(){ printf '\033[1;31m  !! %s\033[0m\n' "$*"; }

command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 || { warn "gh not authenticated -> gh auth login"; exit 1; }
command -v python3 >/dev/null 2>&1 || { warn "python3 required"; exit 1; }
mkdir -p "$OUT"
ME="$(gh api user -q .login)"; loud "authenticated as $ME"

say "1. ENUMERATE ORGS"
: > "$OUT/orgs.tsv"
if [ -n "$ONLY" ]; then echo "$ONLY" | tr ',' '\n' >> "$OUT/orgs.tsv"
else gh api --paginate user/orgs -q '.[].login' >> "$OUT/orgs.tsv" 2>/dev/null || true; fi
echo "$ME" >> "$OUT/orgs.tsv"
sort -u "$OUT/orgs.tsv" -o "$OUT/orgs.tsv"
NORG=$(grep -c . "$OUT/orgs.tsv" || echo 0)
loud "$NORG namespaces (orgs + you)"

say "2. ENUMERATE REPOS (one list call per namespace)"
FIELDS='nameWithOwner,isFork,isPrivate,isArchived,isEmpty,diskUsage,primaryLanguage,pushedAt,description,repositoryTopics,homepageUrl'
: > "$OUT/repos.ndjson"
i=0
while read -r ns; do
  [ -z "$ns" ] && continue
  i=$((i+1)); printf '\r  [%d/%d] %-40s' "$i" "$NORG" "$ns" >&2
  gh repo list "$ns" --limit 1000 --json "$FIELDS" 2>/dev/null \
    | python3 -c 'import json,sys; [print(json.dumps(r)) for r in json.load(sys.stdin)]' >> "$OUT/repos.ndjson" 2>/dev/null || true
done < "$OUT/orgs.tsv"
echo >&2
python3 -c 'import json,sys; print(json.dumps([json.loads(l) for l in open(sys.argv[1]) if l.strip()]))' "$OUT/repos.ndjson" > "$OUT/repos.json"
NREPO=$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))))' "$OUT/repos.json")
loud "$NREPO repos total"

say "3. DERIVE TABLES + 4. ANALYZE + GENERATE PLAN (python, no jq)"
python3 - "$OUT" <<'PY'
import json, sys, collections, datetime, re
out=sys.argv[1]
repos=json.load(open(f"{out}/repos.json"))
n=len(repos)

# ---- derive tables ----
with open(f"{out}/repos.tsv","w") as f:
    for r in repos:
        lang=(r.get("primaryLanguage") or {}).get("name","-")
        f.write("\t".join([r["nameWithOwner"], str(r["isFork"]), str(r["isPrivate"]),
                           str(r["isArchived"]), str(r["isEmpty"]), str(r.get("diskUsage") or 0),
                           lang, r.get("pushedAt") or "-"])+"\n")
sites=[]
for r in repos:
    nm=r["nameWithOwner"]; hp=r.get("homepageUrl") or ""
    if re.search(r"\.github\.io$", nm, re.I) or hp:
        sites.append((nm,hp or "-"))
with open(f"{out}/sites.tsv","w") as f:
    for nm,hp in sites: f.write(f"{nm}\t{hp}\n")

# ---- analyze ----
forks=[r for r in repos if r["isFork"]]
arch=[r for r in repos if r["isArchived"]]
empty=[r for r in repos if r["isEmpty"]]
priv=[r for r in repos if r["isPrivate"]]
own=[r for r in repos if not r["isFork"]]
def norm(nm): return re.sub(r'[^a-z0-9]','', nm.split("/")[-1].lower())
byname=collections.defaultdict(list)
for r in repos: byname[norm(r["nameWithOwner"])].append(r["nameWithOwner"])
dupnames={k:v for k,v in byname.items() if len(v)>1}
langs=collections.Counter(((r.get("primaryLanguage") or {}).get("name","-")) for r in repos)
big=sorted(repos, key=lambda r:-(r.get("diskUsage") or 0))[:15]
def age_days(r):
    p=r.get("pushedAt")
    if not p: return None
    d=datetime.datetime.fromisoformat(p.replace("Z","+00:00"))
    return (datetime.datetime.now(datetime.timezone.utc)-d).days
stale=[r for r in repos if (age_days(r) or 0)>365]
byorg=collections.Counter(r["nameWithOwner"].split("/")[0] for r in repos)
def human(kb):
    kb=kb or 0
    for u in "KB MB GB".split():
        if kb<1024: return f"{kb:.0f}{u}"
        kb/=1024
    return f"{kb:.0f}TB"

A=["# Inventory Analysis\n",
   f"- **Total repos:** {n} across {len(byorg)} namespaces",
   f"- **Original (non-fork):** {len(own)}   **Forks:** {len(forks)}",
   f"- **Archived:** {len(arch)}   **Empty:** {len(empty)}   **Private:** {len(priv)}",
   f"- **Stale (>1y):** {len(stale)}   **Dup-name groups:** {len(dupnames)}   **Site candidates:** {len(sites)}\n",
   "## Largest namespaces"]
for o,c in byorg.most_common(20): A.append(f"- `{o}` — {c} repos")
A.append("\n## Language spread")
for l,c in langs.most_common(12): A.append(f"- {l}: {c}")
A.append("\n## Size hotspots")
for r in big: A.append(f"- {human(r.get('diskUsage'))}  `{r['nameWithOwner']}`")
A.append("\n## Duplicate / near-duplicate names across namespaces (first-order dedup targets)")
for k,v in list(sorted(dupnames.items(), key=lambda kv:-len(kv[1])))[:50]:
    A.append(f"- **{k}** → {', '.join('`'+x+'`' for x in v)}")
open(f"{out}/analysis.md","w").write("\n".join(A)+"\n")

P=["# Convergence Plan (generated)\n",
   f"Generated from {n} repos across {len(byorg)} namespaces on {datetime.date.today()}. "
   f"Derived from your actual footprint — supersedes any hand-written proposal.\n",
   "## Scale reality",
   f"- {n} repos, {len(byorg)} namespaces, {len(forks)} forks ({100*len(forks)//max(n,1)}%), "
   f"{len(arch)} archived, {len(stale)} stale, {len(dupnames)} name-collision groups.\n",
   "## Step 1 — Triage (mechanical, do first)",
   f"- **Archive candidates:** {len(stale)} stale + {len(empty)} empty. Archive (never delete) to shrink the active surface.",
   f"- **Fork segregation:** tag {len(forks)} forks `upstream-fork` so 'ours vs borrowed' is one query — the biggest single legibility win.",
   f"- **Name collisions:** {len(dupnames)} groups (analysis.md) — choose one canonical each, archive/redirect the rest.\n",
   "## Step 2 — Cluster the originals",
   f"- {len(own)} originals remain after fork segregation. Cluster by topic/language into buckets "
   "(ILM Core / Tooling / Site / Products / NGO); reuse existing `repositoryTopics`, tag the rest.\n",
   "## Step 3 — Sites consolidation",
   f"- {len(sites)} Pages-site candidates (sites.tsv). Choose canonical site(s), archive duplicate sites, "
   "ensure each live one has a CNAME + deploy workflow.\n",
   "## Step 4 — Gate, mirror, announce (in order)",
   "- `pre_announce_scan.sh` over repos.tsv must PASS (no HIGH SPI) before any visibility increase.",
   "- `mirror_forges.sh` looped over repos.tsv → GitLab/Codeberg/Savannah/OpenForge.",
   "- Public announcement only after both.\n",
   "## Feed the existing tools from this dataset",
   "```bash",
   "# SPI gate across every namespace",
   "cut -f1 ilm-inventory/repos.tsv | cut -d/ -f1 | sort -u | while read -r o; do pre_announce_scan.sh --org \"$o\"; done",
   "# mirror every repo",
   "cut -f1 ilm-inventory/repos.tsv | while read -r r; do mirror_forges.sh --repo \"$r\"; done",
   "```"]
open(f"{out}/convergence_plan.md","w").write("\n".join(P)+"\n")
print(f"  {n} repos | {len(forks)} forks | {len(arch)} archived | {len(dupnames)} dup-name groups | {len(sites)} sites")
print(f"  wrote repos.tsv, sites.tsv, analysis.md, convergence_plan.md")
PY

say "DONE"
loud "canonical dataset in ./$OUT/  — read convergence_plan.md (generated from your real footprint)"
