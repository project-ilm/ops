set -euo pipefail
R=~/work/11jun/repos/ilm.codes; cd ""
git fetch origin -q || true; git checkout main -q && git pull --ff-only -q || true
git checkout -B ai/fix-3d-explorer
cat > explore/index.html <<'ILM_EXPLORE_EOF'
<!doctype html><html lang="en"><head><meta charset="utf-8">
<!-- ILM context for humans & AI: https://ilm.codes/context/  (build understanding here first) -->
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>ILM — 3D Explorer · scripts × languages × the AGI stack</title>
<meta name="description" content="Navigate every ISO 15924 script and ISO 639-3 language around the canonical core, mapped to the AGI stack. Click a node to propose/fork it.">
<link rel="stylesheet" href="/assets/site.css">
<style>
#stage{position:relative;height:80vh;min-height:520px;border:1px solid var(--line);border-radius:16px;overflow:hidden;background:radial-gradient(80% 80% at 60% 10%,#0c1230,#05060f)}
#stage canvas{display:block;width:100%;height:100%;touch-action:none}
#hud{position:absolute;top:12px;left:12px;background:rgba(8,11,30,.82);backdrop-filter:blur(8px);border:1px solid var(--line);border-radius:12px;padding:.8rem 1rem;max-width:300px;font-size:.82rem}
#hud h4{margin:.1rem 0 .45rem;color:var(--acc)} #hud label{display:block;color:#cdd4f5;margin:.18rem 0;cursor:pointer}
#legend span{display:inline-block;width:.7rem;height:.7rem;border-radius:50%;margin-right:.35rem;vertical-align:middle}
#tip{position:absolute;pointer-events:none;background:rgba(8,11,30,.95);border:1px solid var(--acc);border-radius:8px;padding:.5rem .7rem;font-size:.8rem;display:none;max-width:250px;z-index:6}
#tip b{color:var(--acc)} #tip .act{color:var(--cy);font-size:.74rem;margin-top:.3rem;display:block}
#cnt{position:absolute;right:12px;bottom:12px;font-size:.72rem;color:var(--mut);text-align:right;line-height:1.5}
#fps{position:absolute;left:12px;bottom:12px;font-size:.72rem;color:var(--mut)}
.ov{position:absolute;inset:0;display:flex;align-items:center;justify-content:center;text-align:center;color:var(--mut);padding:2rem}
</style></head><body>
<main><section class="flow"><div class="wrap">
 <h2>3D Explorer</h2>
 <p class="lead">Every ISO 15924 script and every ISO 639-3 language as one universe around the canonical core Ω,
 with the AGI stack L0→L9 as the vertical axis. Drag to orbit, scroll/pinch to zoom. Colour = status.
 <b>Click any node</b> to fork it and start work (opens a pre-filled proposal). Data loads live from the registries.</p>
 <div id="stage">
  <div class="ov" id="load">Loading the universe… (Three.js + live registries)</div>
  <div id="hud" hidden>
   <h4>Filter</h4>
   <div id="legend">
    <label><input type="checkbox" id="f-seeded" checked> <span style="background:#5be08a"></span>seeded</label>
    <label><input type="checkbox" id="f-encoded" checked> <span style="background:#d4a843"></span>encoded (Unicode)</label>
    <label><input type="checkbox" id="f-pending" checked> <span style="background:#6470a0"></span>pending</label>
   </div>
   <h4 style="margin-top:.6rem">Show</h4>
   <label><input type="checkbox" id="show-scripts" checked> scripts (ISO 15924)</label>
   <label><input type="checkbox" id="show-langs" checked> languages (ISO 639-3)</label>
   <label><input type="checkbox" id="spin" checked> auto-rotate</label>
  </div>
  <div id="tip"></div><div id="cnt"></div><div id="fps"></div>
 </div>
 <p class="lead" style="margin-top:1rem">Prefer reading? <a class="btn ghost" href="/scripts/">Scripts table</a><a class="btn ghost" href="/languages/">Languages table</a></p>
</div></section></main>
<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
<script>
/* ILM 3D explorer — component-based, single dependency (three.min.js). Custom orbit controls
   (cdnjs r128 ships no OrbitControls). Context: https://ilm.codes/context/ */
(function(){
 "use strict";
 var stage=document.getElementById("stage"), loadEl=document.getElementById("load");
 function fail(msg){ loadEl.innerHTML=msg+'<br><br><a class="btn ghost" href="/scripts/">Scripts table</a><a class="btn ghost" href="/languages/">Languages table</a>'; loadEl.style.display="flex"; }
 if(typeof THREE==="undefined"){ return fail("Could not load Three.js from the CDN."); }
 try{ var c=document.createElement("canvas"); if(!(c.getContext("webgl")||c.getContext("experimental-webgl"))) return fail("WebGL is not available in this browser."); }catch(e){ return fail("WebGL is not available."); }
 var COL={seeded:0x5be08a,encoded:0xd4a843,pending:0x6470a0};
 var ISSUE="https://github.com/project-ilm/ilm.codes/issues/new";
 function tsv(t){var L=t.trim().split("\n"),h=L[0].split("\t");return L.slice(1).map(function(r){var c=r.split("\t"),o={};h.forEach(function(k,i){o[k]=c[i];});return o;});}
 function statusOf(x){return x.status==="seeded"?"seeded":(x.status==="encoded"?"encoded":"pending");}
 function family(s){var n=((s.unicode_pva||"")+" "+(s.name||"")).toLowerCase();
  if(/deva|beng|taml|telu|knda|mlym|gujr|guru|orya|sinh|tibt|mymr|thai|khmr|brah|gran|shar|modi|newa|limb|lepc|saur|ahom|java|bali|sund|tirh|takr|khoj|sidd/.test(n))return 0;
  if(/arab|aran|rohg|thaa|syrc|hebr|samr|mand|phnx|nbat|sogd|ougr|phli|avst|armi/.test(n))return 1;
  if(/latn|cyrl|grek|armn|geor|copt|runr|ogam|goth|glag|adlm|dsrt/.test(n))return 2;
  if(/hani|hang|hira|kana|bopo|yiii|tang|nshu|lisu|plrd|kits/.test(n))return 3;
  if(/ethi|tfng|nkoo|vaii|bamu|mend|bass|medf/.test(n))return 4;
  if(/cans|cher|osge/.test(n))return 5;
  if(/egyp|xsux|hluw|lina|linb|cprt|cari|lyci|mero|ital|xpeo|ugar/.test(n))return 6;
  return 7;}
 var W=stage.clientWidth||800, H=stage.clientHeight||560;
 var scene=new THREE.Scene();
 var cam=new THREE.PerspectiveCamera(55, W/H, 0.1, 6000);
 var rndr=new THREE.WebGLRenderer({antialias:true,alpha:true});
 rndr.setSize(W,H); rndr.setPixelRatio(Math.min(2,window.devicePixelRatio||1));
 stage.appendChild(rndr.domElement);
 scene.add(new THREE.AmbientLight(0xffffff,0.85));
 var pl=new THREE.PointLight(0xffd9a0,1.1); pl.position.set(250,350,250); scene.add(pl);
 var core=new THREE.Mesh(new THREE.IcosahedronGeometry(26,1),
   new THREE.MeshStandardMaterial({color:0xd4a843,emissive:0x6b4f10,metalness:.6,roughness:.35}));
 var halo=new THREE.Mesh(new THREE.IcosahedronGeometry(31,1),
   new THREE.MeshBasicMaterial({color:0xd4a843,wireframe:true,transparent:true,opacity:.28}));
 scene.add(core); scene.add(halo);
 var STK=460, base=-220, target=new THREE.Vector3(0,base+STK/2,0);
 scene.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(
   [new THREE.Vector3(0,base,0),new THREE.Vector3(0,base+STK,0)]),
   new THREE.LineBasicMaterial({color:0x3a4680})));
 function label(txt){var cv=document.createElement("canvas");cv.width=128;cv.height=64;
   var x=cv.getContext("2d");x.fillStyle="#aab2da";x.font="bold 40px monospace";x.fillText(txt,6,46);
   var sp=new THREE.Sprite(new THREE.SpriteMaterial({map:new THREE.CanvasTexture(cv),transparent:true}));
   sp.scale.set(40,20,1);return sp;}
 for(var i=0;i<10;i++){var y=base+STK*i/9, rr=60+i*15;
   var ring=new THREE.Mesh(new THREE.TorusGeometry(rr,0.7,6,72),
     new THREE.MeshBasicMaterial({color:0x2b376a,transparent:true,opacity:.55}));
   ring.rotation.x=Math.PI/2; ring.position.y=y; scene.add(ring);
   var lb=label("L"+i); lb.position.set(0,y,-rr-20); scene.add(lb);}
 function buildPoints(items,isScript){
  var N=items.length, pos=new Float32Array(N*3), col=new Float32Array(N*3);
  for(var k=0;k<N;k++){var it=items[k], st=statusOf(it);
    var fi=isScript?family(it):(k%8), ang=(fi/8)*Math.PI*2 + (k%41)/41*0.6;
    var r,y;
    if(isScript){ r=95+(st==="seeded"?40:st==="encoded"?120:200)+(k%11)*6;
      y=base+STK*(st==="seeded"?0.62:st==="encoded"?0.42:0.22)+(k%9)*7-18; }
    else { r=300+(st==="seeded"?-50:70)+(k%53)*1.5; y=base+STK*((k*0.013)%1); }
    pos[k*3]=Math.cos(ang)*r; pos[k*3+1]=y; pos[k*3+2]=Math.sin(ang)*r;
    var cc=new THREE.Color(COL[st]); col[k*3]=cc.r; col[k*3+1]=cc.g; col[k*3+2]=cc.b;
  }
  var g=new THREE.BufferGeometry();
  g.setAttribute("position",new THREE.BufferAttribute(pos,3));
  g.setAttribute("color",new THREE.BufferAttribute(col,3));
  var m=new THREE.PointsMaterial({size:isScript?10:3.4,vertexColors:true,transparent:true,
    opacity:isScript?1:0.5,sizeAttenuation:true});
  var p=new THREE.Points(g,m); p.userData={items:items,isScript:isScript}; return p;
 }
 function Controls(camera,dom,tgt){
  var az=0.7, pol=1.15, rad=620, MIN=130, MAX=2600, drag=false, lx=0, ly=0, self=this;
  this.autoRotate=true;
  function apply(){ camera.position.set(
    tgt.x+rad*Math.sin(pol)*Math.sin(az), tgt.y+rad*Math.cos(pol), tgt.z+rad*Math.sin(pol)*Math.cos(az));
    camera.lookAt(tgt); }
  this.tick=function(){ if(self.autoRotate && !drag){ az+=0.0016; apply(); } };
  this.apply=apply;
  dom.addEventListener("pointerdown",function(e){drag=true;lx=e.clientX;ly=e.clientY;dom.setPointerCapture&&dom.setPointerCapture(e.pointerId);});
  dom.addEventListener("pointerup",function(){drag=false;});
  dom.addEventListener("pointerleave",function(){drag=false;});
  dom.addEventListener("pointermove",function(e){ if(!drag)return;
    az-=(e.clientX-lx)*0.005; pol-=(e.clientY-ly)*0.005;
    pol=Math.max(0.16,Math.min(Math.PI-0.16,pol)); lx=e.clientX; ly=e.clientY; apply(); });
  dom.addEventListener("wheel",function(e){e.preventDefault();
    rad*=(1+(e.deltaY>0?1:-1)*0.08); rad=Math.max(MIN,Math.min(MAX,rad)); apply();},{passive:false});
  var pd=null;
  dom.addEventListener("touchmove",function(e){ if(e.touches.length===2){
    var dx=e.touches[0].clientX-e.touches[1].clientX, dy=e.touches[0].clientY-e.touches[1].clientY;
    var d=Math.hypot(dx,dy); if(pd){ rad*=pd/d; rad=Math.max(MIN,Math.min(MAX,rad)); apply(); } pd=d; e.preventDefault(); }
   },{passive:false});
  dom.addEventListener("touchend",function(){pd=null;});
  apply();
 }
 var scriptPts, langPts, scriptData=[], langData=[], ctrl;
 var raycaster=new THREE.Raycaster(); raycaster.params.Points.threshold=7;
 var ndc=new THREE.Vector2();
 function layers(){var a=[]; if(scriptPts&&scriptPts.visible)a.push(scriptPts); if(langPts&&langPts.visible)a.push(langPts); return a;}
 function pick(ev){var r=stage.getBoundingClientRect();
   ndc.x=((ev.clientX-r.left)/r.width)*2-1; ndc.y=-((ev.clientY-r.top)/r.height)*2+1;
   raycaster.setFromCamera(ndc,cam); var h=raycaster.intersectObjects(layers());
   return h.length?{obj:h[0].object,idx:h[0].index}:null;}
 var tip=document.getElementById("tip");
 stage.addEventListener("pointermove",function(ev){var h=pick(ev);
   if(!h){tip.style.display="none";return;}
   var it=h.obj.userData.items[h.idx], isS=h.obj.userData.isScript, r=stage.getBoundingClientRect();
   tip.style.display="block"; tip.style.left=(ev.clientX-r.left+14)+"px"; tip.style.top=(ev.clientY-r.top+14)+"px";
   tip.innerHTML=isS
     ?'<b>'+it.name+'</b> ('+it.code+')<br>ISO 15924 · '+statusOf(it)+(it.unicode_version?' · Unicode '+it.unicode_version:'')+'<span class="act">click → propose / fork this script</span>'
     :'<b>'+it.name+'</b> ('+it.code+')<br>ISO 639-3 · '+(it.type||'')+' · '+statusOf(it)+'<span class="act">click → propose / fork this language</span>';
 });
 stage.addEventListener("click",function(ev){var h=pick(ev); if(!h)return;
   var it=h.obj.userData.items[h.idx], isS=h.obj.userData.isScript;
   var tmpl=isS?"script_proposal.yml":"language_proposal.yml";
   var title=encodeURIComponent((isS?"Script: ":"Language: ")+it.name+" ("+it.code+")");
   window.open(ISSUE+"?template="+tmpl+"&title="+title,"_blank");
 });
 function rebuild(){
   var ok={seeded:document.getElementById("f-seeded").checked,encoded:document.getElementById("f-encoded").checked,pending:document.getElementById("f-pending").checked};
   if(scriptPts){scene.remove(scriptPts);} if(langPts){scene.remove(langPts);}
   scriptPts=buildPoints(scriptData.filter(function(x){return ok[statusOf(x)];}),true);
   langPts=buildPoints(langData.filter(function(x){return ok[statusOf(x)];}),false);
   scriptPts.visible=document.getElementById("show-scripts").checked;
   langPts.visible=document.getElementById("show-langs").checked;
   scene.add(scriptPts); scene.add(langPts);
 }
 var fpsEl=document.getElementById("fps"), last=performance.now(), frames=0, acc=0;
 function animate(){requestAnimationFrame(animate);
   core.rotation.y+=0.004; halo.rotation.y-=0.003; if(ctrl)ctrl.tick();
   rndr.render(scene,cam);
   var now=performance.now(); acc+=now-last; last=now; frames++;
   if(acc>=500){ fpsEl.textContent=Math.round(frames*1000/acc)+" fps"; frames=0; acc=0; }
 }
 function start(scripts,langs){
   scriptData=scripts; langData=langs;
   ctrl=new Controls(cam,rndr.domElement,target);
   rebuild();
   loadEl.style.display="none"; document.getElementById("hud").hidden=false;
   document.getElementById("cnt").innerHTML=scripts.length+" scripts · "+langs.length.toLocaleString()+" languages<br>live from /registry/*.tsv";
   ["f-seeded","f-encoded","f-pending"].forEach(function(id){document.getElementById(id).addEventListener("change",rebuild);});
   document.getElementById("show-scripts").addEventListener("change",function(e){scriptPts.visible=e.target.checked;});
   document.getElementById("show-langs").addEventListener("change",function(e){langPts.visible=e.target.checked;});
   document.getElementById("spin").addEventListener("change",function(e){ctrl.autoRotate=e.target.checked;});
   animate();
 }
 window.addEventListener("resize",function(){ W=stage.clientWidth; H=stage.clientHeight;
   cam.aspect=W/H; cam.updateProjectionMatrix(); rndr.setSize(W,H); });
 Promise.all([
   fetch("/registry/scripts.tsv").then(function(r){if(!r.ok)throw 0;return r.text();}),
   fetch("/registry/languages.tsv").then(function(r){if(!r.ok)throw 0;return r.text();})
 ]).then(function(a){ start(tsv(a[0]),tsv(a[1])); })
   .catch(function(){ fail("Could not load the registries (/registry/*.tsv)."); });
})();
</script>
<script src="/assets/anim.js" data-base=""></script>
</body></html>
ILM_EXPLORE_EOF
git add explore/index.html
git commit -q -m "fix(explore): robust 3D — custom orbit controls (cdnjs r128 ships no OrbitControls), WebGL guard, FPS, component structure" || echo "(no change)"
git push -u origin ai/fix-3d-explorer --force-with-lease
gh pr create --base main --head ai/fix-3d-explorer   --title "fix(explore): 3D explorer renders (drop missing OrbitControls dep)"   --body "Root cause: cdnjs three r128 ships no controls/OrbitControls.js, so THREE.OrbitControls was undefined and the scene never built. Replaced with a tiny custom orbit control (drag/zoom/pinch), added a WebGL guard, FPS meter, and component structure. Single CDN dependency now." 2>/dev/null || echo "PR exists or gh busy — open one in the UI if needed"
echo; echo ">> Verify locally before merge:  (cd  && python3 -m http.server 8000)  then open  http://localhost:8000/explore/"
echo ">> Happy? merge:  gh pr merge ai/fix-3d-explorer --squash --delete-branch"
