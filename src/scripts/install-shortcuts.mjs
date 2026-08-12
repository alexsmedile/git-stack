#!/usr/bin/env node

/**
 * Install optional short Claude Code command aliases.
 *
 * The plugin commands remain namespaced (`/git-stack:commit`). This installer
 * copies or links selected command files into a Claude standalone command
 * directory so they can also be invoked as `/commit` and `/push`.
 */

import { createHash } from 'node:crypto';
import {
  existsSync,
  lstatSync,
  mkdirSync,
  readFileSync,
  readlinkSync,
  realpathSync,
  rmSync,
  symlinkSync,
  writeFileSync,
  copyFileSync,
} from 'node:fs';
import { homedir } from 'node:os';
import { dirname, isAbsolute, join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const SCRIPT_DIR = dirname(fileURLToPath(import.meta.url));
const PACKAGE_ROOT = resolve(process.env.CLAUDE_PLUGIN_ROOT || resolve(SCRIPT_DIR, '../../..'));
const METADATA_FILE = '.git-stack-shortcuts.json';
const DEFAULT_COMMANDS = ['commit', 'push'];

function usage() {
  console.log(`Usage:
  node install-shortcuts.mjs [options]

Install optional short Claude Code aliases for the plugin commands.

Options:
  --scope project|user  Destination scope (default: project)
  --mode copy|symlink   Install mode (default: copy)
  --commands LIST       Comma-separated command names (default: commit,push)
  --force               Replace collisions or changed managed files
  --dry-run             Show planned changes without writing
  --uninstall           Remove aliases recorded by the installer
  --help                Show this help

Project scope writes .claude/commands/ in the current repository.
User scope writes \${CLAUDE_CONFIG_DIR:-~/.claude}/commands/.
`);
}

function parseArgs(argv) {
  const options = {
    scope: 'project',
    mode: 'copy',
    commands: DEFAULT_COMMANDS,
    force: false,
    dryRun: false,
    uninstall: false,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === '--help' || arg === '-h') {
      options.help = true;
    } else if (arg === '--force') {
      options.force = true;
    } else if (arg === '--dry-run') {
      options.dryRun = true;
    } else if (arg === '--uninstall') {
      options.uninstall = true;
    } else if (arg === '--scope' || arg === '--mode' || arg === '--commands') {
      const value = argv[++index];
      if (!value) throw new Error(`${arg} requires a value`);
      if (arg === '--scope') options.scope = value;
      if (arg === '--mode') options.mode = value;
      if (arg === '--commands') options.commands = value.split(',').map((name) => name.trim()).filter(Boolean);
    } else if (arg.startsWith('--scope=')) {
      options.scope = arg.slice('--scope='.length);
    } else if (arg.startsWith('--mode=')) {
      options.mode = arg.slice('--mode='.length);
    } else if (arg.startsWith('--commands=')) {
      options.commands = arg.slice('--commands='.length).split(',').map((name) => name.trim()).filter(Boolean);
    } else {
      throw new Error(`Unknown option: ${arg}`);
    }
  }

  if (!['project', 'user'].includes(options.scope)) {
    throw new Error('--scope must be project or user');
  }
  if (!['copy', 'symlink'].includes(options.mode)) {
    throw new Error('--mode must be copy or symlink');
  }
  if (!options.commands.length) throw new Error('--commands must not be empty');
  for (const name of options.commands) {
    if (!/^[a-z0-9][a-z0-9-]*$/u.test(name)) {
      throw new Error(`Invalid command name: ${name}`);
    }
  }
  return options;
}

function pathExists(path) {
  return existsSync(path) || (() => {
    try {
      lstatSync(path);
      return true;
    } catch {
      return false;
    }
  })();
}

function sha256(path) {
  return createHash('sha256').update(readFileSync(path)).digest('hex');
}

function readManifestCommandPaths() {
  const manifestPath = join(PACKAGE_ROOT, '.claude-plugin', 'plugin.json');
  if (!existsSync(manifestPath)) return [];
  try {
    const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));
    const values = manifest.commands ?? [];
    return (Array.isArray(values) ? values : [values]).filter((value) => typeof value === 'string');
  } catch {
    return [];
  }
}

function sourceForCommand(name) {
  const candidates = [];
  for (const value of readManifestCommandPaths()) {
    const base = resolve(PACKAGE_ROOT, value);
    candidates.push(base.endsWith('.md') ? base : join(base, `${name}.md`));
  }
  candidates.push(
    join(PACKAGE_ROOT, 'commands', `${name}.md`),
    join(PACKAGE_ROOT, 'adapters', 'claude', 'commands', `${name}.md`),
  );
  const unique = [...new Set(candidates)];
  const source = unique.find((candidate) => existsSync(candidate) && lstatSync(candidate).isFile());
  if (!source) throw new Error(`Claude command source not found for ${name}`);
  return source;
}

function destinationDirectory(scope) {
  if (scope === 'project') return join(process.cwd(), '.claude', 'commands');
  const configRoot = process.env.CLAUDE_CONFIG_DIR || join(homedir(), '.claude');
  return join(configRoot, 'commands');
}

function metadataPath(destinationDir) {
  return join(destinationDir, METADATA_FILE);
}

function readMetadata(destinationDir) {
  const path = metadataPath(destinationDir);
  if (!existsSync(path)) return { path, data: null };
  try {
    return { path, data: JSON.parse(readFileSync(path, 'utf8')) };
  } catch {
    throw new Error(`Invalid metadata file: ${path}; remove it or use --force`);
  }
}

function relativeSource(source) {
  const value = relative(PACKAGE_ROOT, source);
  return value && !value.startsWith('..') && !isAbsolute(value) ? value : source;
}

function managedEntry(metadata, name) {
  return metadata?.commands?.[name] ?? null;
}

function sameSymlinkTarget(destination, source) {
  try {
    return realpathSync(destination) === realpathSync(source);
  } catch {
    try {
      return resolve(dirname(destination), readlinkSync(destination)) === resolve(source);
    } catch {
      return false;
    }
  }
}

function canReplace(destination, entry, source, force) {
  if (!pathExists(destination)) return true;
  if (force) return true;
  if (entry?.mode === 'symlink' && sameSymlinkTarget(destination, source)) return true;
  if (entry?.mode === 'copy' && lstatSync(destination).isFile() && sha256(destination) === entry.sha256) return true;
  return false;
}

function removeFile(path) {
  rmSync(path, { force: true });
}

function print(action, path) {
  console.log(`${action} ${path}`);
}

function install(options) {
  const destinationDir = destinationDirectory(options.scope);
  const { path: metadataFile, data: previous } = readMetadata(destinationDir);
  const entries = { ...(previous?.commands || {}) };
  const blocked = [];
  const plans = [];

  for (const name of options.commands) {
    const source = sourceForCommand(name);
    const destination = join(destinationDir, `${name}.md`);
    const prior = managedEntry(previous, name);
    if (pathExists(destination) && lstatSync(destination).isDirectory()) {
      blocked.push(`${destination} (a directory; refusing to replace it)`);
      continue;
    }
    if (!canReplace(destination, prior, source, options.force)) {
      blocked.push(`${destination} (already exists; use --force only if you intend to replace it)`);
      continue;
    }
    entries[name] = {
      source: relativeSource(source),
      destination: `${name}.md`,
      mode: options.mode,
      sha256: sha256(source),
    };
    plans.push({ name, source, destination });
  }

  if (blocked.length) {
    for (const item of blocked) console.error(`BLOCKED ${item}`);
    process.exitCode = 1;
    return;
  }

  for (const { source, destination } of plans) {
    print(pathExists(destination) ? 'UPDATE' : 'CREATE', destination);
    if (!options.dryRun) {
      mkdirSync(destinationDir, { recursive: true });
      if (pathExists(destination)) removeFile(destination);
      if (options.mode === 'symlink') symlinkSync(source, destination);
      else copyFileSync(source, destination);
    }
  }

  if (!options.dryRun) {
    mkdirSync(destinationDir, { recursive: true });
    const metadata = {
      schemaVersion: 1,
      package: 'git-stack',
      scope: options.scope,
      commands: entries,
    };
    writeFileSync(metadataFile, `${JSON.stringify(metadata, null, 2)}\n`);
  }
  console.log(`${options.dryRun ? 'DRY_RUN' : 'INSTALLED'} scope=${options.scope} mode=${options.mode}`);
}

function uninstall(options) {
  const destinationDir = destinationDirectory(options.scope);
  const { path: metadataFile, data: metadata } = readMetadata(destinationDir);
  if (!metadata?.commands) {
    console.log(`NOTHING_TO_DO scope=${options.scope}`);
    return;
  }

  const blocked = [];
  for (const [name, entry] of Object.entries(metadata.commands)) {
    const destination = join(destinationDir, entry.destination || `${name}.md`);
    if (!pathExists(destination)) continue;
    if (lstatSync(destination).isDirectory()) {
      blocked.push(`${destination} (a directory; refusing to remove it)`);
      continue;
    }
    const source = resolve(PACKAGE_ROOT, entry.source || '');
    const owned = entry.mode === 'symlink'
      ? sameSymlinkTarget(destination, source)
      : lstatSync(destination).isFile() && sha256(destination) === entry.sha256;
    if (!owned && !options.force) {
      blocked.push(`${destination} (changed since installation; use --force to remove)`);
      continue;
    }
    print('REMOVE', destination);
    if (!options.dryRun) removeFile(destination);
  }

  if (blocked.length) {
    for (const item of blocked) console.error(`BLOCKED ${item}`);
    process.exitCode = 1;
    return;
  }
  print('REMOVE', metadataFile);
  if (!options.dryRun) removeFile(metadataFile);
  console.log(`${options.dryRun ? 'DRY_RUN' : 'UNINSTALLED'} scope=${options.scope}`);
}

try {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) usage();
  else if (options.uninstall) uninstall(options);
  else install(options);
} catch (error) {
  console.error(`ERROR ${error.message}`);
  console.error('Run with --help for usage.');
  process.exitCode = 1;
}
