#!/usr/bin/env bash
###############################################################################
#  patent_track.sh — the patent workflow as actual tooling. It automates the
#  parts that should be automated — PROVENANCE (a cryptographic, dated proof of
#  invention) and STATE TRACKING — and deliberately stops at filing, which stays
#  a human + counsel decision. This is how an independent inventor uses the
#  toolchain for real patent work without ceding the legal call to a script.
#
#  Each matter lives in ./patents/<slug>/ with matter.json. The OTS proof on the
#  disclosure is the load-bearing artifact: a dated, tamper-evident record of
#  what you invented and when — the thing an office or a court ultimately weighs.
#
#  Prereq:  pipx install misty-doi   (provides `misty ots`)
#
#  Usage: patent_track.sh <command> [args]   (commands below)
#
#  WORKFLOW:
#     patent_track.sh new <slug>                      scaffold (disclosure.md + matter ledger)
#     patent_track.sh disclose <slug>                 OTS-timestamp disclosure.md -> dated proof of invention
#     patent_track.sh priorart <slug> add "<ref>"     record a prior-art reference
#     patent_track.sh priorart <slug> list
#     patent_track.sh state <slug> <state> [note]     drafting|filed|office-action|granted|abandoned
#     patent_track.sh package <slug>                  assemble a filing-ready bundle for counsel
#     patent_track.sh status <slug> | list
#  © 1993-2026 Abhishek Choudhary. GPL-3.0-or-later.
###############################################################################
set -euo pipefail
ROOT="${PATENT_ROOT:-./patents}"
CMD="${1:-}"; shift || true
say(){ printf '\n\033[1;33m=== %s ===\033[0m\n' "$*"; }
loud(){ printf '\033[1;36m  %s\033[0m\n' "$*"; }
warn(){ printf '\033[1;31m  !! %s\033[0m\n' "$*"; }
need_misty(){ command -v misty >/dev/null 2>&1 || { warn "misty not installed -> pipx install misty-doi"; exit 1; }; }
M(){ echo "$ROOT/$1/matter.json"; }
ev(){ python3 - "$(M "$1")" "$2" <<'PY'
import json,sys,datetime
p,e=sys.argv[1],sys.argv[2]; d=json.load(open(p))
d.setdefault("events",[]).append({"at":datetime.datetime.now().isoformat(timespec="seconds"),"event":e})
json.dump(d,open(p,"w"),indent=2)
PY
}
set_k(){ python3 - "$(M "$1")" "$2" "$3" <<'PY'
import json,sys
p,k,v=sys.argv[1:4]; d=json.load(open(p))
try: v=json.loads(v)
except: pass
d[k]=v; json.dump(d,open(p,"w"),indent=2)
PY
}

case "$CMD" in
new)
  SLUG="${1:?slug}"; D="$ROOT/$SLUG"; [ -e "$D" ] && { warn "$D exists"; exit 1; }
  mkdir -p "$D"
  cat > "$D/disclosure.md" <<DOC
# Invention Disclosure — $SLUG

## Title

## Field

## Background / problem

## The invention (claims in plain language)

## Drawings / figures

## Inventors
- Abhishek Choudhary

## Date of conception
DOC
  cat > "$(M "$SLUG")" <<JSON
{"slug":"$SLUG","state":"drafting","disclosure_ots":null,"prior_art":[],"filings":[],"events":[]}
JSON
  ev "$SLUG" "matter opened"
  say "NEW PATENT MATTER: $SLUG"
  loud "fill: $D/disclosure.md   then: patent_track.sh disclose $SLUG"
  ;;
disclose)
  SLUG="${1:?slug}"; need_misty; F="$ROOT/$SLUG/disclosure.md"
  say "TIMESTAMP DISCLOSURE $SLUG"
  if misty ots stamp "$F" 2>/dev/null; then
    set_k "$SLUG" disclosure_ots "\"$F.ots\""; ev "$SLUG" "disclosure OTS-stamped (priority-date evidence)"
    loud "dated proof of invention: $F.ots"
    loud "upgrade to a stronger proof later:  misty ots upgrade $F.ots"
  else warn "OTS calendar unreachable now — re-run when online to fix the invention date"; fi
  ;;
priorart)
  SLUG="${1:?slug}"; SUB="${2:?add|list}"
  if [ "$SUB" = add ]; then REF="${3:?reference text}"
    python3 - "$(M "$SLUG")" "$REF" <<'PY'
import json,sys,datetime
p,r=sys.argv[1],sys.argv[2]; d=json.load(open(p))
d.setdefault("prior_art",[]).append({"ref":r,"at":datetime.datetime.now().isoformat(timespec="seconds")})
json.dump(d,open(p,"w"),indent=2)
PY
    ev "$SLUG" "prior-art added"; loud "recorded: $REF"
  else say "PRIOR ART $SLUG"; python3 -c 'import json,sys;[print("  -",a["ref"]) for a in json.load(open(sys.argv[1])).get("prior_art",[])]' "$(M "$SLUG")"; fi
  ;;
state)
  SLUG="${1:?slug}"; ST="${2:?state}"; NOTE="${3:-}"
  set_k "$SLUG" state "\"$ST\""; ev "$SLUG" "state: $ST${NOTE:+ — $NOTE}"
  say "STATE $SLUG -> $ST"; loud "${NOTE:-recorded}"
  [ "$ST" = filed ] && warn "filing is a human + counsel action — this only records that it happened"
  ;;
package)
  SLUG="${1:?slug}"; D="$ROOT/$SLUG"; B="$D/filing-package"; mkdir -p "$B"
  say "FILING PACKAGE $SLUG (for counsel review)"
  cp "$D/disclosure.md" "$B/" 2>/dev/null || true
  [ -f "$D/disclosure.md.ots" ] && cp "$D/disclosure.md.ots" "$B/" || warn "no OTS proof yet — run: patent_track.sh disclose $SLUG"
  python3 -c 'import json,sys;d=json.load(open(sys.argv[1]));open(sys.argv[2]+"/prior_art.md","w").write("# Prior art\n\n"+"\n".join("- "+a["ref"] for a in d.get("prior_art",[])))' "$(M "$SLUG")" "$B"
  cp "$(M "$SLUG")" "$B/matter.json"
  loud "bundle: $B  (disclosure + OTS proof + prior-art + matter ledger)"
  warn "Hand this to qualified counsel. This tool does NOT file with any patent office."
  ;;
status) SLUG="${1:?slug}"; say "STATUS $SLUG"; python3 -c 'import json,sys;print(json.dumps(json.load(open(sys.argv[1])),indent=2))' "$(M "$SLUG")";;
list)
  say "PATENT MATTERS"
  for m in "$ROOT"/*/matter.json; do
    [ -f "$m" ] || continue
    python3 - "$m" <<'PYL'
import json,sys
d=json.load(open(sys.argv[1]))
print("  %-26s %-14s OTS=%s  prior-art=%d" % (d["slug"], d["state"], "yes" if d.get("disclosure_ots") else "no", len(d.get("prior_art",[]))))
PYL
  done
  ;;
*) grep '^#' "$0" | sed 's/^#//';;
esac
