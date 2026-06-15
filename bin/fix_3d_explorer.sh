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
