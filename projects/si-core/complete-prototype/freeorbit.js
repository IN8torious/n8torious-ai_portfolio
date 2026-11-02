/* ============ THE AGENTS, VISIBLE — moving parts, not dock rows ============
   Every crew manifest gets a body: a mote on its own inclined orbit
   around the ball, a faint ring for its path, and its name. A mote's
   speed and size rise with its HEAT — the same proposals-per-45s the
   AGENT PHYSICS card counts — so a busy agent visibly hurries. Gaze
   reads an agent like anything else labeled: grants, receipts authored,
   heat, live from the kernel. */
const AGENT_COLORS = { n8_supervisor: 0xf5f5f5, vera_router: 0x57e6ff, corvus_planner: 0xc792ff, archivist: 0xffd75e,
  zenki_guardian: 0x6bffb8, kami_communicator: 0xff7eb6, genki_builder: 0xb6ff5e, sentinel: 0xff4a3d };
const AGENT_MOTES = [];
function agentHeatNow(id){ const now = performance.now(); return (agentHeat[id] || []).filter(t => now - t < 45000).length; }
AGENT_DEFS.forEach((def, i) => { const col = AGENT_COLORS[def.id] || 0xffffff;
  const rad = 5.7 + (i % 3) * .55;
  const q = new THREE.Quaternion().setFromEuler(new THREE.Euler(.5 + (i % 4) * .33, i * 1.13, (i % 3) * .4));
  const u = new THREE.Vector3(1, 0, 0).applyQuaternion(q), v = new THREE.Vector3(0, 0, 1).applyQuaternion(q);
  const ringPts = []; for(let j = 0; j <= 64; j++){ const a = j / 64 * Math.PI * 2;
    ringPts.push(new THREE.Vector3().copy(u).multiplyScalar(Math.cos(a) * rad).addScaledVector(v, Math.sin(a) * rad)); }
  const ring = new THREE.Line(new THREE.BufferGeometry().setFromPoints(ringPts),
    new THREE.LineBasicMaterial({ color: col, transparent: true, opacity: .085 }));
  scene.add(ring);
  const mesh = new THREE.Mesh(new THREE.SphereGeometry(.09, 12, 12),
    new THREE.MeshStandardMaterial({ color: 0x0a0a0c, emissive: col, emissiveIntensity: 1.6, roughness: .4 }));
  const hc = new THREE.Color(col);
  mesh.add(glowSprite(`rgba(${Math.round(hc.r * 255)},${Math.round(hc.g * 255)},${Math.round(hc.b * 255)},.8)`, .85, .4));
  scene.add(mesh); addLabel(mesh, def.name, 'agent', .34, 'agent');
  AGENT_MOTES.push({ def, mesh, u, v, rad, ang: i * .9, speed: .06 + i * .004 });
  regGaze('agent', def.id, () => mesh.position); });
function agentsStep(dt){ for(const m of AGENT_MOTES){ const heat = agentHeatNow(m.def.id);
    m.ang += dt * (m.speed + heat * .02);
    m.mesh.position.copy(m.u).multiplyScalar(Math.cos(m.ang) * m.rad).addScaledVector(m.v, Math.sin(m.ang) * m.rad);
    m.mesh.scale.setScalar(1 + Math.min(3, heat) * .14 + Math.sin(performance.now() * .004 + m.ang) * .05); } }

/* ============ FREE ORBIT ON GAZE — not locked to the core ============
   The Raijin pattern (RavenEYE FLY TO, harakiri-unified): the gaze
   chooses where the orbit lives. Tap anything with a label and the
   orbit target flies to it — the camera keeps its math-only orbit
   (θ/φ, target lerp .15, no OrbitControls), now around that thing,
   tracking it if it moves. Tap the core, or empty space, to come home.
   Drag still orbits; pinch still zooms; both work around any target. */
let orbitFocus = null, focusR = 13.6;
let zoomHold = false;   /* once the user's fingers or wheel own the radius, the focus stops forcing it (Edge report, 2026-10-31: "can't zoom out, just zooms back in") */
const HOME_R = () => (innerWidth / innerHeight < .9 ? 17.5 : 13.6);
const FOCUS_R = { node: 5.4, world: 4.8, state: 5.4, heart: 8, helix: 9, agent: 4.4, note: 4.2 };
function flyTo(c){ if(!c || c.kind === 'core'){ goHome(); return; }
  orbitFocus = c; focusR = FOCUS_R[c.kind] || 6; zoomHold = false;
  const st = $('status'); st.textContent = 'FREE ORBIT · ' + String(c.key).toUpperCase() + ' — tap empty space to return to the core';
  st.style.color = 'var(--cyan)'; }
function goHome(){ orbitFocus = null; zoomHold = false; camT.tx = 0; camT.ty = 0; camT.tz = 0; camT.r = HOME_R();
  const st = $('status'); st.textContent = 'ALL SYSTEMS OPERATIONAL'; st.style.color = ''; }
function gazeOrbitStep(){ if(!orbitFocus) return; if(pinch) zoomHold = true; const p = orbitFocus.getPos();
  camT.tx = p.x; camT.ty = p.y; camT.tz = p.z; if(!zoomHold) camT.r = focusR; }
canvas.addEventListener('wheel', () => { zoomHold = true; }, { passive: true });
let tapDown = null;
canvas.addEventListener('pointerdown', e => { tapDown = tapDown ? null : { x: e.clientX, y: e.clientY, t: performance.now(), id: e.pointerId }; });   /* a second finger cancels the tap — a pinch is not a tap */
canvas.addEventListener('pointerup', e => { if(!tapDown || e.pointerId !== tapDown.id) return;
  const moved = Math.hypot(e.clientX - tapDown.x, e.clientY - tapDown.y), dt = performance.now() - tapDown.t; tapDown = null;
  if(dt > 350 || moved > 9) return;
  let best = null, bd = 48; const v = new THREE.Vector3();
  for(const c of gazeCands){ if(c.kind === 'vector') continue;
    v.copy(c.getPos()).project(camera); if(v.z > 1 || v.z < -1) continue;
    const sx = (v.x * .5 + .5) * innerWidth, sy = (-v.y * .5 + .5) * innerHeight;
    const d = Math.hypot(sx - e.clientX, sy - e.clientY); if(d < bd){ bd = d; best = c; } }
  flyTo(best); if(best && best.kind === 'note' && window.__soundNote) window.__soundNote(best.key); });
window.__orbit = () => ({ focus: orbitFocus ? orbitFocus.kind + ':' + orbitFocus.key : 'core', t: [camT.tx, camT.ty, camT.tz], r: camT.r });
window.__agents = () => AGENT_MOTES.map(m => ({ id: m.def.id, pos: m.mesh.position.toArray(), heat: agentHeatNow(m.def.id) }));
