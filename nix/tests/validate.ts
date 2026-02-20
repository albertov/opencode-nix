#!/usr/bin/env bun
//
// Zod-based validation of opencode.json configs against Config.Info schema.
//
// Usage:
//   OPENCODE_SRC=<path-to-opencode-source-with-node_modules> \
//     bun validate.ts <path-to-opencode.json> [--expect-fail]
//
// Environment:
//   OPENCODE_SRC — root of the opencode source tree (must have node_modules installed)
//
// Exit codes:
//   0 — validation outcome matches expectation
//   1 — validation outcome does NOT match expectation (or usage error)
//

import { readFileSync } from "fs";

const OPENCODE_SRC = process.env.OPENCODE_SRC;
if (!OPENCODE_SRC) {
  console.error(
    "OPENCODE_SRC environment variable must be set to opencode source root",
  );
  process.exit(1);
}

const jsonPath = process.argv[2];
const shouldFail = process.argv[3] === "--expect-fail";

if (!jsonPath) {
  console.error(
    "Usage: OPENCODE_SRC=<path> bun validate.ts <path-to-config.json> [--expect-fail]",
  );
  process.exit(1);
}

// Dynamic import: resolve Config.Info from the opencode source tree.
// Bun can import .ts files directly, and the node_modules must already be
// present under OPENCODE_SRC for transitive dependencies to resolve.
const configModule = await import(
  `${OPENCODE_SRC}/packages/opencode/src/config/config.ts`
);
const Config = configModule.Config;

if (!Config?.Info?.safeParse) {
  console.error(
    "✗ Could not resolve Config.Info Zod schema from opencode source",
  );
  process.exit(1);
}

// Read and parse the JSON file
const content = readFileSync(jsonPath, "utf-8");
let parsed: unknown;
try {
  parsed = JSON.parse(content);
} catch (e) {
  console.error(`✗ JSON parse error: ${e}`);
  process.exit(shouldFail ? 0 : 1);
}

// Validate against the Zod schema
const result = Config.Info.safeParse(parsed);

if (shouldFail) {
  if (!result.success) {
    const firstIssue = result.error.issues[0];
    console.log(
      `✓ Expected failure confirmed: ${firstIssue?.path?.join(".")} — ${firstIssue?.message}`,
    );
    process.exit(0);
  } else {
    console.error("✗ Expected failure but config was valid");
    process.exit(1);
  }
} else {
  if (result.success) {
    console.log("✓ Valid config");
    process.exit(0);
  } else {
    console.error("✗ Invalid config:");
    console.error(JSON.stringify(result.error.format(), null, 2));
    process.exit(1);
  }
}
