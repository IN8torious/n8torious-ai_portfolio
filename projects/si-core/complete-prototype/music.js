/* ============ MUSICODE — music on hover (Nathan, 2026-10-31 19:59) ============
   D-P2, marked in scope: sound lives on the notes and nowhere else.
   Hover (or tap) a note and it sings its own pitch off the 515 ladder —
   a sine pluck with a triangle harmonic, built per note, never a loop
   and never a soundtrack. The salvage build's law holds: the swarm
   sounds on interaction, and stays silent otherwise. The AudioContext
   wakes on the first touch, per platform rules. */
let AC = null, sungCount = 0, lastFreq = 0, lastSungKey = null, lastSungAt = 0;
function audio(){ if(!AC){ try{ AC = new (window.AudioContext || window.webkitAudioContext)(); }catch(_){ } }
  if(AC && AC.state === 'suspended') AC.resume(); return AC; }
canvas.addEventListener('pointerdown', () => audio());
function soundNote(i){ const n = NOTES[i]; if(!n) return; const ac = audio();
  sungCount++; lastFreq = n.freq; n.pop = .38;
  if(!ac) return; const t0 = ac.currentTime;
  const g = ac.createGain(); g.gain.setValueAtTime(0, t0);
  g.gain.linearRampToValueAtTime(.16, t0 + .008); g.gain.exponentialRampToValueAtTime(.0001, t0 + .7);
  g.connect(ac.destination);
  const o = ac.createOscillator(); o.type = 'sine'; o.frequency.value = n.freq;
  o.connect(g); o.start(t0); o.stop(t0 + .75);
  const g2 = ac.createGain(); g2.gain.setValueAtTime(0, t0);
  g2.gain.linearRampToValueAtTime(.05, t0 + .006); g2.gain.exponentialRampToValueAtTime(.0001, t0 + .35);
  g2.connect(ac.destination);
  const o2 = ac.createOscillator(); o2.type = 'triangle'; o2.frequency.value = n.freq * 2;
  o2.connect(g2); o2.start(t0); o2.stop(t0 + .4); }
window.__soundNote = soundNote;
for(let i = 0; i < NOTES.length; i++) regGaze('note', i, () => NOTES[i].spr.position);
setInterval(()=>{ if(gazeCur && gazeCur.kind === 'note'){ const now = performance.now();
    if(gazeCur.key !== lastSungKey && now - lastSungAt > 650){ lastSungKey = gazeCur.key; lastSungAt = now; soundNote(gazeCur.key); } }
  else lastSungKey = null; }, 130);
window.__music = () => ({ notes: NOTES.length, freq0: NOTES[0].freq, sung: sungCount, lastFreq, ctx: AC ? AC.state : 'not-created',
  movers: [...new Set(NOTES.map(n => n.mover))], rot: NOTES.map(n => +n.spr.material.rotation.toFixed(2)),
  pos: NOTES.slice(0, 10).map(n => n.spr.position.toArray().map(v => +v.toFixed(1))) });
