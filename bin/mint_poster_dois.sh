#!/usr/bin/env bash
# mint_poster_dois.sh — mint one Zenodo DOI per poster/programme image. Idempotent via ops/doi_map.json.
# Run: ZENODO_TOKEN=xxx bash mint_poster_dois.sh   context: https://ilm.codes/context/
set -euo pipefail
: "${ZENODO_TOKEN:?set ZENODO_TOKEN}"
W=~/work/11jun; D="$W/repos/ilm.codes"; API=https://zenodo.org/api; MAP="$W/ops/doi_map.json"
[ -f "$MAP" ] || echo '{}' > "$MAP"
mint(){ local f="$1" title="$2" desc="$3" key; key=$(basename "$f"); [ -f "$f" ] || { echo "miss $f"; return; }
  if python3 -c "import json,sys;sys.exit(0 if '$key' in json.load(open('$MAP')) else 1)"; then echo "skip $key"; return; fi
  local did; did=$(curl -s -H "Authorization: Bearer $ZENODO_TOKEN" -H "Content-Type: application/json" -X POST "$API/deposit/depositions" -d '{}' | python3 -c "import json,sys;print(json.load(sys.stdin)['id'])")
  curl -s -H "Authorization: Bearer $ZENODO_TOKEN" -F file=@"$f" "$API/deposit/depositions/$did/files" >/dev/null
  python3 - "$did" "$title" "$desc" <<PYE
import json,sys,urllib.request
did,title,desc=sys.argv[1],sys.argv[2],sys.argv[3]
md={"metadata":{"title":title,"upload_type":"poster","description":desc,
 "creators":[{"name":"Choudhary, Abhishek"}],"keywords":["Project ILM","Integrative Linguistic Multiscript","linguistic equity","AGI"],
 "access_right":"open","license":"cc-by-4.0"}}
urllib.request.urlopen(urllib.request.Request("$API/deposit/depositions/%s"%did,data=json.dumps(md).encode(),
 headers={"Authorization":"Bearer $ZENODO_TOKEN","Content-Type":"application/json"},method="PUT")).read()
PYE
  local doi; doi=$(curl -s -H "Authorization: Bearer $ZENODO_TOKEN" -X POST "$API/deposit/depositions/$did/actions/publish" | python3 -c "import json,sys;print(json.load(sys.stdin).get('doi',''))")
  python3 -c "import json;d=json.load(open('$MAP'));d['$key']={'doi':'$doi'};json.dump(d,open('$MAP','w'),indent=1)"
  echo "DOI $doi  <-  $key"; }
python3 - "$D/assets/programme/programme.json" <<'PYE' | while IFS=$'\t' read -r f t d; do mint "$f" "$t" "$d"; done
import json,sys,os
root=os.path.dirname(sys.argv[1])
for x in json.load(open(sys.argv[1])): print("%s/%s.jpg\t%s\t%s"%(root,x["slug"],"ILM Programme — "+x["title"],x["abstract"].replace(chr(10)," ")))
PYE
[ -f "$D/posters/manifest.json" ] && python3 - "$D/posters/manifest.json" "$D" <<'PYE' | while IFS=$'\t' read -r f t d; do mint "$f" "$t" "$d"; done
import json,sys,os
m=json.load(open(sys.argv[1])); root=sys.argv[2]; items=m if isinstance(m,list) else m.get("posters",[])
for x in items:
    img=x.get("image") or x.get("file") or ""
    if img: print("%s/%s\t%s\t%s"%(root,img.lstrip('/'),"ILM Poster — "+x.get("title","poster"),x.get("caption",x.get("title",""))))
PYE
echo "doi_map: $MAP"
