#!/usr/bin/env node

import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../..");
const native = process.argv.includes("--native");
const errors = [];
const checked = [];

function fail(message) { errors.push(message); }
function readJson(relative) {
  try { return JSON.parse(fs.readFileSync(path.join(root, relative), "utf8")); }
  catch (error) { fail(`${relative}:${error.message}`); return {}; }
}
function requireValue(condition, message) { if (!condition) fail(message); }
function exactKeys(object, allowed, label) {
  for (const key of Object.keys(object)) {
    if (!allowed.has(key)) fail(`${label}:unsupported-field:${key}`);
  }
}
function commandExists(command) {
  const probe = spawnSync(command, ["--version"], { stdio: "ignore" });
  return !probe.error;
}
function run(command, args, options = {}, label = command) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    ...options,
  });
  if (result.error || result.status !== 0) {
    const detail = (result.stderr || result.stdout || result.error?.message || "failed").trim().split("\n").pop();
    fail(`native:${label}:${detail}`);
    return false;
  }
  checked.push(label);
  return true;
}

const claude = readJson(".claude-plugin/plugin.json");
const claudeMarket = readJson(".claude-plugin/marketplace.json");
const codex = readJson(".codex-plugin/plugin.json");
const codexMarket = readJson(".agents/plugins/marketplace.json");
const cursor = readJson(".cursor-plugin/plugin.json");
const cursorMarket = readJson(".cursor-plugin/marketplace.json");
const antigravity = readJson("plugin.json");
const commandCatalog = readJson("specs/commands/index.json");

const version = claude.version;
const repo = "https://github.com/alexsmedile/git-stack";
const description = "Portable, script-first Git and GitHub workflows with compact safety checks.";
const manifests = [
  ["claude", claude],
  ["codex", codex],
  ["cursor", cursor],
];
for (const [name, manifest] of manifests) {
  requireValue(manifest.name === "git-stack", `${name}:name`);
  requireValue(manifest.version === version && /^\d+\.\d+\.\d+$/.test(manifest.version || ""), `${name}:version`);
  requireValue(manifest.description === description, `${name}:description`);
  requireValue(manifest.repository === repo, `${name}:repository`);
}

requireValue(Array.isArray(claude.agents) && claude.agents.length === 1 && claude.agents[0] === "./adapters/claude/agents/git-stack-runner.md", "claude:agent-adapter-path");
requireValue(claude.commands === "./adapters/claude/commands/", "claude:commands-adapter-path");
requireValue(fs.existsSync(path.join(root, "adapters/claude/agents/git-stack-runner.md")), "claude:agent-adapter-missing");
requireValue(!fs.existsSync(path.join(root, "agents")), "portable-root:claude-agent-leak");
requireValue(!fs.existsSync(path.join(root, "commands")), "portable-root:claude-command-leak");
requireValue(claudeMarket.name === "git-stack", "claude-market:name");
requireValue(claudeMarket.metadata?.version === version, "claude-market:metadata-version");
requireValue(claudeMarket.plugins?.length === 1 && claudeMarket.plugins[0].source === "./", "claude-market:source");
requireValue(!Object.hasOwn(claudeMarket.plugins?.[0] || {}, "version"), "claude-market:duplicate-plugin-version");

requireValue(typeof codex.author === "object" && codex.author?.name, "codex:author");
requireValue(codex.skills === "./skills/", "codex:skills-path");
requireValue(!Object.hasOwn(codex, "hooks"), "codex:unneeded-hooks-field");
requireValue(codexMarket.name === "git-stack", "codex-market:name");
requireValue(codexMarket.plugins?.[0]?.source?.source === "url", "codex-market:source-type");
requireValue(codexMarket.plugins?.[0]?.source?.url === `${repo}.git`, "codex-market:repository-url");
requireValue(codexMarket.plugins?.[0]?.policy?.installation === "AVAILABLE", "codex-market:installation-policy");
requireValue(codexMarket.plugins?.[0]?.policy?.authentication === "ON_INSTALL", "codex-market:authentication-policy");

exactKeys(cursor, new Set([
  "name", "displayName", "description", "version", "author", "publisher",
  "homepage", "repository", "license", "logo", "keywords", "category",
  "tags", "commands", "agents", "skills", "rules", "hooks", "mcpServers",
]), "cursor");
requireValue(cursor.skills === "./skills/", "cursor:skills-path");
requireValue(typeof cursor.author === "object" && cursor.author?.name, "cursor:author");
requireValue(!Object.hasOwn(cursor, "agents") && !Object.hasOwn(cursor, "commands"), "cursor:must-remain-skill-only");
exactKeys(cursorMarket, new Set(["name", "owner", "metadata", "plugins"]), "cursor-market");
exactKeys(cursorMarket.owner || {}, new Set(["name", "email"]), "cursor-market:owner");
requireValue(cursorMarket.name === "git-stack", "cursor-market:name");
requireValue(cursorMarket.plugins?.length === 1 && cursorMarket.plugins[0].source === "./", "cursor-market:source");
for (const [index, plugin] of (cursorMarket.plugins || []).entries()) {
  exactKeys(plugin, new Set(["name", "source", "description"]), `cursor-market:plugin-${index}`);
}

exactKeys(antigravity, new Set(["$schema", "name", "description"]), "antigravity");
requireValue(antigravity.$schema === "https://antigravity.google/schemas/v1/plugin.json", "antigravity:schema");
requireValue(antigravity.name === "git-stack" && antigravity.description === description, "antigravity:identity");

const readme = fs.readFileSync(path.join(root, "README.md"), "utf8");
const changelog = fs.readFileSync(path.join(root, "docs/CHANGELOG.md"), "utf8");
requireValue(readme.includes(`badge/version-${version}`), "readme:version-badge");
requireValue(changelog.includes(`## [${version}]`), "changelog:top-version");
requireValue(readme.includes("docs/DISTRIBUTION.md"), "readme:distribution-link");
requireValue(fs.existsSync(path.join(root, "docs/DISTRIBUTION.md")), "docs:distribution-missing");
requireValue(fs.existsSync(path.join(root, "skills/git-ops/scripts/install-shortcuts.mjs")), "claude:shortcuts-installer-missing");
requireValue(readme.includes("install-shortcuts.mjs"), "readme:shortcuts-installer-link");
requireValue(fs.readFileSync(path.join(root, "docs/DISTRIBUTION.md"), "utf8").includes("install-shortcuts.mjs"), "docs:shortcuts-installer-link");
requireValue(fs.existsSync(path.join(root, "skills/git-ops/scripts/generate-command-skills.mjs")), "command-skills:generator-missing");
const expectedCommands = ["commit", "push", "release", "changelog", "update-docs", "wrap-up", "cleanup"];
requireValue(JSON.stringify((commandCatalog.commands || []).map((entry) => entry.name)) === JSON.stringify(expectedCommands), "command-skills:catalog-order");
for (const entry of commandCatalog.commands || []) {
  requireValue(fs.existsSync(path.join(root, entry.source || "")), `command-skills:source-missing:${entry.name}`);
}
requireValue(readme.includes("--with-command-skills"), "readme:command-skills-link");
requireValue(fs.readFileSync(path.join(root, "docs/DISTRIBUTION.md"), "utf8").includes("--with-command-skills"), "docs:command-skills-link");
for (const skill of ["git-ops", "repo-prettifier"]) {
  const skillFile = path.join(root, `skills/${skill}/SKILL.md`);
  requireValue(fs.existsSync(skillFile), `skill:${skill}:missing`);
  if (fs.existsSync(skillFile)) {
    const content = fs.readFileSync(skillFile, "utf8");
    requireValue(content.startsWith("---\n") && content.includes(`\nname: ${skill}\n`) && content.includes("\ndescription:"), `skill:${skill}:frontmatter`);
  }
}

if (native) {
  if (commandExists("claude")) run("claude", ["plugin", "validate", "."], {}, "claude-validate");
  if (commandExists("claude")) run("claude", ["plugin", "tag", ".", "--dry-run", "--force"], {}, "claude-tag-dry-run");
  if (commandExists("agy")) run("agy", ["plugin", "validate", "."], {}, "antigravity-validate");
  if (commandExists("codex")) {
    const temp = fs.mkdtempSync(path.join(os.tmpdir(), "git-stack-codex-"));
    const marketplace = path.join(temp, "marketplace");
    const plugin = path.join(marketplace, "plugin");
    fs.mkdirSync(path.join(marketplace, ".agents/plugins"), { recursive: true });
    fs.cpSync(root, plugin, {
      recursive: true,
      filter: source => ![".git", ".octopus", "_archive", "_backups", "articles"].includes(path.basename(source)),
    });
    fs.writeFileSync(path.join(marketplace, ".agents/plugins/marketplace.json"), JSON.stringify({
      name: "git-stack-verify",
      plugins: [{
        name: "git-stack",
        source: { source: "local", path: "./plugin" },
        policy: { installation: "AVAILABLE", authentication: "ON_INSTALL" },
        category: "Productivity",
      }],
    }, null, 2));
    const env = { ...process.env, CODEX_HOME: path.join(temp, "codex-home") };
    fs.mkdirSync(env.CODEX_HOME, { recursive: true });
    if (run("codex", ["plugin", "marketplace", "add", marketplace, "--json"], { env }, "codex-marketplace")) {
      run("codex", ["plugin", "add", "git-stack@git-stack-verify", "--json"], { env }, "codex-install");
    }
    fs.rmSync(temp, { recursive: true, force: true });
  }
  if (commandExists("opencode")) {
    const temp = fs.mkdtempSync(path.join(os.tmpdir(), "git-stack-opencode-"));
    const workspace = path.join(temp, "workspace");
    const env = {
      ...process.env,
      HOME: path.join(temp, "home"),
      XDG_DATA_HOME: path.join(temp, "data"),
      XDG_CONFIG_HOME: path.join(temp, "config"),
      XDG_CACHE_HOME: path.join(temp, "cache"),
      XDG_STATE_HOME: path.join(temp, "state"),
    };
    for (const directory of [env.HOME, env.XDG_DATA_HOME, env.XDG_CONFIG_HOME, env.XDG_CACHE_HOME, env.XDG_STATE_HOME]) {
      fs.mkdirSync(directory, { recursive: true });
    }
    fs.mkdirSync(path.join(workspace, ".agents"), { recursive: true });
    fs.cpSync(path.join(root, "skills"), path.join(workspace, ".agents/skills"), { recursive: true });
    const result = spawnSync("opencode", ["debug", "skill"], { cwd: workspace, env, encoding: "utf8" });
    if (result.error || result.status !== 0) {
      fail(`native:opencode-skill:${(result.stderr || result.stdout || result.error?.message || "failed").trim().split("\n").pop()}`);
    } else if (!result.stdout.includes('"name": "git-ops"') || !result.stdout.includes('"name": "repo-prettifier"')) {
      fail("native:opencode-skill:portable-skills-not-discovered");
    } else {
      checked.push("opencode-skill");
    }
    fs.rmSync(temp, { recursive: true, force: true });
  }
}

if (errors.length) {
  process.stdout.write("DISTRIBUTION=INVALID\n");
  for (const error of errors) process.stdout.write(`ERROR=${error}\n`);
  process.exit(1);
}
process.stdout.write(`DISTRIBUTION=VALID\nVERSION=${version}\nHARNESSES=claude,codex,cursor,antigravity,opencode-skill\n`);
if (native) process.stdout.write(`NATIVE=${checked.join(",") || "none"}\n`);
