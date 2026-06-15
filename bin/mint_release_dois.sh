#!/usr/bin/env bash
# mint_release_dois.sh — one Zenodo DOI per language package + every poster. Idempotent via ops/doi_map.json.
# Token: $ZENODO_TOKEN or ops/.zenodo_token  context: https://ilm.codes/context/
set -euo pipefail
W=~/work/11jun; OPS="$W/ops"; D="$W/repos/ilm.codes"; S="$W/repos/language-specs"; API=https://zenodo.org/api
TOK="${ZENODO_TOKEN:-$(cat "$OPS/.zenodo_token" 2>/dev/null || true)}"; : "${TOK:?set ZENODO_TOKEN or ops/.zenodo_token}"
MAP="$OPS/doi_map.json"; [ -f "$MAP" ] || echo '{}' > "$MAP"
have(){ python3 -c "import json,sys;sys.exit(0 if '$1' in json.load(open('$MAP')) else 1)"; }
rec(){ python3 -c "import json;d=json.load(open('$MAP'));d['$1']={'doi':'$2','title':'''$3''','date':'$(date +%F)'};json.dump(d,open('$MAP','w'),indent=1,ensure_ascii=False)"; }
mint(){ local key="$1" f="$2" title="$3" desc="$4" utype="${5:-poster}"
  [ -f "$f" ] || { echo "miss $f"; return; }; if have "$key"; then echo "skip $key"; return; fi
  local did; did=$(curl -s -H "Authorization: Bearer $TOK" -H "Content-Type: application/json" -X POST "$API/deposit/depositions" -d '{}' | python3 -c "import json,sys;print(json.load(sys.stdin)['id'])")
  curl -s -H "Authorization: Bearer $TOK" -F file=@"$f" "$API/deposit/depositions/$did/files" >/dev/null
  python3 - "$did" "$title" "$desc" "$utype" "$TOK" "$API" <<PYE
import json,sys,urllib.request
did,title,desc,utype,tok,api=sys.argv[1:7]
md={"metadata":{"title":title,"upload_type":utype,"description":desc,"creators":[{"name":"Choudhary, Abhishek"}],
 "keywords":["Project ILM","Integrative Linguistic Multiscript","Shaili","linguistic equity","AGI"],
 "access_right":"open","license":"cc-by-4.0"}}
if utype=="software": md["metadata"]["upload_type"]="software"
urllib.request.urlopen(urllib.request.Request("%s/deposit/depositions/%s"%(api,did),data=json.dumps(md).encode(),
 headers={"Authorization":"Bearer %s"%tok,"Content-Type":"application/json"},method="PUT")).read()
PYE
  local doi; doi=$(curl -s -H "Authorization: Bearer $TOK" -X POST "$API/deposit/depositions/$did/actions/publish" | python3 -c "import json,sys;print(json.load(sys.stdin).get('doi',''))")
  rec "$key" "$doi" "$title"; echo "DOI $doi  <-  $key"; }
# posters: programme + earlier gallery
for f in "$D"/assets/programme/*.jpg "$D"/assets/posters/*; do [ -f "$f" ] || continue
  case "$f" in *.thumb.jpg) continue;; *.json) continue;; esac
  b=$(basename "$f"); mint "poster:$b" "$f" "ILM Poster — ${b%.*}" "Project ILM programme poster." poster; done
# language packages: zip each, one DOI per language
TMP=$(mktemp -d)
for pj in "$S"/packages/*/package.json; do d=$(dirname "$pj"); id=$(basename "$d")
  name=$(python3 -c "import json;print(json.load(open('$pj'))['name'])")
  z="$TMP/$id.zip"; python3 -m zipfile -c "$z" "$d"
  mint "pkg:$id" "$z" "ILM Shaili Package — $name ($id)" "Localized programming-language package (keyword maps, samples, Shaili spec) for $name." software
done
rm -rf "$TMP"; echo "register: $MAP ($(python3 -c "import json;print(len(json.load(open('$MAP'))))") entries)"
