import fs from 'node:fs';
import crypto from 'node:crypto';

const kernelSrc = fs.readFileSync(new URL('./si-kernel.js', import.meta.url), 'utf8');
const body = kernelSrc.replace(/^export /gm, '');
const wrapped = `/* === SI KERNEL — inlined by kernel/build.mjs · DO NOT EDIT HERE · source: kernel/si-kernel.js === */\n${body}\n/* === END SI KERNEL === */`;
const hash = crypto.createHash('sha256').update(body).digest('hex').slice(0, 16);

for(const target of process.argv.slice(2)){
  let s = fs.readFileSync(target, 'utf8');
  const re = /\/\* === SI KERNEL[\s\S]*?\/\* === END SI KERNEL === \*\//;
  if(re.test(s)) s = s.replace(re, wrapped);
  else {
    const anchor = "const $ = id => document.getElementById(id);";
    if(!s.includes(anchor)){ console.error('NO ANCHOR in ' + target); process.exit(1); }
    s = s.replace(anchor, wrapped + '\n\n' + anchor);
  }
  /* verify: the inlined body hashes to the source body */
  const m = s.match(/\/\* === SI KERNEL[\s\S]*?\*\/\n([\s\S]*?)\n\/\* === END SI KERNEL === \*\//);
  const inHash = crypto.createHash('sha256').update(m[1]).digest('hex').slice(0, 16);
  if(inHash !== hash){ console.error('HASH MISMATCH in ' + target); process.exit(1); }
  fs.writeFileSync(target, s);
  console.log(target + ' — kernel inlined, sha256[0:16] = ' + inHash);
}
