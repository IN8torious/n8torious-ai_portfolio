/* ============ FIELD NOTES — P2.8-A, the amended force law ============
   Nathan's amendment (2026-10-31): notes exert real, formula-counted
   force. Each note is dealt a type and a lineage; its MASS is the
   receipts its lineage has authored (ledger-counted, live) and its
   INFLUENCE RADIUS = 2.2 + 0.25 × mass. The host counts notes within
   radius of the live pollen — the η pattern — and the kernel adds:
   Observation + Creative push, Contradiction drags, Receipt anchors
   (no force: its mass is memory made visible). Trajectory only: field
   force cannot execute, veto, approve, or unhold anything. */
const NOTE_TYPES = ['observation', 'creative', 'contradiction', 'receipt'];
NOTES.forEach((n, i) => { n.type = NOTE_TYPES[i % 4]; n.lineage = AGENT_DEFS[i % AGENT_DEFS.length].id; });
NOTES[0].type = 'receipt'; NOTES[0].lineage = 'archivist';   /* the 515 anchor is a receipt note */
function noteMass(n){ return influenceOf(n.lineage); }
function noteRadius(n){ return 2.2 + .25 * noteMass(n); }
let lastField = { push: 0, drag: 0, anchored: 0, inRange: [] };
function countField(at){ let push = 0, drag = 0, anchored = 0; const inRange = [];
  for(let i = 0; i < NOTES.length; i++){ const n = NOTES[i];
    if(n.spr.position.distanceTo(at) < noteRadius(n)){ inRange.push(i);
      if(n.type === 'observation' || n.type === 'creative') push++;
      else if(n.type === 'contradiction') drag++;
      else anchored++; } }
  return { push, drag, anchored, inRange }; }
function noteFieldStep(){ if(cur && pollen.visible) lastField = countField(pollen.position); return lastField; }
/* the gazed note shows its true influence ring, colored by type */
const TYPE_COLORS = { observation: 0x57e6ff, creative: 0xc792ff, contradiction: 0xff4a3d, receipt: 0xffd75e };
const fieldRing = (() => { const pts = []; for(let j = 0; j <= 48; j++){ const a = j / 48 * Math.PI * 2; pts.push(new THREE.Vector3(Math.cos(a), Math.sin(a), 0)); }
  const l = new THREE.Line(new THREE.BufferGeometry().setFromPoints(pts), new THREE.LineBasicMaterial({ color: 0xffffff, transparent: true, opacity: .5 }));
  l.visible = false; scene.add(l); return l; })();
setInterval(()=>{ if(cur && !heldVisual){ forces = K.forcesFor(cur, ETA, noteFieldStep()); updateDock(); }
  if(gazeCur && gazeCur.kind === 'note'){ const n = NOTES[gazeCur.key];
    fieldRing.visible = true; fieldRing.position.copy(n.spr.position);
    fieldRing.scale.setScalar(noteRadius(n)); fieldRing.lookAt(camera.position);
    fieldRing.material.color.setHex(TYPE_COLORS[n.type]); }
  else fieldRing.visible = false; }, 300);
window.__field = () => ({ ...lastField, types: NOTES.map(n => n.type), masses: NOTES.map(n => noteMass(n)), radii: NOTES.map(n => +noteRadius(n).toFixed(2)) });
window.__fieldAt = i => countField(NOTES[i].spr.position);
