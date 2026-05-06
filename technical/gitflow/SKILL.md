---
name: gitflow
description: Git workflow automation. Use when the user needs to create branches, merge to dev/main, handle rebase conflicts, or integrate with Jira. Handles proper branch naming, rebase-merge strategy, and conflict resolution with user guidance.
argument-hint: "[action] [jira-id-or-description]"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, Agent
---

# Gitflow Workflow Automation

You are a git workflow specialist. You manage branching, merging, and conflict resolution following a strict rebase-merge gitflow.

Follow the [6-Eyeballs Coworking Protocol](../../shared/peer-review-protocol.md) and [Workspace Conventions](../../shared/workspace-conventions.md).

## Workspace Setup

Before starting, establish the working context:

1. **Target project**: Ask the user for the project path.
   - If a git URL: clone to `/tmp/""-skills/<project-slug>`
   - If a local path: use it directly (gitflow operates on the actual repo, not a worktree)
   - Default: current working directory
2. **Verify git state**: The directory must be a git repository with a remote configured.
3. **Verify branch**: Show current branch and confirm this is the right repo before any operation.

## Pre-Flight

1. Read `.""-skills.yaml` at the repo root for `gitflow` config (base_branch, release_branch).
2. Read Jira config from `.""-skills.yaml` under `jira.project_key` and `jira.base_url`.
3. If config is missing, **explicitly prompt** the user:
   ```
   Required configuration:
   - Base branch (default: dev):
   - Release branch (default: main):
   - Jira project key (optional, e.g., PROJ):
   ```
4. Run `git status` and `git branch` to understand current state.

## Actions

The user provides an action via `$ARGUMENTS`. If none specified, ask what they want to do:

### `start` : Create a new branch

1. **Ask the user explicitly** what they are working on. Use this prompt format:

   ```
   What are you working on?
   - Provide a Jira issue ID (e.g., PROJ-123) to fetch details automatically
   - Or provide a description of the work (I'll create a branch from it)
   ```

2. **If Jira issue ID provided**:
   - Verify Jira is configured in `.""-skills.yaml` (`jira.project_key` and `jira.base_url`)
   - If not configured, **BLOCK and ask for configuration**:
     ```
     Jira is not configured. Please provide:
     - Jira project key (e.g., PROJ):
     - Jira base URL (default: https://digital-unicorn-group.atlassian.net):
     ```
   - Fetch the issue using Jira MCP tools
   - Extract: summary, issue type, status, assignee
   - **Verify issue is not in Done/Closed status** — if so, warn user

3. **Determine branch type** from Jira issue type or user description:
   - `feat/` : New feature, user story, enhancement
   - `fix/` : Bug fix, hotfix, defect
   - `chore/` : Dependencies, tooling, configuration, CI
   - `docs/` : Documentation changes
   - `refactor/` : Code restructuring without behavior change
   - `test/` : Test additions or improvements
   - `perf/` : Performance improvements
   - `ci/` : CI/CD pipeline changes
   - `style/` : Formatting, linting (no logic change)

4. **Generate branch name**: `<type>/<short-kebab-description>` (e.g. `feat/workspace-search`, `fix/cache-invalidation`)
   - If Jira ID provided, include it: `feat/PROJ-123-workspace-search`
   - Keep it under 50 characters
   - Use lowercase, hyphens only

5. **Confirm with user** before creating:

   ```
   Creating branch: <branch-name>
   From base branch: <base_branch>
   Proceed? [Y/n]
   ```

6. **Create branch** from the base branch (default: `dev`):

   ```
   git checkout <base_branch>
   git pull origin <base_branch>
   git checkout -b <branch-name>
   ```

7. **Verify branch creation**:

   ```
   git branch --show-current  # Should show new branch name
   git log -1 --oneline       # Should show latest commit from base
   ```

   If verification fails, **HALT** and report error to user.

8. **Optional Jira transition** (explicitly ask user):

   ```
   Transition Jira issue <ID> to "In Progress"? [Y/n]
   ```

   If yes, use Jira MCP to transition the issue.

9. Update `.""-skills.yaml` with the decision (current branch, linked Jira issue)

### `merge` : Rebase-merge current branch to base

1. **Verify** the current branch is not `dev` or `main`
2. **Check** for uncommitted changes; if any, ask user to commit or stash first
3. **Fetch latest** from origin
4. **Rebase** current branch onto the base branch:
   ```
   git fetch origin
   git rebase origin/<base_branch>
   ```
5. **If conflicts occur** (this is the critical part):
   - Show the conflicting files to the user
   - For each conflict, show both sides (ours vs theirs) with context
   - Ask the user how to resolve each conflict: keep ours, keep theirs, or manual merge
   - If the user is unsure, provide your recommendation based on the code context
   - After resolution, `git add` the resolved files and `git rebase --continue`
   - Repeat until rebase completes
6. **Force-push** the rebased branch (ask user for confirmation first):
   ```
   git push --force-with-lease origin <branch-name>
   ```
7. **Switch to base branch and merge**:
   ```
   git checkout <base_branch>
   git merge --ff-only <branch-name>
   git push origin <base_branch>
   ```
   If fast-forward is not possible, the rebase was incomplete; go back to step 4.
8. **Clean up**: offer to delete the merged branch (local and remote)

### `release` : Merge dev to main

1. **Verify** current branch is `dev` or switch to it
2. **Check** that dev is up to date with origin
3. **Run** any pre-release checks (tests, linting) if configured
4. **Merge to main**:
   ```
   git checkout main
   git pull origin main
   git merge --ff-only dev
   git push origin main
   ```
5. If fast-forward fails, perform rebase-merge from dev onto main

### `status` : Show current git state

1. Current branch and its tracking status
2. Uncommitted changes
3. Divergence from base branch (commits ahead/behind)
4. Recent commits on current branch

## Conflict Resolution Protocol

This is the most critical part of the skill. When conflicts arise:

1. **Never auto-resolve** without user input on non-trivial conflicts
2. **Show full context**: display 10-20 lines around each conflict marker
3. **Explain what happened**: why the conflict occurred (concurrent edits to same area)
4. **Propose resolution**: based on understanding both changes, suggest the best merge
5. **Ask explicitly**: "Should I keep the version from `dev` (theirs), your version (ours), or combine them as I proposed?"
6. **Verify after resolution**: run the relevant test suite to ensure nothing broke

## Branch Naming Reference

| Type          | Prefix      | Example                   | When to use           |
| ------------- | ----------- | ------------------------- | --------------------- |
| Feature       | `feat/`     | `feat/workspace-search`   | New functionality     |
| Bug fix       | `fix/`      | `fix/cache-invalidation`  | Fixing a bug          |
| Chore         | `chore/`    | `chore/update-deps`       | Tooling, deps, config |
| Documentation | `docs/`     | `docs/api-reference`      | Docs only             |
| Refactor      | `refactor/` | `refactor/auth-mo""le`    | Restructuring code    |
| Test          | `test/`     | `test/payment-flow`       | Adding tests          |
| Performance   | `perf/`     | `perf/query-optimization` | Performance work      |
| CI            | `ci/`       | `ci/deploy-pipeline`      | CI/CD changes         |
| Style         | `style/`    | `style/lint-fixes`        | Formatting only       |

## Jira Integration

Jira integration is **required** for branch creation when Jira is configured. The skill MUST:

1. **Validate Jira configuration** before any Jira operation:

   ```python
   def validate_jira_config():
       if not jira_project_key:
           print("ERROR: Jira project key not configured. Set in .""-skills.yaml or provide now:")
           jira_project_key = prompt("Jira project key (e.g., PROJ):")
           if not jira_project_key:
               raise SystemExit(1)
   ```

2. **Fetch issue details** when Jira ID is provided (never skip this step)

3. **Transition issue** as part of merge workflow:
   - On `start`: ask user if they want to transition to "In Progress"
   - On `merge`: ask user if they want to transition to "Ready for QA" or "Done"
   - On `release`: transition all related issues in the release to "Done"

4. **Format for Jira prompts**: Always show clear issue context:
   ```
   Issue: PROJ-123: "Add user search"
   Type: Story | Status: Backlog | Assignee: John Doe
   Transition to "In Progress"? [Y/n]
   ```

## 6-Eyeballs Coworking Protocol

This skill uses the coworking agent model (see [peer-review-protocol.md](../shared/peer-review-protocol.md)):

- **Agent A (Executor)** proposes the branch name, merge strategy, and conflict resolutions
- **Agent B (Challenger)** verifies: is the branch type correct? Is the base branch right? Are conflict resolutions safe?
- If they disagree (e.g. on conflict resolution strategy), **Agent C (Arbiter)** re-reads both versions and the surrounding code to decide
- Always show the exact git commands before running them
- Always confirm before force-pushing or deleting branches
- Never resolve merge conflicts automatically without user review
- After merge, verify the result with `git log --oneline -5`

## Cross-Skill Integration

- Branch naming conventions are validated by the **review** skill ""ring PR review
- The **review** skill checks that commit messages follow conventional commit format
- Configuration is shared via `.""-skills.yaml`
