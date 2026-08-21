#!/usr/bin/env node

// Distributes the canonical scripts in src/scripts/ into each skill that needs
// them. Skills must be self-contained: a skill installed on its own cannot
// reach a sibling skill's directory, so the scripts it calls are copied in.
//
// src/scripts/ is the SOURCE OF TRUTH. Never edit skills/*/scripts/ by hand —
// run this script instead. `--check` fails when any copy has drifted.

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = path.join(root, "src/scripts");

// Which scripts each skill needs. git-ops runs the write operations and so
// needs the full set; repo-hygiene and update-docs call only the read-only
// `cleanup` and `scan` subcommands, which never invoke the sibling checkers.
// secret-patterns.sh is sourced unconditionally by git-stack.sh, so every skill
// that ships git-stack.sh must ship it too — including the read-only ones.
const distribution = {
  "git-ops": [
    "git-stack.sh",
    "secret-patterns.sh",
    "check-author-email.sh",
    "check-manifests.sh",
    "bump-manifests.sh",
    "install-hooks.sh",
    "pre-commit-block-secrets.sh",
    "install-harness.mjs",
    "install-shortcuts.mjs",
    "validate-distribution.mjs",
  ],
  "repo-hygiene": ["git-stack.sh", "secret-patterns.sh"],
  "update-docs": ["git-stack.sh", "secret-patterns.sh"],
  "repo-governance": ["git-stack.sh", "secret-patterns.sh"],
};

function banner(name, comment) {
  return `${comment} GENERATED COPY — source of truth: src/scripts/${name}\n`
    + `${comment} Edit the source and run \`node src/sync-scripts.mjs\`. Do not edit here.\n`;
}

const check = process.argv.includes("--check");
const results = [];
let drifted = 0;

function stamp(name, content) {
  // Comment syntax differs: `#` for shell, `//` for JavaScript modules.
  const head = banner(name, name.endsWith(".mjs") ? "//" : "#");
  const lines = content.split("\n");
  // Keep the shebang first; insert the banner immediately after it.
  if (lines[0]?.startsWith("#!")) {
    return `${lines[0]}\n${head}${lines.slice(1).join("\n")}`;
  }
  return head + content;
}

for (const [skill, scripts] of Object.entries(distribution)) {
  const targetDir = path.join(root, "skills", skill, "scripts");
  if (!check) fs.mkdirSync(targetDir, { recursive: true });

  for (const name of scripts) {
    const from = path.join(source, name);
    if (!fs.existsSync(from)) {
      process.stderr.write(`ERROR=missing-source:${name}\n`);
      process.exit(1);
    }
    const content = stamp(name, fs.readFileSync(from, "utf8"));
    const to = path.join(targetDir, name);
    const current = fs.existsSync(to) ? fs.readFileSync(to, "utf8") : null;
    const same = current === content;

    if (!same) drifted++;
    results.push(`${same ? "OK" : check ? "DRIFT" : "WRITE"}=${skill}/${name}`);

    if (!check && !same) {
      fs.writeFileSync(to, content, "utf8");
      fs.chmodSync(to, fs.statSync(from).mode);
    }
  }

  // Remove copies no longer in the distribution list.
  if (fs.existsSync(targetDir)) {
    for (const existing of fs.readdirSync(targetDir)) {
      if (scripts.includes(existing)) continue;
      results.push(`${check ? "STALE" : "REMOVE"}=${skill}/${existing}`);
      drifted++;
      if (!check) fs.rmSync(path.join(targetDir, existing), { force: true });
    }
  }
}

for (const line of results) process.stdout.write(`${line}\n`);

if (check && drifted) {
  process.stdout.write(`SYNC=STALE:${drifted}\n`);
  process.stderr.write("ERROR=scripts out of sync; run `node src/sync-scripts.mjs`\n");
  process.exit(1);
}
process.stdout.write(`SYNC=${check ? "CLEAN" : `SYNCED:${drifted}`}\n`);
