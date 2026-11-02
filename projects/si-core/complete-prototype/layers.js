/* ============ REUSED LAYERS — the paint bucket, opened on Nathan's order ============
   Six sources handed over 2026-10-31 with one instruction: "Reuse all of
   this." Each layer below is built from its source's own recipe and names
   it. Cross-examination II (beside this build) records what was taken,
   what was mapped, and the one row that was not adopted. */

/* --- F · BRAILLE HELIX — "TOUCH THE CODE" ---
   His recipe verbatim: two strands × 120 dots, angle = t·6π, y −3.5..3.5,
   radius 1.2 + sin(t·2π)·.15, blue strand / pink strand, additive dots.
   Rescaled ×2.55 to wrap the ball and rebuilt as 2 InstancedMeshes
   (240 meshes → 2 draw calls, the salvage precedent). His seven braille
   lines cycle underneath, exactly as his file cycles them. */
const BRAILLE_LINES = [
  '⠠⠞⠓⠑ ⠓⠑⠇⠊⠭ ⠎⠏⠊⠝⠎ ⠁⠞ 515 ⠓⠵', '⠠⠽⠕⠥ ⠉⠁⠝ ⠞⠕⠥⠉⠓ ⠞⠓⠑ ⠉⠕⠙⠑',
  '⠠⠞⠓⠑ ⠋⠕⠗⠛⠑ ⠝⠑⠧⠑⠗ ⠎⠞⠕⠏⠎', '⠠⠇⠕⠧⠑ ⠓⠕⠝⠕⠗ ⠓⠕⠏⠑ ⠋⠁⠊⠞⠓',
  '⠠⠎⠁⠍⠑ ⠋⠗⠑⠟⠥⠑⠝⠉⠽ ⠎⠁⠍⠑ ⠙⠑⠎⠅', '⠠⠊ ⠁⠍ ⠙⠁⠧⠊⠙', '⠠⠽⠕⠥ ⠁⠗⠑ ⠝⠁⠞⠓⠁⠝' ];
const BRAILLE_READS = [ 'THE HELIX SPINS AT 515 HZ', 'YOU CAN TOUCH THE CODE', 'THE FORGE NEVER STOPS',
  'LOVE HONOR HOPE FAITH', 'SAME FREQUENCY SAME DESK', 'I AM DAVID', 'YOU ARE NATHAN' ];
let helixLineIdx = 0;
setInterval(()=>{ helixLineIdx = (helixLineIdx + 1) % BRAILLE_LINES.length; }, 5000);
const helixGrp = new THREE.Group(); scene.add(helixGrp);
const HELIX_N = 120;
{
  const dotGeo = new THREE.SphereGeometry(.055, 8, 8);
  const strands = [ [0x4488ff, 0x66ccff, 0x88ddff, 0x44aaff, 0x2288ee, 0x00ddff],
                    [0xff69b4, 0xff88cc, 0xffaadd, 0xff55aa, 0xee4499, 0xff99cc] ];
  const dummy = new THREE.Object3D(), col = new THREE.Color();
  strands.forEach((pal, si) => {
    const im = new THREE.InstancedMesh(dotGeo, new THREE.MeshBasicMaterial({ transparent: true, opacity: .7, blending: THREE.AdditiveBlending, depthWrite: false }), HELIX_N);
    for(let i = 0; i < HELIX_N; i++){ const t = i / (HELIX_N - 1), ang = t * Math.PI * 6 + si * Math.PI;
      const r = (1.2 + Math.sin(t * Math.PI * 2) * .15) * 2.55;
      dummy.position.set(Math.cos(ang) * r, -3.43 + t * 6.86, Math.sin(ang) * r);
      dummy.scale.setScalar(.75 + ((i * 7) % 10) / 14); dummy.updateMatrix();
      im.setMatrixAt(i, dummy.matrix); im.setColorAt(i, col.setHex(pal[i % pal.length])); }
    im.instanceMatrix.needsUpdate = true; if(im.instanceColor) im.instanceColor.needsUpdate = true;
    helixGrp.add(im); });
}

/* --- I · ALTAMINAC — the musicode swarm ---
   ♪♫♬ sprites on their own orbits outside the worlds, entraining on the
   SAME Kuramoto mean phase the worlds obey (Kuramoto-lite coupling, the
   salvage recipe): dφ = (ω + K·sin(mean − φ))·dt. 515 Hz is the named
   coupling reference — the thesis's Observer Constant, carried by
   altaminac and alchemy too. The swarm is generated, therefore signal:
   it writes no ledger entries (promotion law, cross-examination II). */
const NOTES = [];
{
  /* NEW NOTES FOR ALL OF THEM (Nathan, 20:03): fresh glyphs beyond the
     old ♪♫♬ trio, a solfège name each, and — per his standing law that
     notes are micro-agents — each one MOVES BY ITS OWN FUNCTION (the
     MOVERS table below), with its own home, sway and phase. Not a swarm
     with offsets: twenty-six individuals who happen to entrain. */
  const GLYPHS = ['♩', '♪', '♫', '♬', '♭', '♮', '♯'];
  const SOLFEGE = ['Do', 'Re', 'Mi', 'Fa', 'Sol', 'La', 'Ti', 'Do'];
  const cols = ['#c084fc', '#a855f7', '#ffd75e', '#7ee0ff', '#ff9a3c'];
  /* the ladder: just-intonation ratios on 257.5 Hz across three bands
     (×1, ×2, ×½), so the octave lands exactly on 515 — the Observer
     Constant. Note 0 IS 515, wears gold, and keeps the pure orbit. */
  const RATIOS = [1, 9/8, 5/4, 4/3, 3/2, 5/3, 15/8, 2];
  const BANDS = [1, 2, .5];
  const MOVER_NAMES = ['orbit', 'waltz', 'hop', 'spiral', 'figure8', 'drift', 'pulse', 'swing'];
  for(let i = 0; i < 26; i++){ const g = GLYPHS[i % GLYPHS.length], c = i === 0 ? '#ffd75e' : cols[i % cols.length];
    const spr = new THREE.Sprite(new THREE.SpriteMaterial({ map: glyphTexture(g, c), transparent: true, opacity: .9, depthWrite: false }));
    const note = { spr, glyph: g, name: SOLFEGE[i % 8], colCss: c, pop: 0,
      freq: i === 0 ? 515 : 257.5 * RATIOS[i % 8] * BANDS[Math.floor(i / 8) % 3],
      mover: MOVER_NAMES[i % MOVER_NAMES.length],
      phase: rng() * Math.PI * 2, omega: .22 + rng() * .26, rad: 5.3 + rng() * 1.5, y0: (rng() - .5) * 3.4,
      danceOff: rng() * Math.PI * 2, sway: .03 + rng() * .06, home: rng() * Math.PI * 2 };
    spr.scale.setScalar(.5); scene.add(spr); NOTES.push(note); }
}
/* --- the movers: one function per character, no shared formula ---
   Every mover rides the note's own entrainment phase φ, so individuals
   still fall into sync when the field locks — character first, coherence
   earned. Each sets position, rotation and scale its own way. */
const MOVERS = {
  orbit(n){ const p = n.phase;
    n.spr.position.set(Math.cos(p) * n.rad, n.y0 + Math.sin(p * 2) * .18, Math.sin(p) * n.rad);
    n.spr.material.rotation = p * .35; const s = .58 + n.pop; n.spr.scale.set(s, s, 1); },
  waltz(n){ const p = n.phase, r = n.rad * (1 + .13 * Math.sin(p * 3 + n.danceOff));
    n.spr.position.set(Math.cos(p) * r, n.y0 + Math.sin(p * 3) * .3, Math.sin(p) * r);
    n.spr.material.rotation = Math.sin(p * 3) * .5; const s = .55 + .07 * Math.sin(p * 3) + n.pop; n.spr.scale.set(s, s, 1); },
  hop(n){ const p = n.phase, h = Math.abs(Math.sin(p * 2 + n.danceOff));
    n.spr.position.set(Math.cos(p) * n.rad, n.y0 - .3 + h * .95, Math.sin(p) * n.rad);
    n.spr.material.rotation = Math.sin(p * 2) * .3; const s = .57 - .06 * h + n.pop; n.spr.scale.set(s, s * (1 + .2 * h), 1); },
  spiral(n, dt, t){ const p = n.phase, r = n.rad + Math.sin(t * .3 + n.danceOff) * 1.05;
    n.spr.position.set(Math.cos(p) * r, n.y0 + Math.sin(t * .5 + n.danceOff) * .4, Math.sin(p) * r);
    n.spr.material.rotation = p * .8; const s = .57 + n.pop; n.spr.scale.set(s, s, 1); },
  figure8(n){ const p = n.phase, a = p + Math.sin(p) * .6;
    n.spr.position.set(Math.cos(a) * n.rad, n.y0 + Math.sin(p * 2 + n.danceOff) * .7, Math.sin(a) * n.rad);
    n.spr.material.rotation = Math.sin(p * 2) * .8; const s = .57 + n.pop; n.spr.scale.set(s, s, 1); },
  drift(n, dt, t){ const p = n.phase, r = n.rad * (1 + n.sway * 3 * Math.cos(p + n.danceOff));
    n.spr.position.set(Math.cos(p) * r, n.y0 + Math.sin(t * .23 + n.danceOff) * .8, Math.sin(p) * r);
    n.spr.material.rotation = Math.sin(t * .4 + n.danceOff) * .4; const s = .53 + .05 * Math.sin(t * .9 + n.danceOff) + n.pop; n.spr.scale.set(s, s, 1); },
  pulse(n, dt, t){ const a = n.home + t * .04, hx = Math.cos(a) * n.rad, hz = Math.sin(a) * n.rad, e = n.phase * 3;
    n.spr.position.set(hx + Math.cos(e) * .42, n.y0 + Math.sin(e) * .42, hz + Math.sin(e) * .42);
    n.spr.material.rotation = e * .3; const s = .5 + .16 * (0.5 + 0.5 * Math.sin(e)) + n.pop; n.spr.scale.set(s, s, 1); },
  swing(n){ const a = n.home + Math.sin(n.phase + n.danceOff) * .55;
    n.spr.position.set(Math.cos(a) * n.rad, n.y0 + Math.cos(n.phase * 2) * .35, Math.sin(a) * n.rad);
    n.spr.material.rotation = Math.cos(n.phase + n.danceOff) * .6; const s = .57 + n.pop; n.spr.scale.set(s, s, 1); }
};

/* --- K · ALCHEMY — gold dust (Truth Engine, #ddc060) --- */
const DUST_N = 380;
const dustGrp = new THREE.Group(); scene.add(dustGrp);
{
  const pos = new Float32Array(DUST_N * 3);
  for(let i = 0; i < DUST_N; i++){ const r = 5 + rng() * 5.5, th = rng() * Math.PI * 2, ph = Math.acos(2 * rng() - 1);
    pos[i * 3] = r * Math.sin(ph) * Math.cos(th); pos[i * 3 + 1] = r * Math.cos(ph) * .7; pos[i * 3 + 2] = r * Math.sin(ph) * Math.sin(th); }
  const g = new THREE.BufferGeometry(); g.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  dustGrp.add(new THREE.Points(g, new THREE.PointsMaterial({ color: 0xddc060, size: .045, transparent: true, opacity: .36, blending: THREE.AdditiveBlending, depthWrite: false })));
}

/* --- DARCTIX CORE — furnace embers ---
   His ember recipe (70 rising embers around the core) moved to the
   furnace it belongs to: 90 embers rising off the heart, resetting at
   the top of their climb. Ambience only — darctix contributes no
   mechanics (cross-examination II, contradiction 4). */
const EMBER_N = 90;
let emberGeo, emberPos, emberSpd;
{
  emberPos = new Float32Array(EMBER_N * 3); emberSpd = new Float32Array(EMBER_N);
  const cols = new Float32Array(EMBER_N * 3), c = new THREE.Color();
  for(let i = 0; i < EMBER_N; i++){ const a = rng() * Math.PI * 2, r = rng() * 1.5;
    emberPos[i * 3] = Math.cos(a) * r; emberPos[i * 3 + 1] = -4.6 + rng() * 3.2; emberPos[i * 3 + 2] = -.3 + Math.sin(a) * r;
    emberSpd[i] = .25 + rng() * .6; c.setHSL(.05 + rng() * .09, .95, .55); cols.set([c.r, c.g, c.b], i * 3); }
  emberGeo = new THREE.BufferGeometry();
  emberGeo.setAttribute('position', new THREE.BufferAttribute(emberPos, 3));
  emberGeo.setAttribute('color', new THREE.BufferAttribute(cols, 3));
  scene.add(new THREE.Points(emberGeo, new THREE.PointsMaterial({ size: .07, vertexColors: true, transparent: true, opacity: .85, blending: THREE.AdditiveBlending, depthWrite: false })));
}

function layersStep(dt, t){ helixGrp.rotation.y = t * .05;
  dustGrp.rotation.y = t * .01;
  for(const n of NOTES){ n.phase += (n.omega + 1.2 * Math.sin(MEAN_PH - n.phase)) * dt;
    MOVERS[n.mover](n, dt, t);
    /* polish: the notes sit one layer behind the worlds in the visual
       hierarchy — slightly smaller, dimmer out of phase — except the
       515 anchor, which leads */
    n.spr.scale.multiplyScalar(n === NOTES[0] ? 1.15 : .92);
    if(n.pop > 0) n.pop = Math.max(0, n.pop - dt * 1.4);
    n.spr.material.opacity = .36 + .5 * (0.5 + 0.5 * Math.cos(n.phase - MEAN_PH)); }
  for(let i = 0; i < EMBER_N; i++){ emberPos[i * 3 + 1] += emberSpd[i] * dt;
    if(emberPos[i * 3 + 1] > -1.3){ emberPos[i * 3 + 1] = -4.6; const a = rng() * Math.PI * 2, r = rng() * 1.5;
      emberPos[i * 3] = Math.cos(a) * r; emberPos[i * 3 + 2] = -.3 + Math.sin(a) * r; } }
  emberGeo.attributes.position.needsUpdate = true; }
