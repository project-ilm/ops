#!/usr/bin/env bash
###############################################################################
#  publish_paper.sh — the actual end-to-end publishing workflow, built on
#  misty-doi. This is "how people use misty-doi for real work": one command per
#  stage, a per-publication status ledger, from blank metadata to a minted DOI
#  to a submission-ready bundle, with provenance timestamped along the way.
#
#  Each publication lives in ./publications/<slug>/ with a status.json that
#  records every stage. Nothing irreversible runs without an explicit flag.
#
#  Prereq:  pipx install misty-doi   (and ZENODO_TOKEN in env for real publish)
#
#  Usage: publish_paper.sh <command> [args]   (commands below)
#
#  WORKFLOW (run in order, or jump in anywhere):
#     publish_paper.sh new <slug>                 scaffold (misty init + status ledger)
#     publish_paper.sh validate <slug>            misty validate the metadata
#     publish_paper.sh stamp <slug> <file>        OTS-timestamp the manuscript (provenance, pre-DOI)
#     publish_paper.sh doi <slug> <file...> [--dry-run|--sandbox]   mint the DOI (misty publish)
#     publish_paper.sh submission <slug> <venue>  build a submission bundle (transform + cover letter)
#     publish_paper.sh track <slug> <state> [note] submitted|under-review|revisions|accepted|published
#     publish_paper.sh status <slug>              show this publication's full ledger
#     publish_paper.sh list                       all publications + states
#  © 1993-2026 Abhishek Choudhary. GPL-3.0-or-later.
###############################################################################
set -euo pipefail
ROOT="${PUBLISH_ROOT:-./publications}"
CMD="${1:-}"; shift || true
say(){ printf '\n\033[1;33m=== %s ===\033[0m\n' "$*"; }
loud(){ printf '\033[1;36m  %s\033[0m\n' "$*"; }
warn(){ printf '\033[1;31m  !! %s\033[0m\n' "$*"; }
need_misty(){ command -v misty >/dev/null 2>&1 || { warn "misty not installed -> pipx install misty-doi"; exit 1; }; }
dir(){ echo "$ROOT/$1"; }
ledger(){ echo "$ROOT/$1/status.json"; }

j_set(){ # slug key value(json)  -- merge a key into status.json
  python3 - "$(ledger "$1")" "$2" "$3" <<'PY'
import json,sys
p,k,v=sys.argv[1],sys.argv[2],sys.argv[3]
d=json.load(open(p))
try: v=json.loads(v)
except: pass
d[k]=v; json.dump(d,open(p,"w"),indent=2)
PY
}
j_append_event(){ # slug event
  python3 - "$(ledger "$1")" "$2" <<'PY'
import json,sys,datetime
p,e=sys.argv[1],sys.argv[2]
d=json.load(open(p)); d.setdefault("events",[]).append({"at":datetime.datetime.now().isoformat(timespec="seconds"),"event":e})
json.dump(d,open(p,"w"),indent=2)
PY
}

case "$CMD" in
new)
  SLUG="${1:?slug}"; D="$(dir "$SLUG")"
  [ -e "$D" ] && { warn "$D exists"; exit 1; }
  mkdir -p "$D"; need_misty
  ( cd "$D" && misty init -o metadata.json >/dev/null )
  [ -f "$D/manuscript.md" ] || printf '# %s\n\n(manuscript goes here)\n' "$SLUG" > "$D/manuscript.md"
  cat > "$(ledger "$SLUG")" <<JSON
{"slug":"$SLUG","state":"draft","doi":null,"ots":null,"submissions":[],"events":[]}
JSON
  j_append_event "$SLUG" "scaffolded"
  say "NEW PUBLICATION: $SLUG"
  loud "edit:     $D/metadata.json   (or: ai_metadata.py to draft it)"
  loud "manuscript: $D/manuscript.md"
  loud "next:     publish_paper.sh validate $SLUG"
  ;;
validate)
  SLUG="${1:?slug}"; need_misty
  say "VALIDATE $SLUG"
  misty validate -m "$(dir "$SLUG")/metadata.json" && j_append_event "$SLUG" "validated" && loud "metadata OK"
  ;;
stamp)
  SLUG="${1:?slug}"; FILE="${2:?file to stamp}"; need_misty
  say "OTS STAMP $SLUG ($FILE)"
  if misty ots stamp "$FILE" 2>/dev/null; then
    j_set "$SLUG" ots "\"$FILE.ots\""; j_append_event "$SLUG" "ots-stamped $FILE"
    loud "provenance proof: $FILE.ots  (upgrade later: misty ots upgrade $FILE.ots)"
  else warn "OTS calendar unreachable now — re-run when online; the proof can be created later"; fi
  ;;
doi)
  SLUG="${1:?slug}"; shift; need_misty
  DRY=""; FILES=()
  for a in "$@"; do case "$a" in --dry-run) DRY="--dry-run";; --sandbox) DRY="--sandbox";; *) FILES+=("$a");; esac; done
  [ "${#FILES[@]}" -gt 0 ] || { warn "give at least one file to deposit"; exit 1; }
  say "MINT DOI $SLUG ${DRY:-(PRODUCTION)}"
  [ -z "$DRY" ] && [ -z "${ZENODO_TOKEN:-}" ] && { warn "ZENODO_TOKEN unset for production. export it, or pass --dry-run/--sandbox"; exit 1; }
  OUT="$(dir "$SLUG")/doi-result.json"
  misty publish -m "$(dir "$SLUG")/metadata.json" -f "${FILES[@]}" $DRY \
    --package-dir "$(dir "$SLUG")/doi-package" --output "$OUT"
  DOI="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("doi") or "")' "$OUT" 2>/dev/null||true)"
  if [ -n "$DOI" ]; then j_set "$SLUG" doi "\"$DOI\""; j_set "$SLUG" state '"doi-minted"'; j_append_event "$SLUG" "DOI $DOI"; say "DOI: $DOI"; fi
  ;;
submission)
  SLUG="${1:?slug}"; VENUE="${2:?venue}"; need_misty
  say "SUBMISSION BUNDLE $SLUG -> $VENUE"
  B="$(dir "$SLUG")/submission-$(echo "$VENUE"|tr -c 'A-Za-z0-9' _)"; mkdir -p "$B"
  misty transform -m "$(dir "$SLUG")/metadata.json" -o "$B" >/dev/null   # zenodo/datacite/codemeta/CFF
  cp "$(dir "$SLUG")"/manuscript.* "$B/" 2>/dev/null || true
  TITLE="$(python3 -c 'import json;print(json.load(open("'"$(dir "$SLUG")"'/metadata.json")).get("title",""))' 2>/dev/null||echo)"
  cat > "$B/cover_letter.md" <<LET
Dear $VENUE Editor,

Please consider our submission, "$TITLE", for publication in $VENUE.
$( [ -n "$(python3 -c 'import json;print(json.load(open("'"$(ledger "$SLUG")"'")).get("doi") or "")' 2>/dev/null)" ] && echo "A preprint with a permanent DOI is available; details in the metadata." )

Sincerely,
The authors
LET
  python3 - "$(ledger "$SLUG")" "$VENUE" "$B" <<'PY'
import json,sys,datetime
p,v,b=sys.argv[1:4]; d=json.load(open(p))
d.setdefault("submissions",[]).append({"venue":v,"bundle":b,"state":"prepared","at":datetime.datetime.now().isoformat(timespec="seconds")})
json.dump(d,open(p,"w"),indent=2)
PY
  j_append_event "$SLUG" "submission bundle for $VENUE"
  loud "bundle: $B  (manuscript + CFF/datacite/codemeta + cover_letter.md)"
  loud "most journals have no API — submit this bundle manually, then: publish_paper.sh track $SLUG submitted \"$VENUE\""
  ;;
track)
  SLUG="${1:?slug}"; STATE="${2:?state}"; NOTE="${3:-}"
  j_set "$SLUG" state "\"$STATE\""; j_append_event "$SLUG" "track: $STATE${NOTE:+ — $NOTE}"
  say "TRACK $SLUG -> $STATE"; loud "${NOTE:-recorded}"
  ;;
status)
  SLUG="${1:?slug}"
  say "STATUS $SLUG"; python3 -c 'import json,sys;print(json.dumps(json.load(open(sys.argv[1])),indent=2))' "$(ledger "$SLUG")"
  ;;
list)
  say "PUBLICATIONS"
  for s in "$ROOT"/*/status.json; do [ -f "$s" ] || continue
    python3 - "$s" <<'PYL'
import json,sys
d=json.load(open(sys.argv[1]))
print("  %-30s %-14s DOI=%s" % (d["slug"], d["state"], d.get("doi") or "-"))
PYL
  done
  ;;
*) grep '^#' "$0" | sed 's/^#//'; ;;
esac
