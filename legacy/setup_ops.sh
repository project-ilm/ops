#!/usr/bin/env bash
# setup_ops.sh — bootstrap project-ilm/ops: the auditable home for ILM build/fix/handoff scripts,
# architecture and process. Run once. Re-runnable. Context: https://ilm.codes/context/
# (C) 1993-2026 Abhishek Choudhary, GPL-3.0-or-later
set -euo pipefail
W=~/work/11jun; OPS="$W/ops"; ORG=project-ilm
mkdir -p "$OPS/bin" "$OPS/docs" "$OPS/legacy"
echo "[ops] writing into $OPS"

cat > "$OPS/README.md" <<'EOF'
# ops — Project ILM operations
<!-- context: https://ilm.codes/context/ -->
The auditable home for every build/fix/handoff script, the architecture, and the process. Nothing is run as
loose commands; scripts live here, in git, with history. See `docs/`. Run a task: `bash bin/<task>.sh`.
GPL-3.0-or-later · © 1993-2026 Abhishek Choudhary.
EOF

cat > "$OPS/docs/ARCHITECTURE.md" <<'EOF'
# Architecture — component model
<!-- context: https://ilm.codes/context/ -->
A **node** is the atomic unit: a *script* (ISO 15924) or a *language × paradigm/layer* (ISO 639-3 × L0..L9).
Each node has a **manifest** (status, spec, binding, DOI, refs, install). Everything else is a *view* over the
node registry:
- **registries** (`ilm.codes/registry/*.tsv`) + **per-node manifests** = source of truth.
- **generators** (components): script-table, language-spec (Shaili), binding (per layer), grammar, node-page, DOI minter.
- **views**: the site, the 3D explorer, the specs, the bindings, the DOIs — all generated from the registry.
Invariant: N projection tables + 1 fixed kernel, never N². Generators never edit the kernel.
Repos: `ilm.codes` (site+registry), `romenagri` (kernel), `language-specs` (Shaili deltas), `bindings` (per layer),
`vscode-ilm`/`ilm-lsp` (tooling), `linguistics-labs`, `record` (RTI), `ops` (this), `refs` (external references).
EOF

cat > "$OPS/docs/WORKFLOW.md" <<'EOF'
# Workflow — fork → fix → PR → review → merge
<!-- context: https://ilm.codes/context/ -->
- **Maintainer (write access):** branch on origin `ai/<task>` or `issue/<n>` → PR → review → squash-merge.
- **External / AI collaborator (no write):** **fork** → branch → PR to upstream → review → merge.
- One task = one branch = one small, reviewable diff (patch the files that change, not the repo).
- PRs are created **loudly** (URL printed); never swallow `gh` output.
- Every script that does the work lives in `ops/bin/`, committed before/with the change it makes.
- Merge: `gh pr merge <branch> --squash --delete-branch` **from the correct repo dir**.
EOF

cat > "$OPS/docs/HANDOFF.md" <<'EOF'
# Handoff — to Gemini / ChatGPT / a human
<!-- context: https://ilm.codes/context/ -->
Handing work off = **open an issue**, not a chat dump. The issue carries:
1. **Node + goal** (which script/language×layer, what artifact).
2. **Bootstrap prompt** — a *pointer*, not a payload (the context does not fit in a URL):
   > Continue Project ILM. Build context by reading, in order: https://ilm.codes/context/ ,
   > https://ilm.codes/context/state.json , and the node page <NODE_URL>. Self-check against
   > https://ilm.codes/context/VALIDATION_PROMPT.md . If the artifact exists, surface it; else scaffold it
   > under the Shaili/Charter rules and open a fork→PR.
3. **Check-in contract:** fork `<org>/<repo>`, branch `issue/<n>`, validate, PR to upstream, reference this issue.
The agent *fetches* the URLs to build context — a fresh session, because it won't fit in one prompt.
EOF

cat > "$OPS/docs/SCM.md" <<'EOF'
# SCM — configuration management
<!-- context: https://ilm.codes/context/ -->
Surface = scripts (~226 ISO 15924) × human languages (~7,867 ISO 639-3) × paradigms/layers (L0..L9).
**Do not make a repo per cell.** Data-driven: registries + per-node manifests generate every artifact.
- **Node id:** `script:<Code>` or `lang:<iso639-3>@<layer>` (e.g. `lang:san@L4`).
- **Manifest** (`manifests/<id>.json`): {status, spec, binding, doi, refs[], install, updated}.
- **Versioning:** semver per artifact; the registry pins which manifest version is current.
- **Generated, never hand-forked:** node pages, specs, bindings, grammars, DOIs all rebuild from manifests.
EOF

cat > "$OPS/docs/DOI.md" <<'EOF'
# DOI policy — per artifact, not one blob
<!-- context: https://ilm.codes/context/ -->
Romenagri's DOI covers the **kernel** only. Every **localized language** (Shaili Shraeni and siblings) gets its
**own concept DOI**, version-bumped per release. So does each major artifact class (registries, specs corpus,
posters). A **batch minter** iterates the manifests and mints/updates version DOIs (Zenodo concept→version),
writing the DOI back into each manifest. Metadata cites the host-language standard normatively; we copyright the
**emergent** localized language, never the host standard's text.
EOF

cat > "$OPS/docs/AI_ONBOARDING.md" <<'EOF'
# AI onboarding — how any model (or human) joins
<!-- context: https://ilm.codes/context/ -->
1. Read https://ilm.codes/context/ then `/context/state.json` (machine state + concept hierarchy).
2. Pick a node (3D explorer / `/scripts/` / `/languages/`) or an issue.
3. Self-validate understanding against `/context/VALIDATION_PROMPT.md`.
4. fork → branch `issue/<n>` → patch only what changes → run validators → PR to upstream.
5. **File-header convention:** every source/doc file carries `context: https://ilm.codes/context/` in a comment,
   pointing readers to the concept hierarchy so context is always one hop away.
EOF

cat > "$OPS/bin/lib.sh" <<'EOF'
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
EOF

cat > "$OPS/bin/fix_3d_explorer.sh" <<'EOF'
#!/usr/bin/env bash
# fix_3d_explorer.sh — slow the auto-rotate ~4x; add persistent family-cluster labels; brighten L0-L9.
# Incremental patch to one file, on a branch, with a loud PR. context: https://ilm.codes/context/
set -euo pipefail
source "$(dirname "$0")/lib.sh"
D="$(ilm_repo ilm.codes)"
ilm_branch "$D" ai/fix-3d-spin-labels
python3 - "$D/explore/index.html" <<'PYEOF'
import sys
p=sys.argv[1]; h=open(p,encoding="utf-8").read(); o=h
h=h.replace("if(self.autoRotate && !drag){ az+=0.0016; apply(); }",
            "if(self.autoRotate && !drag){ az+=0.00042; apply(); }")
h=h.replace('x.fillStyle="#aab2da";x.font="bold 40px monospace";x.fillText(txt,6,46);',
            'x.fillStyle="#eef1ff";x.font="bold 44px monospace";x.fillText(txt,6,46);')
h=h.replace("sp.scale.set(40,20,1);return sp;","sp.scale.set(58,29,1);return sp;")
anchor='   var lb=label("L"+i); lb.position.set(0,y,-rr-20); scene.add(lb);}'
block=anchor+'''
 var FAMS=["Brahmic","Perso-Arabic","Alphabetic","CJK / E-Asian","African","American","Ancient","Other"];
 function clusterLabel(txt,col){var cv=document.createElement("canvas");cv.width=512;cv.height=96;
   var x=cv.getContext("2d");x.fillStyle=col;x.font="bold 40px Georgia,serif";x.textAlign="center";x.fillText(txt,256,60);
   var sp=new THREE.Sprite(new THREE.SpriteMaterial({map:new THREE.CanvasTexture(cv),transparent:true,depthTest:false}));
   sp.scale.set(150,28,1);return sp;}
 for(var fI=0;fI<FAMS.length;fI++){var fAng=(fI/8)*Math.PI*2, fR=255, fY=base+STK*0.5;
   var fl=clusterLabel(FAMS[fI],"#d4a843"); fl.position.set(Math.cos(fAng)*fR,fY,Math.sin(fAng)*fR); scene.add(fl);}'''
assert anchor in h, "anchor not found — explore/index.html differs from expected"
h=h.replace(anchor,block,1)
assert h!=o, "no change produced"
open(p,"w",encoding="utf-8").write(h)
print("patched: spin slowed, family labels added, L-labels brightened")
PYEOF
git -C "$D" add explore/index.html
git -C "$D" commit -q -m "fix(explore): slow auto-rotate ~4x; persistent family-cluster labels; brighter L0-L9"
ilm_pr "$D" ai/fix-3d-spin-labels "fix(explore): calmer spin + readable labels" \
"Auto-rotate slowed ~4x (0.0016 -> 0.00042). Added persistent coloured family-cluster labels (Brahmic, Perso-Arabic, ...). Brightened/enlarged L0-L9 axis labels. One-file incremental patch."
EOF

cat > "$OPS/bin/enable_vscode.sh" <<'EOF'
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
EOF

chmod +x "$OPS"/bin/*.sh
cp "$W"/run_*.sh "$W"/*_*.sh "$W"/status.sh "$OPS/legacy/" 2>/dev/null || true

cat > "$OPS/.gitignore" <<'EOF'
*.tar.gz
*.zip
EOF

cd "$OPS"
git init -q -b main 2>/dev/null || true
git add -A
git commit -q -m "ops: architecture/workflow/handoff/SCM/DOI/onboarding docs; lib + fix scripts; legacy audit" || echo "(nothing to commit)"
if ! gh repo view "$ORG/ops" >/dev/null 2>&1; then
  gh repo create "$ORG/ops" --public --source=. --remote=origin --push
else
  git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$ORG/ops.git"
  git push -u origin main
fi
echo
echo "ops ready: https://github.com/$ORG/ops"
echo "Now run the two fixes (each opens a PR you review + merge):"
echo "  bash $OPS/bin/fix_3d_explorer.sh"
echo "  bash $OPS/bin/enable_vscode.sh"
