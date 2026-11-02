#!/usr/bin/env python3
"""Fresh assembly: the complete prototype, from the best parts.
Parts are taken deliberately from the verified Ball build (core-lens),
recomposed into a new file with the reused layers as first-class
sections. Proofs are re-earned by test/proto-test.py — assembly does
not inherit them."""
import pathlib, sys

HERE = pathlib.Path(__file__).parent
ball = (HERE.parent / 'core-lens' / 'index.html').read_text()
layers = (HERE / 'layers.js').read_text()
freeorbit = (HERE / 'freeorbit.js').read_text()
music = (HERE / 'music.js').read_text()
field = (HERE / 'field.js').read_text()
src_card = (HERE / 'sources-card.html').read_text()

def cut(text, start_anchor, end_anchor):
    i = text.index(start_anchor)
    j = text.index(end_anchor, i) if end_anchor else len(text)
    return text[i:j]

head = cut(ball, '<!DOCTYPE html>', '/* === SI KERNEL')
kernel_and_scene = cut(ball, '/* === SI KERNEL', '/* ============ KERNEL WIRING')
rest = cut(ball, '/* ============ KERNEL WIRING', None)

# layers become a first-class section: after the Evidence Sky, before the dream pass
dream_anchor = '/* ============ THE DREAM PASS'
i = kernel_and_scene.index(dream_anchor)
kernel_and_scene = kernel_and_scene[:i] + layers + '\n' + kernel_and_scene[i:]

html = head + kernel_and_scene + rest

def patch(old, new, count=1):
    global html
    assert html.count(old) == count, f'anchor x{html.count(old)} (want {count}): {old[:70]!r}'
    html = html.replace(old, new)

# --- identity: this is a new file, and it must look like one ---
patch('<title>SI CORE — THE CORE · ball view</title>', '<title>SI CORE — COMPLETE PROTOTYPE</title>')
patch('THE CORE · ONE RUNTIME, BALL VIEW', 'COMPLETE PROTOTYPE · ONE RUNTIME · BEST OF EVERYTHING')
patch('SI CORE — <em>THE BALL</em>', 'SI CORE — <em>COMPLETE</em>')
patch("""<p>The agentic core as a ball — five primitive nodes on a geodesic lattice,
     every pathway a lattice path. Worlds hop the outer lattice edge to edge;
     refusals fall to the furnace. Drag to orbit · pinch to zoom · tap a node.</p>""",
"""<p>The ball and its lattice worlds, wrapped in the braille helix,
     trailed by singing notes, the crew in orbit. Hover to read inside
     a thing; tap to fly there. Drag to orbit · pinch to zoom.</p>""")

# --- polish pass (2026-10-31, Nathan's call): hierarchy before decoration ---
patch('COMPLETE PROTOTYPE · ONE RUNTIME · BEST OF EVERYTHING', 'COMPLETE PROTOTYPE · ONE RUNTIME')
patch('background:linear-gradient(180deg, rgba(5,6,10,.78) 55%, rgba(5,6,10,0));',
      'background:linear-gradient(180deg, rgba(5,6,10,.9) 52%, rgba(5,6,10,0));')
patch('background:rgba(5,6,10,.42); padding:2px 7px; border-radius:6px; }',
      'background:rgba(5,6,10,.58); padding:2px 7px; border-radius:6px; border:1px solid rgba(232,228,218,.09); box-shadow:0 2px 10px rgba(0,0,0,.35); backdrop-filter:blur(3px); }')
patch('border-left:1px solid rgba(255,74,61,.45);', 'border-left:1px solid rgba(255,74,61,.26);')
patch("#status{ position:fixed; left:16px; bottom:14px; font-size:11px; letter-spacing:.14em; color:var(--lime); z-index:5; pointer-events:none; }",
      "#status{ position:fixed; left:16px; bottom:14px; font-size:11px; letter-spacing:.14em; color:var(--lime); z-index:5; pointer-events:none; padding:5px 9px; border-radius:6px; background:linear-gradient(90deg, rgba(5,6,10,.6), rgba(5,6,10,0)); text-shadow:0 1px 6px #000; }")
patch("gzT.textContent = d.title; gzT.style.color = '#' + d.color.toString(16).padStart(6, '0');",
      "gzT.textContent = d.title; gzT.style.color = '#' + d.color.toString(16).padStart(6, '0'); gazeCard.style.borderColor = '#' + d.color.toString(16).padStart(6, '0') + '59';")
patch("    if(L.kind === 'world' && facing < .02){ L.el.style.display='none'; continue; }",
      "    if(L.kind === 'world' && facing < .02){ L.el.style.display='none'; continue; }\n    if(L.kind === 'agent' && facing < .12){ L.el.style.display='none'; continue; }   /* far-side agents ride as light, like far worlds */")
patch("    if(sm) sm.style.display = (L.kind === 'world' && facing < .5) ? 'none' : 'block';",
      "    if(sm) sm.style.display = ((L.kind === 'world' && facing < .5) || (L.kind === 'agent' && facing < .6)) ? 'none' : 'block';")

# --- the header is taller now; the labels' quiet zone grows with it ---
patch('const hw = Math.min(430, innerWidth*.74), hh = 138;', 'const hw = Math.min(430, innerWidth*.74), hh = 172;')

# --- gold grade for the sources card ---
patch('  .track .fill{transition:width .35s ease}',
"""  .card.src{ border-color:rgba(221,192,96,.32); }
  .card.src h3{ color:#ddc060; }
  .track .fill{transition:width .35s ease}""")

# --- SOURCES card: last card in the panel, after the standing fine print ---
patch('sources of authority; systems are never sources of authority.</p>\n  </div>',
      'sources of authority; systems are never sources of authority.</p>\n' + src_card + '  </div>')

# --- gaze learns the helix ---
patch("regGaze('core', 'core', () => coreGrp.getWorldPosition(new THREE.Vector3()));",
"""regGaze('core', 'core', () => coreGrp.getWorldPosition(new THREE.Vector3()));
regGaze('helix', 'helix', () => helixGrp.localToWorld(new THREE.Vector3(3.06, 1.4, 0)));""")
patch("  if(c.kind === 'heart')",
"""  if(c.kind === 'helix'){ return { title: 'BRAILLE HELIX · TOUCH THE CODE', color: 0x66ccff, rows: [
      ['strands', '2 · blue / pink'], ['dots', '240 · instanced ×2'], ['spin', '515 Hz · his line 1'],
      ['line now', BRAILLE_LINES[helixLineIdx]], ['reads', BRAILLE_READS[helixLineIdx]] ] }; }
  if(c.kind === 'heart')""")
patch("  if(c.kind === 'helix'){",
"""  if(c.kind === 'agent'){ const def = AGENT_DEFS.find(a => a.id === c.key); const M = AGENT_MOTES.find(m => m.def.id === c.key);
    return { title: def.name.toUpperCase() + ' · AGENT', color: AGENT_COLORS[c.key], rows: [
      ['grants', def.capabilities.length ? def.capabilities.join(' · ') : 'none — holds the line'], ['receipts authored', influenceOf(c.key)],
      ['proposals · 45s', agentHeatNow(c.key)], ['orbit', 'R ' + M.rad.toFixed(1) + ' · inclined'], ['pace', 'speed rises with its heat'] ] }; }
  if(c.kind === 'helix'){""")

# --- gaze learns the notes (pitch, entrainment, dance) ---
patch("  if(c.kind === 'agent'){",
"""  if(c.kind === 'note'){ const n = NOTES[c.key]; const mass = noteMass(n), R = noteRadius(n);
    const ex = !lastField.inRange.includes(c.key) ? 'out of range' : n.type === 'contradiction' ? '+1 drag on the run' : n.type === 'receipt' ? 'anchoring the run' : '+1 push on the run';
    return { title: n.name.toUpperCase() + ' ' + n.glyph + ' · ' + n.type.toUpperCase() + ' NOTE', color: parseInt(n.colCss.slice(1), 16), rows: [
      ['pitch', n.freq.toFixed(1) + ' Hz'], ['moves', n.mover + ' · its own function'],
      ['mass', mass + ' receipts · ' + n.lineage], ['influence radius', R.toFixed(2)],
      ['exerting', ex], ['entrainment', Math.round(Math.cos(n.phase - MEAN_PH) * 100) + '%'], ['sound', 'sings on hover'] ] }; }
  if(c.kind === 'agent'){""")

# --- free orbit on gaze + the agents' moving parts + musicode + field notes ---
patch('/* ============ dock grip ============ */', freeorbit + '\n' + music + '\n' + field + '\n/* ============ dock grip ============ */')

# --- the amended law at every force computation (P2.8-A) ---
patch('K.forcesFor(cur, ETA);', 'K.forcesFor(cur, ETA, noteFieldStep());', count=3)
patch('(evidence ${forces.parts.evidence} + worlds ${forces.parts.worlds} + prior receipts ${forces.parts.priorReceipts})',
      '(evidence ${forces.parts.evidence} + worlds ${forces.parts.worlds} + prior receipts ${forces.parts.priorReceipts} + field push ${forces.parts.fieldPush || 0})')
patch('(risk ${cur.risk} + conflict ${forces.parts.conflicts} — P3)',
      '(risk ${cur.risk} + conflict ${forces.parts.conflicts} — P3 · + field drag ${forces.parts.fieldDrag || 0})')

# --- pinch owns the radius at the source: a fast pinch dispatches all its
#     events between two frames, so the hold must be set in the pinch handler
#     itself, not only noticed by gazeOrbitStep ---
patch('if(d > 10) camT.r = THREE.MathUtils.clamp(pinch.r * pinch.d / d, R_MIN, R_MAX); return; }',
      'if(d > 10){ camT.r = THREE.MathUtils.clamp(pinch.r * pinch.d / d, R_MIN, R_MAX); zoomHold = true; } return; }')

# --- the frame loop steps the layers, the agents, and the free orbit ---
patch('vecStep(); gazeScan(); composer.render();', 'vecStep(); layersStep(dt, t); agentsStep(dt); gazeOrbitStep(); gazeScan(); composer.render();')

# --- test hook for the layers ---
patch('window.__gazeAim = (kind, key) => { const c = gazeCands.find(c => c.kind === kind && c.key === key) || gazeCands.find(c => c.kind === kind);',
"""window.__layers = () => ({ helix: HELIX_N * 2, swarm: NOTES.length, dust: DUST_N, embers: EMBER_N, braille: BRAILLE_LINES[helixLineIdx], reads: BRAILLE_READS[helixLineIdx],
  swarmLock: NOTES.reduce((s, n) => s + Math.cos(n.phase - MEAN_PH), 0) / NOTES.length });
window.__gazeAim = (kind, key) => { const c = gazeCands.find(c => c.kind === kind && c.key === key) || gazeCands.find(c => c.kind === kind);""")

out = HERE / 'index.html'
out.write_text(html)
print('assembled', out, len(html), 'bytes')
