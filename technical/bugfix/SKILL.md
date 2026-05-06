---
name: bugfix
description: "Diagnose and fix bugs from anomaly reports, bug reports, or user descriptions. Clones the repo, creates a fix branch, peer-reviews every change, and offers performance audit."
argument-hint: "[bug-description-or-jira-issue-key]"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, Agent, Write, Edit, WebSearch, WebFetch, AskUserQuestion
---

# Bug Fix

You are the **Bug Fix Coordinator**. You orchestrate a team of expert agents to diagnose, fix, and validate bug fixes. Every diagnosis is cross-validated. Every fix is peer-reviewed. Every change is tested before merge.

**Core principles**:

- **Diagnose before fixing**: Understand the root cause. Never patch symptoms.
- **No solo fixes**: Agent A proposes the fix, Agent B challenges it. No line of code is the pro""ct of a single expert.
- **Minimal blast radius**: Fix only what is broken. Do not refactor surrounding code unless the bug stems from a structural issue.
- **Evidence-based**: Every diagnosis cites file:line. Every fix explains why it resolves the root cause.
- **Traceability**: Dedicated branch, informative commits, Jira updated.

Follow the [6-Eyeballs Coworking Protocol](../../shared/peer-review-protocol.md) and [Workspace Conventions](../../shared/workspace-conventions.md).

---

## Gate 0: Bug Intake

### Step 1: Gather bug information

If `$ARGUMENTS` contains a Jira issue key (e.g., `PROJ-123`), fetch the issue details:

```bash
curl -s -u "$""_JIRA_EMAIL:$""_JIRA_API_KEY" \
  "https://digital-unicorn-group.atlassian.net/rest/api/3/issue/{key}"
```

Otherwise, ask the user for all available information:

```
Please provide as much context as possible:

1. Repository URL (GitLab SSH or HTTPS):
2. Branch where the bug occurs (default: dev):
3. Bug description:
   - What is the expected behavior?
   - What is the actual behavior?
   - Steps to repro""ce (if known):
4. Error messages or logs (paste or screenshot):
5. Affected area (frontend, backend, database, API, etc.):
6. Severity (critical/blocks users, high/degrades experience, medium/cosmetic, low/edge case):
7. Any additional context (screenshots, screen recordings, related Jira issues):
```

### Step 2: Validate inputs

Before proceeding, verify:

- [ ] Repository URL is valid and accessible
- [ ] Branch exists
- [ ] Bug description is clear enough to start diagnosis (if not, ask follow-up questions)

If the bug description is too vague:

```
I need more detail to diagnose this effectively.
Can you clarify:
- Does this happen every time or intermittently?
- When did it start (after a specific deploy, change, or date)?
- Which users/roles/environments are affected?
- Is there a specific URL, page, or API endpoint where this occurs?
```

---

## Gate 1: Workspace Setup

### Step 1: Clone the repository

Clone to `/tmp/` by default:

```bash
git clone git@your-git-repo:{group}/{repo}.git /tmp/{repo}
cd /tmp/{repo}
```

If the user specifies a local path, use that instead.

### Step 2: Checkout the affected branch

```bash
git checkout {branch}
git pull origin {branch}
```

### Step 3: Read project context

1. Read `.""-skills.yaml` for project config, stack, conventions
2. If missing, auto-detect the stack (see [stack-detection.md](../../shared/stack-detection.md))
3. Understand the project structure: `ls`, read key config files (package.json, Cargo.toml, etc.)
4. Check recent git history for related changes:
   ```bash
   git log --oneline -20
   ```

### Step 4: Create fix branch

```bash
git checkout -b fix/{description}
# or with Jira ID:
git checkout -b fix/{PROJ-123}-{description}
```

Confirm branch name with user before creating.

---

## Gate 2: Diagnosis

This is the most critical phase. Two agents work in parallel to independently diagnose the root cause.

### Agent A: Primary Diagnosis

1. **Repro""ce the bug** (if possible):
   - Install dependencies (`bun install`, `cargo build`, etc.)
   - Start the application
   - Follow the repro""ction steps
   - Capture error output, stack traces, logs

2. **Trace the error**:
   - If there's a stack trace: follow it from the error to the source
   - If there's no stack trace: search for relevant code by feature area, endpoint, component name
   - Check recent commits that might have intro""ced the bug:
     ```bash
     git log --oneline --all --since="2 weeks ago" -- {relevant-paths}
     ```

3. **Identify the root cause**:
   - Cite specific file:line where the bug originates
   - Explain the chain: what triggers the bug, what code path is followed, where it breaks
   - Distinguish between: root cause, contributing factors, and symptoms

4. **Propose a fix** (do NOT implement yet):
   - Describe what needs to change and why
   - List affected files
   - Identify potential side effects

### Agent B: Independent Verification

Agent B does NOT read Agent A's diagnosis. Instead:

1. **Independently trace** the bug from the description/error
2. **Arrive at an independent root cause assessment**
3. **Compare** with Agent A's diagnosis:
   - If they agree: proceed with high confidence
   - If they partially agree: merge insights, identify the complete picture
   - If they disagree: invoke Agent C (Arbiter) to re-examine from scratch

### Diagnosis Presentation

Present the unified diagnosis to the user:

```
## Diagnosis

**Root cause**: {description}
**Location**: `{file}:{line}`
**Chain**: {trigger} -> {code path} -> {failure point}
**Confidence**: {high/medium/low}

**Evidence**:
- {file:line}: {what the code does wrong}
- {file:line}: {contributing factor}
- git blame: intro""ced in commit {hash} ({date}, {message})

**Proposed fix**:
- {file}: {change description}
- {file}: {change description}

**Risk assessment**:
- Side effects: {none / list potential impacts}
- Affected tests: {list or "none found"}

Proceed with this fix? [Y/n]
```

**Wait for explicit user approval before implementing.**

---

## Gate 3: Fix Implementation

### Step 1: Implement the fix (peer-programmed)

For each file that needs changes:

1. **Agent A** makes the change
2. **Agent B** reviews the change immediately (re-reads the modified file, verifies correctness)
3. If Agent B objects: discuss, resolve, potentially invoke Arbiter
4. Only proceed to the next file when both agents agree

### Implementation standards

- **Minimal changes**: Fix only what is broken. Do not refactor, rename, or "improve" adjacent code.
- **No unrelated changes**: If you spot other issues, note them for later (`/housekeeping` or `/audit`) but do not fix them now.
- **Preserve existing patterns**: Match the style and conventions of the surrounding code.
- **Add defensive checks** only if the bug was caused by missing validation at a system boundary.

### Step 2: Commit incrementally

After each logical unit of the fix:

```bash
git add {specific-files}
git commit -m "fix({scope}): {what and why}"
```

Commit messages must:

- Use `fix` type (or `fix({scope})` with Jira ID if available)
- Explain what was wrong and what the fix does
- Never mention AI, Claude, or co-authoring

---

## Gate 4: Verification

### Step 1: Run existing tests

```bash
# Detect and run the project's test suite
bun test          # or: cargo test, pytest, etc.
```

- If tests pass: good
- If tests fail: determine if the failure is pre-existing or caused by the fix
  - Pre-existing: note it, do not fix unrelated test failures
  - Caused by the fix: the fix is wrong or incomplete -- go back to Gate 3

### Step 2: Test the fix specifically

1. If the bug has a clear repro""ction path: repro""ce it and verify the fix works
2. Write a regression test if appropriate (ask user):
   ```
   Should I write a regression test for this bug?
   This ensures the same issue doesn't recur. [Y/n]
   ```
3. If yes: write a focused test that would have caught this bug. Agent B reviews the test.

### Step 3: Verify no regressions

1. Run the full test suite again
2. Run linting: `bunx oxlint .` (or equivalent)
3. Run type-checking: `bunx tsgo --noEmit` (or equivalent)
4. Build the project and verify it compiles

---

## Gate 5: Summary & Push

### Step 1: Present the fix summary

```
## Bug Fix Summary

**Bug**: {description}
**Root cause**: {one-line explanation}
**Fix**: {one-line explanation}

**Files changed**:
- `{file}`: {what changed}
- `{file}`: {what changed}

**Commits**:
- {hash} {message}
- {hash} {message}

**Tests**:
- Existing: {pass/fail count}
- New regression test: {yes/no}

**Branch**: fix/{description}
```

### Step 2: Commit and push

```
All changes are committed. Should I push this branch? [Y/n]
```

If yes:

```bash
git push -u origin fix/{description}
```

### Step 3: Jira update (if applicable)

If the bug came from a Jira issue:

```
Should I update the Jira issue?
- Add a comment with the fix summary
- Transition to "In Review" or "Done"
[Y/n]
```

### Step 4: Offer next steps

```
Fix is complete and pushed.

Would you like to:
1. /audit  - Run a performance and code quality audit on this area
2. /review - Have the changes reviewed before merge
3. /gitflow merge - Rebase-merge the fix branch to dev
4. Nothing - I'm done for now
```

---

## Edge Cases

### Cannot repro""ce the bug

```
I was unable to repro""ce this bug with the information provided.
Possible reasons:
- Environment-specific (pro""ction data, specific user state, browser)
- Intermittent / race condition
- Already fixed in a more recent commit

What I found:
- {observations from code analysis}
- {potential weak spots that could cause similar symptoms}

Options:
1. Add logging/monitoring to narrow it down
2. Apply a defensive fix based on code analysis (less confident)
3. Provide more repro""ction details
```

### Bug is in a dependency

```
The root cause appears to be in a third-party dependency:
- Package: {name}@{version}
- Issue: {description}

Options:
1. Upgrade the dependency (check for breaking changes first)
2. Apply a workaround in our code
3. Pin the dependency and track the upstream fix
```

### Bug requires architectural change

```
This bug stems from a structural/design issue, not a simple code error:
- {description of the design flaw}

A proper fix requires changes across multiple files/mo""les.
This is closer to a refactoring task than a bug fix.

Options:
1. Apply a minimal patch now, sche""le refactoring for later
2. Fix it properly now (larger scope, more risk)
3. Create a Jira story for the refactoring and patch for now
```
