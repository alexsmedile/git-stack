#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const defaultRoot = path.resolve(scriptDir, "../../..");
const metadataName = ".git-stack-command-skills.json";

function pathExists(target) {
  try { fs.lstatSync(target); return true; } catch { return false; }
}

function hashFile(target) {
  return crypto.createHash("sha256").update(fs.readFileSync(target)).digest("hex");
}

function readCatalog(root) {
  const catalogPath = path.join(root, "specs/commands/index.json");
  const catalog = JSON.parse(fs.readFileSync(catalogPath, "utf8"));
  if (!Array.isArray(catalog.commands) || !catalog.commands.length) {
    throw new Error("specs/commands/index.json has no commands");
  }
  return catalog.commands;
}

function parseCommand(source) {
  const content = fs.readFileSync(source, "utf8");
  const match = content.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/u);
  if (!match) throw new Error(`Missing frontmatter: ${source}`);
  const description = match[1].match(/^description:\s*(.+)$/mu)?.[1]?.trim()
    || "Run the git-stack workflow for this operation.";
  return {
    description,
    body: match[2]
      .replace(/\$\{CLAUDE_PLUGIN_ROOT\}\/skills\/git-ops\/scripts/gu, "{{SCRIPT_PATH}}")
      .replace(/\$\{CLAUDE_PLUGIN_ROOT\}/gu, "{{PLUGIN_ROOT}}")
      .replace(/skills\/git-ops\/scripts\//gu, "{{SCRIPT_PATH}}/")
      .replace(/skills\/git-ops\/references\//gu, "the installed git-ops skill's references/")
      .replace(/\$ARGUMENTS/gu, "the user's supplied arguments")
      .replace(/^(#) \/([a-z0-9-]+)/gmu, "$1 $2")
      .replace(/AskUserQuestion/gu, "the harness confirmation mechanism")
      .trimStart(),
  };
}

function renderSkill(name, command, scriptPath) {
  const body = command.body
    .replaceAll("{{SCRIPT_PATH}}", scriptPath)
    .replaceAll("{{PLUGIN_ROOT}}", path.dirname(path.dirname(scriptPath)));
  return `---\nname: ${name}\ndescription: ${command.description}\n---\n\n${body}\n`;
}

function readMetadata(skillRoot) {
  const metadataPath = path.join(skillRoot, metadataName);
  if (!pathExists(metadataPath)) return { metadataPath, data: null };
  try {
    return { metadataPath, data: JSON.parse(fs.readFileSync(metadataPath, "utf8")) };
  } catch {
    throw new Error(`Invalid metadata file: ${metadataPath}`);
  }
}

function removeTarget(target) {
  fs.rmSync(target, { recursive: true, force: true });
}

export function generateCommandSkills({
  root = defaultRoot,
  skillRoot,
  scriptPath = path.join(root, "skills/git-ops/scripts"),
  excluded = [],
  dryRun = false,
  force = false,
  check = false,
  uninstall = false,
} = {}) {
  if (!skillRoot) throw new Error("skillRoot is required");
  const excludedSet = new Set(excluded);
  const { metadataPath, data: previous } = readMetadata(skillRoot);
  const entries = { ...(previous?.commands || {}) };
  const plans = [];
  const blocked = [];

  if (uninstall) {
    for (const [name, entry] of Object.entries(entries)) {
      const target = path.join(skillRoot, entry.destination || name);
      if (!pathExists(target)) continue;
      const owned = entry.sha256 && fs.existsSync(path.join(target, "SKILL.md"))
        && hashFile(path.join(target, "SKILL.md")) === entry.sha256;
      if (!owned && !force) {
        blocked.push(`${target} (changed since installation; use --force to remove)`);
        continue;
      }
      plans.push({ action: "REMOVE", target });
      delete entries[name];
    }
    if (blocked.length) return { status: "BLOCKED", blocked };
    if (!dryRun) {
      for (const plan of plans) removeTarget(plan.target);
      if (Object.keys(entries).length === 0 && pathExists(metadataPath)) removeTarget(metadataPath);
      else fs.writeFileSync(metadataPath, `${JSON.stringify({ schemaVersion: 1, commands: entries }, null, 2)}\n`, "utf8");
    }
    return { status: dryRun ? "DRY_RUN" : "UNINSTALLED", plans, metadataPath };
  }

  const commands = readCatalog(root);

  for (const definition of commands) {
    const name = definition.name;
    if (excludedSet.has(name)) continue;
    const source = path.resolve(root, definition.source);
    if (!pathExists(source)) throw new Error(`Command source not found: ${definition.source}`);
    const target = path.join(skillRoot, name);
    const skillFile = path.join(target, "SKILL.md");
    const content = renderSkill(name, parseCommand(source), scriptPath);
    const contentHash = crypto.createHash("sha256").update(content).digest("hex");
    const prior = entries[name];

    if (check) {
      if (!fs.existsSync(skillFile)) blocked.push(`${skillFile} (missing generated skill)`);
      else if (hashFile(skillFile) !== contentHash) blocked.push(`${skillFile} (generated output drift)`);
      else plans.push({ action: "UNCHANGED", target });
      continue;
    }

    if (pathExists(target) && !force) {
      const managedUnchanged = prior?.sha256 && fs.existsSync(skillFile)
        && hashFile(skillFile) === prior.sha256;
      if (!managedUnchanged) {
        blocked.push(`${target} (already exists; use --force only if you intend to replace it)`);
        continue;
      }
    }
    plans.push({ action: pathExists(target) ? "UPDATE" : "CREATE", target, skillFile, content });
    entries[name] = {
      source: definition.source,
      destination: name,
      sha256: contentHash,
    };
  }

  if (blocked.length) return { status: check ? "DRIFT" : "BLOCKED", blocked };
  if (check) return { status: "CHECKED", plans, metadataPath };
  if (!dryRun) {
    for (const plan of plans) {
      fs.mkdirSync(plan.target, { recursive: true });
      if (plan.action === "UPDATE") removeTarget(plan.target);
      fs.mkdirSync(path.dirname(plan.skillFile), { recursive: true });
      fs.writeFileSync(plan.skillFile, plan.content, "utf8");
    }
    fs.mkdirSync(skillRoot, { recursive: true });
    fs.writeFileSync(metadataPath, `${JSON.stringify({ schemaVersion: 1, commands: entries }, null, 2)}\n`, "utf8");
  }
  return { status: dryRun ? "DRY_RUN" : "INSTALLED", plans, metadataPath };
}

function usage() {
  console.log(`Usage: generate-command-skills.mjs [options]

Options:
  --root <path>             git-stack checkout root
  --skill-root <path>       Destination skill root (required)
  --script-path <path>      Portable path to git-ops/scripts
  --no-<command>            Exclude a command (all are enabled by default)
  --check                   Verify existing generated output without writing
  --dry-run                 Preview without writing
  --force                   Replace changed destinations
  --uninstall               Remove generated command skills
`);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  if (args.includes("--help") || args.includes("-h")) {
    usage();
    process.exit(0);
  }
  let root = defaultRoot;
  let skillRoot = "";
  let scriptPath = "";
  let dryRun = false;
  let force = false;
  let check = false;
  let uninstall = false;
  const excluded = [];
  while (args.length) {
    const arg = args.shift();
    if (arg === "--root") root = path.resolve(args.shift() || "");
    else if (arg === "--skill-root") skillRoot = path.resolve(args.shift() || "");
    else if (arg === "--script-path") scriptPath = args.shift() || "";
    else if (arg === "--dry-run") dryRun = true;
    else if (arg === "--force") force = true;
    else if (arg === "--check") check = true;
    else if (arg === "--uninstall") uninstall = true;
    else if (arg.startsWith("--no-")) excluded.push(arg.slice(5));
    else throw new Error(`Unknown option: ${arg}`);
  }
  try {
    const result = generateCommandSkills({ root, skillRoot, scriptPath, excluded, dryRun, force, check, uninstall });
    for (const plan of result.plans || []) console.log(`${plan.action} ${plan.target}`);
    for (const item of result.blocked || []) console.error(`BLOCKED ${item}`);
    console.log(`COMMAND_SKILLS=${result.status}`);
    if (["BLOCKED", "DRIFT"].includes(result.status)) process.exitCode = 1;
  } catch (error) {
    console.error(`ERROR=${error.message}`);
    process.exitCode = 1;
  }
}
