#!/usr/bin/env bash
# enable_vscode.sh — (re)generate the .uhin grammar from the keyword registries and open a LOUD PR.
# context: https://ilm.codes/context/
set -euo pipefail
source "$(dirname "$0")/lib.sh"
ILM="$(ilm_repo ilm.codes)"
VS="$(ilm_repo vscode-ilm)"
ilm_branch "$VS" ai/vscode-grammar
mkdir -p "$VS/syntaxes" "$VS/scripts"
cat > "$VS/scripts/gen_grammar.py" <<'PYEOF'
#!/usr/bin/env python3
# context: https://ilm.codes/context/   Usage: gen_grammar.py <ilm-data-dir> <out.tmLanguage.json>
import sys, os, glob, csv, json, re
data_dir, out = sys.argv[1], sys.argv[2]
control, types, other = set(), set(), set(); TYPECAT={"type","declaration","modifier","storage"}
files = sorted(glob.glob(os.path.join(data_dir,"ilm-*-keywords-mapping.csv"))); langs=set()
for f in files:
    with open(f,encoding="utf-8") as fh:
        rd=csv.reader(fh); header=next(rd,None)
        if not header: continue
        langs.update(c.strip() for c in header[2:] if c.strip())
        for row in rd:
            if not row: continue
            canon=(row[0] or "").strip(); cat=(row[1] if len(row)>1 else "").strip().lower()
            toks=[canon]+[(row[i] if i<len(row) else "").strip() for i in range(2,len(header))]
            b=control if cat=="control" else (types if cat in TYPECAT else other)
            for t in toks:
                if t: b.add(t)
types-=control; other-=(control|types)
def alt(s): return "|".join(re.escape(t) for t in sorted({x for x in s if x},key=lambda x:(-len(x),x)))
def rule(scope,s):
    a=alt(s); return {"name":scope,"match":r"(?<![\p{L}\p{N}_])(?:%s)(?![\p{L}\p{N}_])"%a} if a else None
pat=[{"name":"comment.line.double-slash.uhin","match":r"//.*$"},
     {"name":"comment.block.uhin","begin":r"/\*","end":r"\*/"},
     {"name":"string.quoted.double.uhin","begin":"\"","end":"\""},
     {"name":"string.quoted.single.uhin","begin":"'","end":"'"},
     {"name":"constant.numeric.uhin","match":r"\b[0-9]+(\.[0-9]+)?\b"}]
for sc,s in [("keyword.control.uhin",control),("storage.type.uhin",types),("keyword.other.uhin",other)]:
    r=rule(sc,s); pat.append(r) if r else None
json.dump({"$schema":"https://raw.githubusercontent.com/martinring/tmlanguage/master/tmlanguage.json",
 "name":"uhin","scopeName":"source.uhin","patterns":pat,
 "_generated":{"languages":sorted(langs),"counts":{"control":len(control),"types":len(types),"other":len(other)}}},
 open(out,"w",encoding="utf-8"),ensure_ascii=False,indent=1)
print("grammar:",len(control),"control",len(types),"types",len(other),"other |",len(langs),"langs")
PYEOF
python3 "$VS/scripts/gen_grammar.py" "$ILM/data" "$VS/syntaxes/uhin.tmLanguage.json"
git -C "$VS" add -A
git -C "$VS" commit -q -m "feat(vscode): regenerate .uhin grammar from keyword registries" || echo "(no change)"
ilm_pr "$VS" ai/vscode-grammar "feat(vscode): data-driven .uhin highlighting" \
"Grammar generated from the ILM keyword registries (control/type/other, unicode-aware boundaries). Test: open in VS Code, press F5, open a .uhin file. TextMate grammar is portable to Sublime/Atom."
