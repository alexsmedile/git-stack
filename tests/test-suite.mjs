import { strict as assert } from "node:assert";
import { execSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import {
  createCleanRepo,
  createFileOverlapRepo,
  createHygieneRepo,
  createOccupiedWorktreeRepo,
  createStackedBranchesRepo,
} from "./fixtures.mjs";

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

test("Deterministic State Inspector (git-stack.sh state)", async (t) => {
  await t.test("reports clean state correctly on main", () => {
    const repo = createCleanRepo();
    try {
      const res = runGitStack("state", [], repo.dir);
      assert.equal(res.code, 0);
      const parsed = parseKeyVal(res.stdout);
      assert.equal(parsed.OP, "state");
      assert.equal(parsed.BRANCH, "main");
      assert.equal(parsed.STAGED, "0");
      assert.equal(parsed.UNSTAGED, "0");
      assert.equal(parsed.UNTRACKED, "0");
      assert.equal(parsed.INTERRUPTED, "NONE");
      assert.equal(parsed.WORKTREES, "1");
      assert.equal(parsed.VERDICT, "OBSERVED");
    } finally {
      repo.cleanup();
    }
  });

  await t.test("reports target path properties and overlap correctly", () => {
    const repo = createFileOverlapRepo();
    try {
      // On feat/feature-b: target shared.txt exists and was touched on feat/feature-a
      const res = runGitStack("state", ["--path", "shared.txt", "--path", "other.txt"], repo.dir);
      assert.equal(res.code, 0);
      const parsed = parseKeyVal(res.stdout);
      assert.equal(parsed.TARGET_1_PATH, "shared.txt");
      assert.equal(parsed.TARGET_1_EXISTS, "no"); // was committed on feature-a, not yet merged to main
      assert.notEqual(parsed.TARGET_1_OVERLAP, "NONE"); // branch feat/feature-a touched it
      assert.equal(parsed.TARGET_2_PATH, "other.txt");
      assert.equal(parsed.TARGET_2_EXISTS, "yes");
    } finally {
      repo.cleanup();
    }
  });

  await t.test("detects occupied linked worktrees and their dirty status", () => {
    const repo = createOccupiedWorktreeRepo();
    try {
      const res = runGitStack("state", [], repo.dir);
      assert.equal(res.code, 0);
      const parsed = parseKeyVal(res.stdout);
      assert.equal(parsed.WORKTREES, "2");
      assert.equal(parsed.WORKTREE_2_BRANCH, "feat/wt-branch");
      assert.equal(parsed.WORKTREE_2_DIRTY, "1");
    } finally {
      repo.cleanup();
    }
  });
});

test("Safety Preflights (git-stack.sh commit & push)", async (t) => {
  await t.test("blocks committing directly to main without --allow-main", () => {
    const repo = createCleanRepo();
    try {
      fs.writeFileSync(path.join(repo.dir, "test.txt"), "New change\n");
      repo.run("git add test.txt");

      const res = runGitStack("commit", [], repo.dir);
      assert.equal(res.code, 1); // blocked
      const parsed = parseKeyVal(res.stdout);
      assert.equal(parsed.VERDICT, "BLOCKED");
      assert.ok(parsed.blockers.some((b) => b.includes("direct-write-to-default-branch") || b.includes("main")));
    } finally {
      repo.cleanup();
    }
  });

  await t.test("blocks committing staged secrets", () => {
    const repo = createCleanRepo();
    try {
      repo.run("git checkout -b feat/secret-test");
      fs.writeFileSync(path.join(repo.dir, "config.js"), 'const key = "sk-proj-1234567890abcdef1234567890abcdef12345678";\n');
      repo.run("git add config.js");

      const res = runGitStack("commit", [], repo.dir);
      assert.equal(res.code, 1, `expected blocked commit, got: ${res.stdout}`);
      const parsed = parseKeyVal(res.stdout);
      assert.equal(parsed.VERDICT, "BLOCKED");
      assert.ok(parsed.blockers.some((b) => b.includes("secret") || b.includes("staged-env-file")));
    } finally {
      repo.cleanup();
    }
  });

  await t.test("executes clean commit when on feature branch", () => {
    const repo = createCleanRepo();
    try {
      repo.run("git checkout -b feat/clean-test");
      fs.writeFileSync(path.join(repo.dir, "feature.txt"), "Feature code\n");
      repo.run("git add feature.txt");

      const resCheck = runGitStack("commit", [], repo.dir);
      assert.equal(resCheck.code, 0, `commit check failed: code=${resCheck.code}, out=${resCheck.stdout}, err=${resCheck.stderr}`);
      assert.equal(parseKeyVal(resCheck.stdout).VERDICT, "CLEAN");

      const resExec = runGitStack("commit", ["--execute", "--message", '"feat: add feature code"'], repo.dir);
      assert.equal(resExec.code, 0, `commit exec failed: code=${resExec.code}, out=${resExec.stdout}, err=${resExec.stderr}`);
      const parsed = parseKeyVal(resExec.stdout);
      assert.equal(parsed.VERDICT, "DONE");
      assert.match(parsed.COMMIT, /feat: add feature code/);
    } finally {
      repo.cleanup();
    }
  });
});

test("Repo Hygiene Engine (git-stack.sh cleanup)", async (t) => {
  await t.test("detects merged branches, stashes, and untracked junk", () => {
    const repo = createHygieneRepo();
    try {
      const res = runGitStack("cleanup", ["--no-fetch"], repo.dir);
      assert.equal(res.code, 0, `cleanup failed: ${res.stderr}`);
      const parsed = parseKeyVal(res.stdout);
      assert.ok(Number(parsed.BRANCHES_MERGED) >= 1, `expected BRANCHES_MERGED >= 1, got ${parsed.BRANCHES_MERGED} (out: ${res.stdout})`);
      assert.ok(Number(parsed.STASHES) >= 1, `expected STASHES >= 1, got ${parsed.STASHES} (out: ${res.stdout})`);
      assert.ok(Number(parsed.TRACKED_JUNK) >= 1, `expected TRACKED_JUNK >= 1, got ${parsed.TRACKED_JUNK} (out: ${res.stdout})`);
    } finally {
      repo.cleanup();
    }
  });
});

test("Clean Merge & Stack Subsumption", async (t) => {
  await t.test("fast-forwards stacked branches and prunes subsumed branches safely", () => {
    const repo = createStackedBranchesRepo();
    try {
      // main is at root; feat/step-3 contains step-1, step-2, step-3
      repo.run("git checkout main");

      // Verify merge base
      const mergeBase = repo.run("git merge-base main feat/step-3").trim();
      const mainHead = repo.run("git rev-parse main").trim();
      assert.equal(mergeBase, mainHead);

      // Fast-forward merge step-3 into main
      repo.run("git merge --ff-only feat/step-3");

      // Verify merged branches
      const mergedBranches = repo.run("git branch --merged main")
        .split("\n")
        .map((s) => s.replace(/^\*?\s+/, "").trim())
        .filter(Boolean);

      assert.ok(mergedBranches.includes("feat/step-1"));
      assert.ok(mergedBranches.includes("feat/step-2"));
      assert.ok(mergedBranches.includes("feat/step-3"));

      // Prune merged branches safely with git branch -d
      repo.run("git branch -d feat/step-1 feat/step-2 feat/step-3");

      const remainingBranches = repo.run("git branch")
        .split("\n")
        .map((s) => s.replace(/^\*?\s+/, "").trim())
        .filter(Boolean);

      assert.deepEqual(remainingBranches, ["main"]);
    } finally {
      repo.cleanup();
    }
  });
});

test("Governance & Manifest Integrity", async (t) => {
  await t.test("scripts are in sync across all skills", () => {
    const res = execSync(`node "${path.join(rootDir, "src/sync-scripts.mjs")}" --check`, {
      encoding: "utf8",
      cwd: rootDir,
    });
    assert.match(res, /SYNC=CLEAN/);
  });

  await t.test("manifests pass integrity checks across all ecosystems", () => {
    const res = execSync(`bash "${path.join(rootDir, "src/scripts/check-manifests.sh")}"`, {
      encoding: "utf8",
      cwd: rootDir,
    });
    assert.match(res, /Project-level versions aligned/);
  });

  await t.test("all skill files remain under 500 lines", () => {
    const skillFiles = [
      "skills/git-ops/SKILL.md",
      "skills/repo-governance/SKILL.md",
      "skills/repo-guardrails/SKILL.md",
      "skills/repo-hygiene/SKILL.md",
      "skills/repo-prettifier/SKILL.md",
      "skills/update-docs/SKILL.md",
      "skills/repo-governance/references/orient.md",
      "skills/repo-governance/references/workstreams.md",
      "skills/repo-governance/references/recover.md",
      "skills/git-ops/references/operations.md",
      "skills/git-ops/references/workflows.md",
    ];

    for (const relPath of skillFiles) {
      const fullPath = path.join(rootDir, relPath);
      if (fs.existsSync(fullPath)) {
        const lines = fs.readFileSync(fullPath, "utf8").split("\n").length;
        assert.ok(lines < 500, `${relPath} is ${lines} lines (must be < 500)`);
      }
    }
  });
});
