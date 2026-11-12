#!/usr/bin/env node
// Digest of past Claude Code conversations for ONE project (read-only).
// Usage: node extract.mjs [projectDir=cwd] [--sessions N=40] [--max-prompt N=400]
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';

const args = process.argv.slice(2);
const opt = (n, d) => { const i = args.indexOf(n); return i >= 0 ? Number(args[i + 1]) : d; };
const MAX_SESSIONS = opt('--sessions', 40);
const MAX_PROMPT = opt('--max-prompt', 400);
const projectDir = path.resolve(args.find((a, i) => !a.startsWith('--') && !/^\d+$/.test(a) || false) || process.cwd());

// Claude Code encodes the project path: every non-alphanumeric char -> '-'
const encoded = projectDir.replace(/[^A-Za-z0-9]/g, '-');
// Respect CLAUDE_CONFIG_DIR (this chat runs under ~/.claude-nvidia); fall back to ~/.claude
const configDir = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude');
const primaryRoot = path.join(configDir, 'projects');
const fallbackRoot = path.join(os.homedir(), '.claude', 'projects');
const resolveRoot = () => {
  if (fs.existsSync(primaryRoot)) return primaryRoot;
  if (fs.existsSync(fallbackRoot)) return fallbackRoot;
  return primaryRoot;
};
let root = resolveRoot();
let dir = path.join(root, encoded);
if (!fs.existsSync(dir)) {
  const hit = fs.existsSync(root) && fs.readdirSync(root).find(d => d.toLowerCase() === encoded.toLowerCase());
  if (!hit) { console.log(`NO_HISTORY: no ${encoded} under ${root}`); process.exit(0); }
  dir = path.join(root, hit);
}

const files = fs.readdirSync(dir).filter(f => f.endsWith('.jsonl'))
  .map(f => ({ f, p: path.join(dir, f), m: fs.statSync(path.join(dir, f)).mtimeMs }))
  .sort((a, b) => b.m - a.m).slice(0, MAX_SESSIONS);

const CORRECTION = /\b(non[ ,.!]|pas (ça|comme|du tout)|je (t'ai|te l'ai) (déjà )?(dit|demandé)|encore (une fois|ça)|toujours|à chaque fois|n'oublie pas|arrête|stop|pourquoi (tu|t'as|as-tu)|c'est (faux|cassé|nul)|ça (marche|fonctionne) pas|still (broken|not)|again|i (told|said)|don't|never|always|wrong|you (forgot|missed))\b/i;
const strip = s => s.replace(/<system-reminder>[\s\S]*?<\/system-reminder>/g, '').replace(/<pasted_content[^>]*>|<\/pasted_content[^>]*>/g, '').trim();
const textOf = c => typeof c === 'string' ? c : Array.isArray(c) ? c.filter(x => x.type === 'text').map(x => x.text).join('\n') : '';

const sessions = [], errCount = new Map(), promptCount = new Map();
for (const { f, p, m } of files) {
  const prompts = [], corrections = [];
  for (const line of fs.readFileSync(p, 'utf8').split('\n')) {
    if (!line) continue;
    let o; try { o = JSON.parse(line); } catch { continue; }
    if (o.type !== 'user' || o.isSidechain || o.isMeta) continue;
    const c = o.message?.content;
    if (Array.isArray(c)) {
      for (const b of c) if (b.type === 'tool_result' && b.is_error) {
        const k = textOf(b.content).replace(/\s+/g, ' ').replace(/[A-Za-z]:[\/][^ ]+/g, '<path>').slice(0, 90);
        if (k) errCount.set(k, (errCount.get(k) || 0) + 1);
      }
    }
    const t = strip(textOf(c));
    if (!t || t.startsWith('<command-') || t.startsWith('<local-command') || t.startsWith('Caveat:') || t.startsWith('<task-notification') || t.startsWith('[Request interrupted')) continue;
    const short = t.replace(/\s+/g, ' ').slice(0, MAX_PROMPT);
    prompts.push(short);
    if (CORRECTION.test(t) && t.length < 600) corrections.push(short);
    const norm = t.toLowerCase().replace(/\s+/g, ' ').slice(0, 80);
    if (norm.length > 15) promptCount.set(norm, (promptCount.get(norm) || 0) + 1);
  }
  if (prompts.length) sessions.push({ id: f.slice(0, 8), date: new Date(m).toISOString().slice(0, 10), prompts, corrections });
}

console.log(`# Digest — ${projectDir}\nhistory: ${dir}\nsessions analysed: ${sessions.length}\n`);
console.log('## Repeated prompts (same opening typed in >=2 messages)');
for (const [k, n] of [...promptCount].filter(([, n]) => n >= 2).sort((a, b) => b[1] - a[1]).slice(0, 15)) console.log(`- x${n}: ${k}`);
console.log('\n## Recurrent tool errors');
for (const [k, n] of [...errCount].filter(([, n]) => n >= 2).sort((a, b) => b[1] - a[1]).slice(0, 15)) console.log(`- x${n}: ${k}`);
console.log('\n## Sessions (newest first): user prompts; [!] = looks like a correction/frustration');
for (const s of sessions) {
  console.log(`\n### ${s.date} ${s.id} (${s.prompts.length} prompts)`);
  const flagged = new Set(s.corrections);
  s.prompts.slice(0, 25).forEach(p => console.log(`${flagged.has(p) ? '[!]' : ' - '} ${p}`));
  if (s.prompts.length > 25) console.log(` … ${s.prompts.length - 25} more (corrections: ${s.corrections.length})`);
}
