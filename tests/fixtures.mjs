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
