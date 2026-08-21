import { execSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

function run(cmd, cwd) {
  return execSync(cmd, {
    cwd,
    encoding: "utf8",
    env: {
      ...process.env,
      GIT_AUTHOR_NAME: "Test Author",
      GIT_AUTHOR_EMAIL: "12345+test@users.noreply.github.com",
      GIT_COMMITTER_NAME: "Test Committer",
      GIT_COMMITTER_EMAIL: "12345+test@users.noreply.github.com",
    },
    stdio: ["pipe", "pipe", "pipe"],
  });
}

export function createTempRepo() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "git-op-test-"));
  run("git init -b main", dir);
  run("git config user.name 'Test Author'", dir);
  run("git config user.email '12345+test@users.noreply.github.com'", dir);

  fs.writeFileSync(path.join(dir, "README.md"), "# Test Repo\nInitial content\n");
  fs.writeFileSync(path.join(dir, ".gitignore"), "node_modules/\n.env\n");
  run("git add README.md .gitignore", dir);
  run("git commit -m 'chore: initial commit'", dir);

  return {
    dir,
    cleanup: () => {
      try {
        fs.rmSync(dir, { recursive: true, force: true });
      } catch {}
    },
    run: (cmd) => run(cmd, dir),
  };
}

export const createCleanRepo = createTempRepo;

export function createStackedBranchesRepo() {
  const repo = createTempRepo();
  const { dir, run } = repo;

  // Branch 1
  run("git checkout -b feat/step-1");
  fs.writeFileSync(path.join(dir, "step1.txt"), "Step 1\n");
  run("git add step1.txt");
  run("git commit -m 'feat: add step 1'");

  // Branch 2
  run("git checkout -b feat/step-2");
  fs.writeFileSync(path.join(dir, "step2.txt"), "Step 2\n");
  run("git add step2.txt");
  run("git commit -m 'feat: add step 2'");

  // Branch 3
  run("git checkout -b feat/step-3");
  fs.writeFileSync(path.join(dir, "step3.txt"), "Step 3\n");
  run("git add step3.txt");
  run("git commit -m 'feat: add step 3'");

  return repo;
}

export function createFileOverlapRepo() {
  const repo = createTempRepo();
  const { dir, run } = repo;

  // Create branch A touching shared.txt
  run("git checkout -b feat/feature-a");
  fs.writeFileSync(path.join(dir, "shared.txt"), "Feature A edits\n");
  run("git add shared.txt");
  run("git commit -m 'feat: update shared in branch A'");

  // Create branch B off main touching different file
  run("git checkout main");
  run("git checkout -b feat/feature-b");
  fs.writeFileSync(path.join(dir, "other.txt"), "Feature B edits\n");
  run("git add other.txt");
  run("git commit -m 'feat: update other in branch B'");

  return repo;
}

export function createOccupiedWorktreeRepo() {
  const repo = createTempRepo();
  const { dir, run } = repo;

  const wtDir = path.join(os.tmpdir(), `git-op-wt-${Date.now()}`);
  run(`git worktree add -b feat/wt-branch "${wtDir}"`);
  fs.writeFileSync(path.join(wtDir, "uncommitted.txt"), "WIP in worktree\n");

  const originalCleanup = repo.cleanup;
  repo.wtDir = wtDir;
  repo.cleanup = () => {
    try {
      fs.rmSync(wtDir, { recursive: true, force: true });
    } catch {}
    originalCleanup();
  };

  return repo;
}

export function createHygieneRepo() {
  const repo = createTempRepo();
  const { dir, run } = repo;

  // Merged branch
  run("git checkout -b feat/merged-branch");
  fs.writeFileSync(path.join(dir, "merged.txt"), "Merged\n");
  run("git add merged.txt");
  run("git commit -m 'feat: add merged file'");
  run("git checkout main");
  run("git merge feat/merged-branch");

  // Unmerged/unsynced branch
  run("git checkout -b feat/unsynced-branch");
  fs.writeFileSync(path.join(dir, "unsynced.txt"), "Unsynced\n");
  run("git add unsynced.txt");
  run("git commit -m 'feat: add unsynced file'");

  // Stash
  fs.writeFileSync(path.join(dir, "stash-me.txt"), "Stashed content\n");
  run("git add stash-me.txt");
  run("git stash push -m 'wip stash'");

  // Tracked junk on main
  run("git checkout main");
  fs.writeFileSync(path.join(dir, ".DS_Store"), "junk");
  run("git add -f .DS_Store");
  run("git commit -m 'chore: accidental junk commit on main'");

  return repo;
}

// --- Hard/adversarial fixtures ------------------------------------------------

export function createDetachedHeadRepo() {
  const repo = createTempRepo();
  repo.run("git checkout --detach HEAD");
  return repo;
}

export function createUnbornRepo() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "git-op-unborn-"));
  execSync("git init -b main", { cwd: dir, encoding: "utf8" });
  return {
    dir,
    cleanup: () => {
      try {
        fs.rmSync(dir, { recursive: true, force: true });
      } catch {}
    },
    run: (cmd) => run(cmd, dir),
  };
}

export function createInterruptedMergeRepo() {
  const repo = createTempRepo();
  const { dir, run } = repo;

  run("git checkout -b feat/side");
  fs.writeFileSync(path.join(dir, "conflict.txt"), "side version\n");
  run("git add conflict.txt");
  run("git commit -m 'feat: side edit'");
  run("git checkout main");
  fs.writeFileSync(path.join(dir, "conflict.txt"), "main version\n");
  run("git add conflict.txt");
  run("git commit -m 'feat: main edit'");
  // Merge that conflicts and is left unresolved.
  try {
    execSync("git merge feat/side", { cwd: dir, encoding: "utf8", stdio: "pipe" });
  } catch {
    // expected conflict
  }
  return repo;
}

export function createInterruptedRebaseRepo() {
  const repo = createTempRepo();
  const { dir, run } = repo;

  run("git checkout -b feat/rebase-me");
  fs.writeFileSync(path.join(dir, "conflict.txt"), "branch version\n");
  run("git add conflict.txt");
  run("git commit -m 'feat: branch edit'");
  run("git checkout main");
  fs.writeFileSync(path.join(dir, "conflict.txt"), "main version\n");
  run("git add conflict.txt");
  run("git commit -m 'feat: main edit'");
  run("git checkout feat/rebase-me");
  try {
    execSync("git rebase main", { cwd: dir, encoding: "utf8", stdio: "pipe" });
  } catch {
    // expected conflict stops the rebase
  }
  return repo;
}

export function createFakeUpstreamRepo() {
  // Local-only "remote": a second ref pretending to be origin/main so
  // ahead/behind math runs without any network.
  const repo = createTempRepo();
  const { dir, run } = repo;

  // alt shares history with main but has one commit main lacks (behind=1)
  run("git checkout -b alt HEAD~0");
  fs.writeFileSync(path.join(dir, "remote-only.txt"), "on remote\n");
  run("git add remote-only.txt");
  run("git commit -m 'feat: exists only on remote'");
  const altSha = execSync("git rev-parse alt", { cwd: dir, encoding: "utf8" }).trim();
  run(`git update-ref refs/remotes/origin/main ${altSha}`);
  // Wire the upstream through config directly: --set-upstream-to demands a
  // real remote-tracking ref lookup, which a fabricated ref does not satisfy.
  run("git remote add origin ./fake-origin.git");
  run("git checkout main");
  fs.writeFileSync(path.join(dir, "local-only.txt"), "local\n");
  run("git add local-only.txt");
  run("git commit -m 'feat: local only'");
  run("git config branch.main.remote origin");
  run("git config branch.main.merge refs/heads/main");

  repo.cleanupOriginal = repo.cleanup;
  repo.cleanup = () => {
    repo.cleanupOriginal();
  };
  return repo;
}

export function createMultiOverlapRepo() {
  const repo = createTempRepo();
  const { dir, run } = repo;

  // Two branches, both carrying distinct unmerged commits touching shared.txt
  run("git checkout -b feat/overlap-a");
  fs.writeFileSync(path.join(dir, "shared.txt"), "A\n");
  run("git add shared.txt");
  run("git commit -m 'feat: A touches shared'");
  run("git checkout main");
  run("git checkout -b feat/overlap-b");
  fs.appendFileSync(path.join(dir, "shared.txt"), "B\n");
  fs.writeFileSync(path.join(dir, "base.txt"), "base\n");
  run("git add shared.txt base.txt");
  run("git commit -m 'feat: B touches shared'");
  run("git checkout main");
  return repo;
}

export function createMergedOverlapRepo() {
  const repo = createTempRepo();
  const { dir, run } = repo;

  // Branch whose commits are fully merged: must NOT count as overlap.
  run("git checkout -b feat/already-merged");
  fs.writeFileSync(path.join(dir, "shared.txt"), "merged content\n");
  run("git add shared.txt");
  run("git commit -m 'feat: will be merged'");
  run("git checkout main");
  run("git merge --ff-only feat/already-merged");
  run("git branch -d feat/already-merged");
  return repo;
}
