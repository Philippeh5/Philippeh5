// claude-foreman — seat-evidence reporter for claude-seat-dispatch.sh.
//
// Kept as a file rather than a `node -e` heredoc inside the launcher: the
// report text is full of single quotes around model ids, and every one of them
// would terminate the launcher's shell quoting.
//
// Reads the dispatch artifact and prints the evidence lines the transport
// envelope ends with. It NEVER upgrades the wording to "verified": modelUsage
// is the gateway's billing record, not a served-model field (SKILL.md hard
// rail 5, verification.md Layer 0).
//
// Usage: node seat-evidence.js <artifact.json> <alias> [expected-model-id]
'use strict';

const fs = require('fs');
const [artifactPath, alias, expected] = process.argv.slice(2);

if (!artifactPath || !alias) {
  console.log('seat evidence: NONE — evidence checker called without an artifact. Seat: unverified (Layer 0).');
  process.exit(0);
}

let result;
try {
  result = JSON.parse(fs.readFileSync(artifactPath, 'utf8'));
} catch (err) {
  console.log(`seat evidence: NONE — artifact is not parseable JSON (${err.message}).`);
  console.log('               Seat: unverified (Layer 0).');
  process.exit(0);
}

const usageMap = result.modelUsage && typeof result.modelUsage === 'object'
  ? result.modelUsage
  : {};
const billed = Object.keys(usageMap);

const inputOf = (id) => {
  const v = usageMap[id];
  return v && typeof v.inputTokens === 'number' ? v.inputTokens : 0;
};
// The map routinely holds two keys — the model that ran the agent loop plus the
// small background model Claude Code uses for titles and summaries. A presence
// test cannot tell them apart, and on this machine the background model *is*
// the id the `haiku` alias maps to, so `billed.includes(expected)` passed
// trivially for that alias while a different model did all the work. Evidence
// is therefore "the id carrying the bulk of the input tokens is the expected
// one" — measured 2026-08-26, the background model bills 79–427 input tokens
// against the main model's 7.5k–29k, so on real data the two are far apart.
//
// But "far apart" is a property of a healthy artifact, not a guarantee. A
// truncated or errored result can report zeros, or a tie, and then "which id
// carried the bulk" has no answer. Reporting SUSPECT there would turn *no
// evidence* into an accusation of substitution — the very distinction this
// reporter exists to keep. So a verdict is only issued when one id leads the
// runner-up by a clear margin; otherwise the seat is simply unverified.
const ranked = billed.slice().sort((a, b) => inputOf(b) - inputOf(a));
const primary = ranked[0];
const lead = inputOf(ranked[0]) - (ranked.length > 1 ? inputOf(ranked[1]) : 0);
// 1000 sits an order of magnitude above the largest background-model figure
// measured (427) and an order of magnitude below the smallest main-model one
// (7528), so it separates the real cases without being tuned to them.
const decisive = inputOf(primary) > 0 && (billed.length === 1 || lead >= 1000);
let mismatch = false;
const ledger = billed
  .map((id) => `${id} (in=${inputOf(id)})`)
  .join(', ');

if (!billed.length) {
  console.log('seat evidence: NONE — the result carries no modelUsage. Seat: unverified (Layer 0).');
} else if (expected && !decisive) {
  console.log('seat evidence: NONE — no id carries a decisive share of the input tokens, so which');
  console.log('               model ran the dispatch cannot be determined from this artifact.');
  console.log(`               Billed models: ${ledger}.`);
  console.log('               This is missing evidence, NOT a proven substitution — the artifact is');
  console.log('               probably truncated or errored. Seat: unverified (Layer 0).');
} else if (expected && primary === expected) {
  console.log(`billed-tier evidence: '${expected}' carried the bulk of the input tokens, and it is the`);
  console.log(`               id this machine maps to alias '${alias}'.`);
  console.log(`               Billed models: ${ledger}.`);
  console.log('               This is the gateway billing record, NOT a served-tier field.');
  console.log('               Seat: billed-tier only — never record it as "verified".');
} else if (expected) {
  console.log(`WARNING — SEAT MISMATCH: alias '${alias}' maps to '${expected}' on this machine,`);
  console.log(`               but '${primary}' carried the bulk of the input tokens.`);
  console.log(`               Billed models: ${ledger}.`);
  console.log('               The gateway substituted the model (routing.md silent-fallback');
  console.log('               hazard). Treat this dispatch as SUSPECT and do not accept its output.');
  // Exit 3 so the launcher can surface SUSPECT in its exit code. Printing the
  // warning is not enough: the transport wrapper decides DONE vs BLOCKED from
  // the exit code, so a prose-only warning got relayed as DONE.
  mismatch = true;
} else {
  console.log(`billed models: ${billed.join(', ')} — but the seat settings define no`);
  console.log(`               ANTHROPIC_DEFAULT_${alias.toUpperCase()}_MODEL, so there is nothing to`);
  console.log('               compare against. Seat: unverified (Layer 0).');
}

const usage = result.usage || {};
const measured = ['input_tokens', 'output_tokens', 'cache_creation_input_tokens', 'cache_read_input_tokens']
  .filter((k) => typeof usage[k] === 'number')
  .map((k) => `${k}=${usage[k]}`)
  .join(' ');
if (measured) console.log(`tokens (measured): ${measured}`);

// Observed 2026-08-26: a dispatch served entirely by ":free" models reported
// $0.158, because Claude Code prices the alias tier against Anthropic's table
// rather than the gateway's. Tokens are measured here; dollars are not.
if (typeof result.total_cost_usd === 'number') {
  console.log(`cost: total_cost_usd=${result.total_cost_usd} — NOT REPORTABLE AS MONEY for a gateway`);
  console.log('      seat: the figure prices the alias tier against Anthropic rates, not the');
  console.log('      gateway rates. Free models have been observed billing over $0.10 here.');
  console.log('      Log the token counts above instead.');
}

if (result.is_error === true) {
  console.log('NOTE: the result is flagged is_error — the seat returned an error payload, not work.');
}

// 3 = proven substitution. Any other failure mode stays 0: "no evidence" is not
// the same claim as "wrong model", and only the latter invalidates the output.
if (mismatch) process.exit(3);
