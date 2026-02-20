// Deep structural comparison of two JSON files, ignoring key order.
// Usage: bun deep-diff.js <nix-output.json> <reference.json>
const fs = require('fs');
const nix = JSON.parse(fs.readFileSync(process.argv[2], 'utf-8'));
const ref = JSON.parse(fs.readFileSync(process.argv[3], 'utf-8'));

function deepDiff(a, b, path) {
  const diffs = [];
  if (typeof a !== typeof b) {
    diffs.push(path + ': type mismatch (' + typeof a + ' vs ' + typeof b + ')');
    return diffs;
  }
  if (Array.isArray(a)) {
    if (!Array.isArray(b)) { diffs.push(path + ': array vs non-array'); return diffs; }
    const len = Math.max(a.length, b.length);
    for (let i = 0; i < len; i++) {
      if (i >= a.length) diffs.push(path + '[' + i + ']: missing in nix');
      else if (i >= b.length) diffs.push(path + '[' + i + ']: extra in nix');
      else diffs.push(...deepDiff(a[i], b[i], path + '[' + i + ']'));
    }
    return diffs;
  }
  if (typeof a === 'object' && a !== null) {
    const allKeys = new Set([...Object.keys(a), ...Object.keys(b)]);
    for (const k of allKeys) {
      if (!(k in a)) diffs.push(path + '.' + k + ': missing in nix');
      else if (!(k in b)) diffs.push(path + '.' + k + ': extra in nix (not in reference)');
      else diffs.push(...deepDiff(a[k], b[k], path + '.' + k));
    }
    return diffs;
  }
  if (a !== b) diffs.push(path + ': ' + JSON.stringify(a) + ' !== ' + JSON.stringify(b));
  return diffs;
}

const diffs = deepDiff(nix, ref, '$');

// Filter out known normalization differences
const knownNormalizations = [
  '$.agent.data-processor.mode: extra in nix (not in reference)',
];
const realDiffs = diffs.filter(d => !knownNormalizations.includes(d));

if (realDiffs.length === 0) {
  if (diffs.length > realDiffs.length) {
    console.log('Known normalizations (expected):');
    diffs.filter(d => knownNormalizations.includes(d)).forEach(d => console.log('  ' + d));
  }
  console.log('STRUCTURALLY_IDENTICAL');
} else {
  console.log('DIFFERENCES:');
  realDiffs.forEach(d => console.log('  ' + d));
  process.exit(1);
}
