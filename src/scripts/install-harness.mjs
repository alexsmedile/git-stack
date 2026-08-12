#!/usr/bin/env node

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
function findRoot(start) {
  // Works from src/scripts/ and from any skills/<name>/scripts/ copy.
  let dir = start;
  for (let i = 0; i < 6; i++) {
    if (fs.existsSync(path.join(dir, ".claude-plugin/plugin.json"))) return dir;
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  return path.resolve(start, "../../..");
}

const packageRoot = findRoot(scriptDir);
const harnesses = new Set(["claude", "codex", "cursor", "antigravity", "opencode"]);
const skillNames = ["git-ops", "repo-hygiene", "update-docs", "repo-prettifier"];

const args = process.argv.slice(2);
const harness = args.shift();
let scope = "project";
let surface = "app";
let surfaceSet = false;
let projectDir = process.cwd();
let model = "";
let withAgent = false;
let dryRun = false;
let force = false;

function usage(exitCode = 0) {
  process.stdout.write(`Usage: install-harness.mjs <harness> [options]

Harnesses: claude, codex, cursor, antigravity, opencode

Options:
  --scope project|global   Install scope (default: project)
  --surface app|cli        Antigravity global surface (default: app)
  --project-dir <path>     Project root (default: current directory)
  --with-agent             Also install a native optional runner adapter
  --model <id>             Override the adapter model
  --dry-run                Print destinations without writing
  --force                  Replace an existing skill/adapter

The skill is the portable core. Agent adapters are optional and are never used
for routine commit, push, tag, or release flows. Antigravity's documented
subagents inherit the parent model, so --with-agent is intentionally rejected.
All four skills (git-ops, repo-hygiene, update-docs, repo-prettifier) are
installed together. Harnesses without plugin commands invoke them
conversationally.
Cursor and OpenCode require an explicit --model because their available model
IDs are account/provider-specific and no stable low-cost default is assumed.
`);
  process.exit(exitCode);
}

function fail(message) {
  process.stderr.write(`ERROR=${message}\n`);
  process.exit(1);
}

if (harness === "-h" || harness === "--help") usage(0);

while (args.length) {
  const arg = args.shift();
  if (arg === "--scope") scope = args.shift() || fail("--scope requires a value");
  else if (arg === "--surface") { surface = args.shift() || fail("--surface requires a value"); surfaceSet = true; }
  else if (arg === "--project-dir") projectDir = path.resolve(args.shift() || fail("--project-dir requires a value"));
  else if (arg === "--model") model = args.shift() || fail("--model requires a value");
  else if (arg === "--with-agent") withAgent = true;
  else if (arg === "--dry-run") dryRun = true;
  else if (arg === "--force") force = true;
  else if (arg === "-h" || arg === "--help") usage(0);
  else fail(`Unknown option: ${arg}`);
}

if (!harnesses.has(harness)) usage(1);
if (!new Set(["project", "global"]).has(scope)) fail(`Invalid scope: ${scope}`);
if (!new Set(["app", "cli"]).has(surface)) fail(`Invalid surface: ${surface}`);
if (surfaceSet && harness !== "antigravity") fail("--surface is only valid for Antigravity.");
if (withAgent && harness === "antigravity") {
  fail("Antigravity subagents inherit the parent model; install the skill without --with-agent.");
}
if (withAgent && harness === "cursor" && !model) {
  fail("Cursor model availability is account-specific; pass --model with a verified small/low-cost model ID.");
}
if (withAgent && harness === "opencode" && !model) {
  fail("OpenCode model IDs are provider-specific; pass --model provider/model-id.");
}

const home = os.homedir();
const skillRoots = {
  claude: scope === "global" ? path.join(home, ".claude/skills") : path.join(projectDir, ".claude/skills"),
  codex: scope === "global" ? path.join(home, ".agents/skills") : path.join(projectDir, ".agents/skills"),
  cursor: scope === "global" ? path.join(home, ".cursor/skills") : path.join(projectDir, ".agents/skills"),
  antigravity: scope === "global"
    ? (surface === "cli" ? path.join(home, ".gemini/antigravity-cli/skills") : path.join(home, ".gemini/config/skills"))
    : path.join(projectDir, ".agents/skills"),
  opencode: scope === "global" ? path.join(home, ".config/opencode/skills") : path.join(projectDir, ".agents/skills"),
};
const skillTarget = path.join(skillRoots[harness], "git-ops");

const agentTargets = {
  claude: scope === "global" ? path.join(home, ".claude/agents/git-stack-runner.md") : path.join(projectDir, ".claude/agents/git-stack-runner.md"),
  codex: scope === "global" ? path.join(home, ".codex/agents/git-stack-runner.toml") : path.join(projectDir, ".codex/agents/git-stack-runner.toml"),
  cursor: scope === "global" ? path.join(home, ".cursor/agents/git-stack-runner.md") : path.join(projectDir, ".cursor/agents/git-stack-runner.md"),
  opencode: scope === "global" ? path.join(home, ".config/opencode/agents/git-stack-runner.md") : path.join(projectDir, ".opencode/agents/git-stack-runner.md"),
};

const defaultModels = {
  claude: "sonnet",
  codex: "gpt-5.6-terra",
};
if (!model) model = defaultModels[harness] || "";

function instructions(runner) {
  return `Run the compact git-stack executor at ${runner}. Use only the requested operation and return its KEY=value output without narration. Never pass --allow-main or --allow-large without explicit user approval. Never force-push, stage unspecified files, or spawn another agent. On a blocker, stop and return it to the parent.`;
}

function renderAgent() {
  const runner = path.join(skillTarget, "scripts/git-stack.sh");
  const prompt = instructions(runner);
  if (harness === "claude") return `---\nname: git-stack-runner\ndescription: Optional compact Git executor for explicitly delegated high-volume checks; never use for routine Git flows.\ntools: Bash, Read\nmodel: ${JSON.stringify(model)}\nmaxTurns: 4\n---\n\n${prompt}\n`;
  if (harness === "codex") return `name = "git_stack_runner"\ndescription = "Optional compact Git executor for explicitly delegated high-volume checks; never use for routine Git flows."\nmodel = ${JSON.stringify(model)}\nmodel_reasoning_effort = "low"\nsandbox_mode = "workspace-write"\ndeveloper_instructions = ${JSON.stringify(prompt)}\n`;
  if (harness === "cursor") return `---\nname: git-stack-runner\ndescription: Optional compact Git executor for explicitly delegated high-volume checks; never use for routine Git flows.\nmodel: ${JSON.stringify(model)}\nreadonly: false\nis_background: false\n---\n\n${prompt}\n`;
  return `---\ndescription: Optional compact Git executor for explicitly delegated high-volume checks; never use for routine Git flows.\nmode: subagent\nmodel: ${JSON.stringify(model)}\nsteps: 4\npermission:\n  read: allow\n  bash: allow\n  edit: deny\n  task: deny\n  question: deny\n---\n\n${prompt}\n`;
}

function installDirectory(source, target) {
  if (path.resolve(source) === path.resolve(target)) return "SOURCE";
  if (fs.existsSync(target) && !force) return "EXISTS";
  if (!dryRun) {
    fs.mkdirSync(path.dirname(target), { recursive: true });
    if (fs.existsSync(target)) fs.rmSync(target, { recursive: true, force: true });
    fs.cpSync(source, target, { recursive: true });
  }
  return dryRun ? "PLANNED" : "INSTALLED";
}

function installFile(target, content) {
  if (fs.existsSync(target) && !force) return "EXISTS";
  if (!dryRun) {
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.writeFileSync(target, content, "utf8");
  }
  return dryRun ? "PLANNED" : "INSTALLED";
}

function portableScriptPath() {
  const scriptPath = path.join(skillTarget, "scripts");
  if (scope === "global") {
    const relativeHome = path.relative(home, scriptPath).split(path.sep).join("/");
    return relativeHome ? `$HOME/${relativeHome}` : "$HOME";
  }
  const relativeProject = path.relative(projectDir, scriptPath).split(path.sep).join("/");
  return relativeProject || ".";
}

process.stdout.write(`HARNESS=${harness}\nSCOPE=${scope}\n`);
if (harness === "antigravity") process.stdout.write(`SURFACE=${surface}\n`);
for (const skillName of skillNames) {
  const source = path.join(packageRoot, "skills", skillName);
  if (!fs.existsSync(source)) continue;
  const target = path.join(skillRoots[harness], skillName);
  process.stdout.write(`SKILL=${installDirectory(source, target)}:${target}\n`);
}
if (withAgent) {
  const agentTarget = agentTargets[harness];
  process.stdout.write(`AGENT=${installFile(agentTarget, renderAgent())}:${agentTarget}\nMODEL=${model}\n`);
} else {
  process.stdout.write("AGENT=SKIPPED\n");
}
