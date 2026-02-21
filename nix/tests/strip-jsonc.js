// Strip JSONC comments and trailing commas, output compact JSON.
// Usage: bun strip-jsonc.js <input.jsonc> <output.json>
//
// This implementation properly handles strings (doesn't strip // inside "...").
const fs = require("fs");
const text = fs.readFileSync(process.argv[2], "utf-8");

let result = "";
let i = 0;
while (i < text.length) {
  // String literal — copy verbatim
  if (text[i] === '"') {
    let j = i + 1;
    while (j < text.length && text[j] !== '"') {
      if (text[j] === "\\") j++; // skip escaped char
      j++;
    }
    result += text.slice(i, j + 1);
    i = j + 1;
    continue;
  }
  // Single-line comment
  if (text[i] === "/" && text[i + 1] === "/") {
    // Skip to end of line
    while (i < text.length && text[i] !== "\n") i++;
    continue;
  }
  // Block comment
  if (text[i] === "/" && text[i + 1] === "*") {
    i += 2;
    while (i < text.length && !(text[i] === "*" && text[i + 1] === "/")) i++;
    i += 2; // skip */
    continue;
  }
  result += text[i];
  i++;
}

// Remove trailing commas before } or ]
const cleaned = result.replace(/,\s*([\]}])/g, "$1");
const parsed = JSON.parse(cleaned);
fs.writeFileSync(process.argv[3], JSON.stringify(parsed, null, 0));
