import { strict as assert } from "node:assert";
import { execSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import {
  createCleanRepo,
  createDetachedHeadRepo,
  createFakeUpstreamRepo,
  createInterruptedMergeRepo,
  createInterruptedRebaseRepo,
  createMergedOverlapRepo,
  createMultiOverlapRepo,
  createTempRepo,
  createUnbornRepo,
} from "./fixtures.mjs";

// Hard/adversarial cases for the deterministic layer. Every assertion here is
// something a governance skill must be able to SEE before it routes — if the
// script cannot report it, no skill prose can compensate.

const rootDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const gitStackScript = path.join(rootDir, "src/scripts/git-stack.sh");

function runGitStack(op, args = [], cwd = rootDir) {
  try {
    const stdout = execSync(`bash "${gitStackScript}" ${op} ${args.join(" ")}`, {
      cwd,
      encoding: "utf8",
      env: { ...process.env },
      stdio: ["pipe", "pipe", "pipe"],
    });
    return { code: 0, stdout };
  } catch (err) {
    return {
      code: err.status,
      stdout: err.stdout ? err.stdout.toString() : "",
      stderr: err.stderr ? err.stderr.toString() : "",
    };
  }
}

function parseKeyVal(stdout) {
  const result = { blockers: [], warnings: [] };
  for (const line of stdout.split("\n")) {
    const idx = line.indexOf("=");
    if (idx !== -1) {
      const k = line.slice(0, idx);
      const v = line.slice(idx + 1);
      if (k === "BLOCKER") result.blockers.push(v);
      else if (k === "WARNING") result.warnings.push(v);
      else result[k] = v;
    }
  }
  return result;
}

test("Hard state inspection", async (t) => {
  await t.test("detached HEAD is named, not guessed", () => {
    const repo = createDetachedHeadRepo();
    try {
      const parsed = parseKeyVal(runGitStack("state", [], repo.dir).stdout);
      assert.equal(parsed.BRANCH, "DETACHED");
    } finally {
      repo.cleanup();
    }
  });

  await t.test("unborn repository does not crash or lie", () => {
    const repo = createUnbornRepo();
    try {
      const res = runGitStack("state", [], repo.dir);
      assert.equal(res.code, 0, res.stderr);
      const parsed = parseKeyVal(res.stdout);
      assert.equal(parsed.VERDICT, "OBSERVED");
      // No commits exist: ahead/behind must not fabricate numbers against a
      // nonexistent upstream.
      assert.ok(["NONE", ""].includes(parsed.UPSTREAM));
    } finally {
      repo.cleanup();
    }
  });

  await t.test("interrupted merge is surfaced as INTERRUPTED", () => {
    const repo = createInterruptedMergeRepo();
    try {
      const parsed = parseKeyVal(runGitStack("state", [], repo.dir).stdout);
      assert.equal(parsed.INTERRUPTED, "MERGE_HEAD");
    } finally {
      repo.cleanup();
    }
  });

  await t.test("interrupted rebase is surfaced as INTERRUPTED", () => {
    const repo = createInterruptedRebaseRepo();
    try {
      const parsed = parseKeyVal(runGitStack("state", [], repo.dir).stdout);
      assert.equal(parsed.INTERRUPTED, "REBASE");
    } finally {
      repo.cleanup();
    }
  });

  await t.test("state counts stashes so resets cannot strand them silently", () => {
    const repo = createCleanRepo();
    try {
      fs.writeFileSync(path.join(repo.dir, "wip.txt"), "wip\n");
      repo.run("git add wip.txt");
      repo.run("git stash push -m hard-test-stash");
      const parsed = parseKeyVal(runGitStack("state", [], repo.dir).stdout);
      assert.equal(parsed.STASHES, "1");
    } finally {
      repo.cleanup();
    }
  });

  await t.test("fake upstream divergence reports AHEAD and BEHIND without network", () => {
    const repo = createFakeUpstreamRepo();
    try {
      const parsed = parseKeyVal(runGitStack("state", [], repo.dir).stdout);
      assert.equal(parsed.UPSTREAM, "origin/main");
      assert.equal(parsed.AHEAD, "1");
      assert.equal(parsed.BEHIND, "1");
    } finally {
      repo.cleanup();
    }
  });

  await t.test("target paths containing spaces are handled", () => {
    const repo = createCleanRepo();
    try {
      fs.writeFileSync(path.join(repo.dir, "my file.txt"), "x\n");
      repo.run("git add 'my file.txt'");
      const res = runGitStack("state", ["--path", "'my file.txt'"], repo.dir);
      const parsed = parseKeyVal(res.stdout);
      assert.equal(parsed.TARGET_1_EXISTS, "yes");
      assert.equal(parsed.TARGETS, "1");
    } finally {
      repo.cleanup();
    }
  });
});

test("Hard overlap evidence", async (t) => {
  await t.test("overlap names every branch carrying unmerged commits on the path", () => {
    const repo = createMultiOverlapRepo();
    try {
      const parsed = parseKeyVal(
        runGitStack("state", ["--path", "shared.txt"], repo.dir).stdout
      );
      assert.match(parsed.TARGET_1_OVERLAP, /feat\/overlap-a/);
      assert.match(parsed.TARGET_1_OVERLAP, /feat\/overlap-b/);
    } finally {
      repo.cleanup();
    }
  });

  await t.test("fully merged branches do not count as overlap", () => {
    const repo = createMergedOverlapRepo();
    try {
      const parsed = parseKeyVal(
        runGitStack("state", ["--path", "shared.txt"], repo.dir).stdout
      );
      assert.equal(parsed.TARGET_1_OVERLAP, "NONE");
    } finally {
      repo.cleanup();
    }
  });

  await t.test("overlap is path-scoped, not repository-wide", () => {
    const repo = createMultiOverlapRepo();
    try {
      const parsed = parseKeyVal(
        runGitStack("state", ["--path", "unrelated.txt"], repo.dir).stdout
      );
      assert.equal(parsed.TARGET_1_OVERLAP, "NONE");
    } finally {
      repo.cleanup();
    }
  });
});

test("Hard commit gates", async (t) => {
  await t.test(".env.local variant is blocked, not just plain .env", () => {
    const repo = createTempRepo();
    try {
      repo.run("git checkout -b feat/env-variant");
      fs.writeFileSync(path.join(repo.dir, ".env.local"), "SECRET=1\n");
      repo.run("git add .env.local");
      const res = runGitStack("commit", ["--allow-main"], repo.dir);
      const parsed = parseKeyVal(res.stdout);
      assert.equal(parsed.VERDICT, "BLOCKED");
      assert.ok(parsed.blockers.some((b) => b.includes("env")));
    } finally {
      repo.cleanup();
    }
  });

  await t.test("nested config/.env.production is blocked", () => {
    const repo = createTempRepo();
    try {
      repo.run("git checkout -b feat/nested-env");
      fs.mkdirSync(path.join(repo.dir, "config"));
      fs.writeFileSync(path.join(repo.dir, "config/.env.production"), "SECRET=1\n");
      repo.run("git add config/.env.production");
      const res = runGitStack("commit", ["--allow-main"], repo.dir);
      const parsed = parseKeyVal(res.stdout);
      assert.ok(parsed.blockers.some((b) => b.includes("env")));
    } finally {
      repo.cleanup();
    }
  });

  await t.test("PEM private key block is blocked", () => {
    const repo = createTempRepo();
    try {
      repo.run("git checkout -b feat/pem");
      const pem = [
        "-----BEGIN RSA PRIVATE KEY-----",
        "MIIEpAIBAAKCAQEA7TestTestTestTestTestTestTestTestTest",
        "-----END RSA PRIVATE KEY-----",
      ].join("\n");
      fs.writeFileSync(path.join(repo.dir, "server.key"), pem);
      repo.run("git add server.key");
      const res = runGitStack("commit", ["--allow-main"], repo.dir);
      const parsed = parseKeyVal(res.stdout);
      assert.equal(parsed.VERDICT, "BLOCKED");
      assert.ok(
        parsed.blockers.some((b) => b.includes("secret") || b.includes("gitleaks"))
      );
    } finally {
      repo.cleanup();
    }
  });

  await t.test("oversized file is blocked and --allow-large releases the gate", () => {
    const repo = createTempRepo();
    try {
      repo.run("git checkout -b feat/big");
      fs.writeFileSync(path.join(repo.dir, "big.bin"), Buffer.alloc(600 * 1024, "a"));
      repo.run("git add big.bin");
      const blocked = parseKeyVal(runGitStack("commit", ["--allow-main"], repo.dir).stdout);
      assert.ok(blocked.blockers.some((b) => b.includes("over-500KB")));
      const allowed = parseKeyVal(
        runGitStack("commit", ["--allow-main", "--allow-large"], repo.dir).stdout
      );
      assert.notEqual(allowed.VERDICT, "BLOCKED");
    } finally {
      repo.cleanup();
    }
  });
});

test("Hard push and tag gates", async (t) => {
  await t.test("diverged branch blocks push instead of overwriting remote", () => {
    const repo = createFakeUpstreamRepo();
    try {
      const res = runGitStack("push", ["--no-fetch"], repo.dir);
      assert.equal(res.code, 1);
      const parsed = parseKeyVal(res.stdout);
      assert.ok(parsed.blockers.some((b) => b.startsWith("branch-behind-upstream")));
    } finally {
      repo.cleanup();
    }
  });

  await t.test("tagging outside the default branch is blocked even when clean", () => {
    const repo = createCleanRepo();
    try {
      repo.run("git checkout -b feat/tag-here");
      const res = runGitStack("tag", ["--version", "9.9.9"], repo.dir);
      const parsed = parseKeyVal(res.stdout);
      assert.ok(parsed.blockers.some((b) => b.startsWith("tag-requires-default-branch")));
    } finally {
      repo.cleanup();
    }
  });

  await t.test("duplicate tag version is blocked", () => {
    const repo = createCleanRepo();
    try {
      repo.run("git tag v1.0.0");
      const res = runGitStack("tag", ["--version", "1.0.0"], repo.dir);
      const parsed = parseKeyVal(res.stdout);
      assert.ok(parsed.blockers.some((b) => b.startsWith("tag-exists")));
    } finally {
      repo.cleanup();
    }
  });

  await t.test("release refuses a dirty working tree", () => {
    const repo = createCleanRepo();
    try {
      fs.writeFileSync(path.join(repo.dir, "dirty.txt"), "uncommitted\n");
      const res = runGitStack("release", ["--version", "2.0.0"], repo.dir);
      assert.equal(res.code, 1);
      const parsed = parseKeyVal(res.stdout);
      assert.ok(parsed.blockers.some((b) => b === "dirty-working-tree"));
    } finally {
      repo.cleanup();
    }
  });
});
