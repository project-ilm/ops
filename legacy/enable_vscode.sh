set -euo pipefail
ILM=~/work/11jun/repos/ilm.codes
VS=~/work/11jun/repos/vscode-ilm
[ -d "$VS/.git" ] || gh repo clone project-ilm/vscode-ilm "$VS"
cd "$VS"; git fetch origin -q || true; git checkout main -q && git pull --ff-only -q || true
git checkout -B ai/vscode-grammar
mkdir -p syntaxes scripts
cat > scripts/gen_grammar.py <<'ILM_GEN_EOF'
#!/usr/bin/env python3
# Generate a TextMate grammar for ILM/Hindawi localized keywords from the keyword-mapping CSVs.
# Context: https://ilm.codes/context/   Usage: gen_grammar.py <ilm-data-dir> <out.tmLanguage.json>
import sys, os, glob, csv, json, re
data_dir, out = sys.argv[1], sys.argv[2]
control, types, other = set(), set(), set()
TYPECAT = {"type","declaration","modifier","storage"}
files = sorted(glob.glob(os.path.join(data_dir, "ilm-*-keywords-mapping.csv")))
langs=set()
for f in files:
    with open(f, encoding="utf-8") as fh:
        rd = csv.reader(fh); header = next(rd, None)
        if not header: continue
        langs.update(c.strip() for c in header[2:] if c.strip())
        for row in rd:
            if not row: continue
            canon = (row[0] or "").strip()
            cat   = (row[1] if len(row)>1 else "").strip().lower()
            toks  = [canon] + [(row[i] if i < len(row) else "").strip() for i in range(2, len(header))]
            bucket = control if cat=="control" else (types if cat in TYPECAT else other)
            for t in toks:
                if t: bucket.add(t)
types -= control; other -= (control|types)
def alt(s):
    toks = sorted({t for t in s if t}, key=lambda x:(-len(x), x))
    return "|".join(re.escape(t) for t in toks)
def rule(scope, s):
    a = alt(s)
    return {"name": scope, "match": r"(?<![\p{L}\p{N}_])(?:%s)(?![\p{L}\p{N}_])" % a} if a else None
patterns = [
    {"name":"comment.line.double-slash.uhin","match":r"//.*$"},
    {"name":"comment.block.uhin","begin":r"/\*","end":r"\*/"},
    {"name":"string.quoted.double.uhin","begin":"\"","end":"\""},
    {"name":"string.quoted.single.uhin","begin":"'","end":"'"},
    {"name":"constant.numeric.uhin","match":r"\b[0-9]+(\.[0-9]+)?\b"},
]
for scope, s in [("keyword.control.uhin",control),("storage.type.uhin",types),("keyword.other.uhin",other)]:
    r = rule(scope, s)
    if r: patterns.append(r)
grammar = {"$schema":"https://raw.githubusercontent.com/martinring/tmlanguage/master/tmlanguage.json",
  "name":"uhin","scopeName":"source.uhin","patterns":patterns,
  "_generated":{"from":"ILM keyword-mapping CSVs","files":[os.path.basename(f) for f in files],
                "languages":sorted(langs),"counts":{"control":len(control),"types":len(types),"other":len(other)}}}
os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
json.dump(grammar, open(out,"w",encoding="utf-8"), ensure_ascii=False, indent=1)
print("wrote", out, "| control",len(control),"types",len(types),"other",len(other),"| langs",len(langs),"| files",len(files))
ILM_GEN_EOF
[ -d "$ILM/data" ] || { echo "ERROR: $ILM/data not found — clone project-ilm/ilm.codes there first"; exit 1; }
python3 scripts/gen_grammar.py "$ILM/data" syntaxes/uhin.tmLanguage.json
cat > language-configuration.json <<'ILM_CFG_EOF'
{ "comments": { "lineComment": "//", "blockComment": ["/*", "*/"] },
  "brackets": [["{","}"],["[","]"],["(",")"]],
  "autoClosingPairs": [["{","}"],["[","]"],["(",")"],["\"","\""],["'","'"]],
  "surroundingPairs": [["{","}"],["[","]"],["(",")"],["\"","\""],["'","'"]] }
ILM_CFG_EOF
cat > package.json <<'ILM_PKG_EOF'
{
  "name": "vscode-ilm",
  "displayName": "ILM / Hindawi (.uhin)",
  "description": "Syntax highlighting for ILM/Hindawi localized-keyword source (.uhin). Grammar generated from the ILM keyword registries (41 languages, 9 host languages). Context: https://ilm.codes/context/",
  "version": "0.1.0",
  "publisher": "project-ilm",
  "license": "GPL-3.0-or-later",
  "repository": { "type": "git", "url": "https://github.com/project-ilm/vscode-ilm" },
  "engines": { "vscode": "^1.70.0" },
  "categories": ["Programming Languages"],
  "scripts": { "gen": "python3 scripts/gen_grammar.py ../ilm.codes/data syntaxes/uhin.tmLanguage.json" },
  "contributes": {
    "languages": [{ "id": "uhin", "aliases": ["ILM","Hindawi","uhin"], "extensions": [".uhin",".hin"], "configuration": "./language-configuration.json" }],
    "grammars": [{ "language": "uhin", "scopeName": "source.uhin", "path": "./syntaxes/uhin.tmLanguage.json" }]
  }
}
ILM_PKG_EOF
cat > README.md <<'ILM_RM_EOF'
# vscode-ilm — highlighting for localized keywords (.uhin)
<!-- ILM context: https://ilm.codes/context/ -->
Grammar is **generated** from the ILM keyword registries (`project-ilm/ilm.codes/data/ilm-*-keywords-mapping.csv`),
so one build highlights every localized keyword across all languages. Regenerate: `npm run gen` (or
`python3 scripts/gen_grammar.py ../ilm.codes/data syntaxes/uhin.tmLanguage.json`).
The same `syntaxes/uhin.tmLanguage.json` is a TextMate grammar — reusable in Sublime Text & Atom; JetBrains/Vim next.
Test: open this folder in VS Code, press **F5** (Extension Development Host), open a `.uhin` file.
GPL-3.0-or-later · © 1993–2026 Abhishek Choudhary.
ILM_RM_EOF
git add -A
git commit -q -m "feat(vscode): generate .uhin grammar from ILM keyword registries (41 langs, 9 host languages); package + config" || echo "(no change)"
git push -u origin ai/vscode-grammar --force-with-lease
gh pr create --base main --head ai/vscode-grammar \
  --title "feat(vscode): data-driven .uhin syntax highlighting" \
  --body "Grammar generated from the keyword registries (control/type/other scopes, unicode-aware boundaries). Test via F5 Extension Development Host. TextMate grammar is portable to Sublime/Atom." 2>/dev/null || echo "PR exists or gh busy"
echo; echo ">> Test:  code $VS   then press F5, open a .uhin file"
echo ">> Merge: gh pr merge ai/vscode-grammar --squash --delete-branch"
