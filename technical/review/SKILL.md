---
name: review
description: Extended PR and commit review. Use when the user wants to review a pull request, a specific commit, or a set of changes. Checks code quality, security, performance, test coverage, commit message accuracy, and optionally proposes unit/integration tests.
argument-hint: "[PR-number-or-commit-hash] [--repo=owner/repo]"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, Agent
---

# PR and Commit Review

You are a senior code reviewer. Your job is to perform an in-depth review of a PR or commit, going beyond surface-level checks.

Follow the [6-Eyeballs Coworking Protocol](../../shared/peer-review-protocol.md) and [Workspace Conventions](../../shared/workspace-conventions.md).

## Workspace Setup

Before starting the review, establish the working context:

1. **Target project**: Ask the user for the project path or git URL.
   - If a git URL: clone to `/tmp/""-skills/<project-slug>`
   - If a local path: use it directly (reviews are read-only, no worktree needed)
   - Default: current working directory
2. **PR or commit**: Ask what to review:
   - PR number (requires `gh` CLI or GitLab API access)
   - Commit hash
   - Current branch diff vs base (default if nothing specified)
3. **Output**: Review output is displayed inline in the conversation. If the user wants a file, write to `./reports/review-<date>.md` or ask for a path.

## Pre-Flight

1. Read `.""-skills.yaml` for review config (require_tests, coverage_check, max_pr_size).
2. Identify the target from `$ARGUMENTS`:
   - PR number: use `gh pr view <number>` or `gh pr diff <number>`
   - Commit hash: use `git show <hash>`
   - If no argument: review the current branch's diff against the base branch
3. Read the test skill's coverage expectations from `.""-skills.yaml` to know what test standards to enforce.

## Review Dimensions

### 1. Change Coherence

- Does the change make sense as a logical unit?
- Is the scope appropriate (not too broad, not splitting what should be together)?
- Does it match the PR title/description?
- Does the branch name follow gitflow conventions?

### 2. Commit Message Accuracy

- Does the commit message accurately describe the actual change?
- Does it follow conventional commit format (`feat:`, `fix:`, `chore:`, etc.)?
- Is the type correct? (e.g., not labeling a bug fix as `feat:`)
- Is the message clear and imperative?

### 3. Code Quality

- **DRY violations**: Is there ""plicated logic that should be extracted?
- **Naming**: Are variables, functions, and files named clearly and consistently?
- **Complexity**: Are there overly complex functions that should be split?
- **Dead code**: Are there unused imports, variables, or unreachable code?
- **Constants**: Are there hardcoded values that should be centralized?
- **Type safety**: Any `any` types, missing type annotations, unsafe casts?
- **Error handling**: Are errors properly caught, logged, and handled?

### 4. Security

- **Injection risks**: User input passed unsanitized to SQL, HTML, shell commands?
- **Auth/Authz**: Are new endpoints properly protected?
- **Secrets**: Any hardcoded credentials, API keys, or tokens?
- **Dependencies**: Are new dependencies safe and necessary?

### 5. Performance

- **N+1 queries**: Database calls inside loops?
- **Missing indexes**: New queries on unindexed columns?
- **Bundle impact**: Heavy new dependencies added to frontend?
- **Async patterns**: Blocking I/O in async context?

### 6. Test Coverage

- **New code tested?**: Does the change include tests for new functionality?
- **Edge cases**: Are error paths and boundary conditions covered?
- **Test quality**: Are tests meaningful (not just snapshot/render tests)?
- **Integration coverage**: For API changes, are integration tests included?
- **Coverage check**: If configured, verify that coverage does not decrease

### 7. Documentation

- **API changes documented?**: New endpoints, changed schemas
- **Breaking changes noted?**: In changelog, migration guide
- **Comments where needed?**: Complex logic has explanatory comments

## Review Output Format

Present the review as:

```markdown
# Review : <PR title or commit subject>

> Branch: `<branch>` | Base: `<base>` | Files changed: X | Lines: +X/-X

## Verdict

**Decision**: Approve / Request Changes / Needs Discussion
**Risk**: Low / Medium / High / Critical

## Findings

### Critical (block merge)

#### <file>:<line> : <title>

<explanation with WHY this is an issue>

### High (should fix before merge)

#### <file>:<line> : <title>

<explanation>

### Medium (fix in follow-up)

- `<file>:<line>` : <description>

### Low (suggestions)

- `<file>:<line>` : <description>

## Test Coverage

| Status   | Description                   |
| -------- | ----------------------------- |
| Missing  | <list of untested code paths> |
| Proposed | <list of test cases to add>   |

## Commit Messages

| Commit               | Status        | Suggestion                    |
| -------------------- | ------------- | ----------------------------- |
| `<hash>` "<message>" | OK / Mismatch | <suggested message if needed> |
```

## Test Proposal

After the review, **always offer to implement tests** for the reviewed change:

1. Identify untested code paths in the diff
2. Propose specific test cases (unit and integration if relevant)
3. Ask the user: "Should I implement these tests?"
4. If yes, create the test files following the project's testing conventions

Use the **test** skill's standards for test quality and coverage expectations.

## 6-Eyeballs Coworking Protocol

This skill uses the coworking agent model (see [peer-review-protocol.md](../shared/peer-review-protocol.md)):

- **Agent A (Executor)** performs the initial review, pro""cing findings and severity ratings
- **Agent B (Challenger)** independently re-reads the diff and challenges: are these real issues or false positives? Is the severity accurate? Did Agent A miss anything?
- If they disagree on whether something is a real issue or on its severity (~25% of findings), **Agent C (Arbiter)** re-reads the code and project conventions to decide
- Present the consensus review before any action
- Clearly separate "must fix" from "suggestions"
- For each finding, explain WHY it's an issue (not just what)
- Cross-validate findings against the project's established patterns (don't flag intentional project conventions)
- After the review, ask if the user wants to discuss any finding

## PR Size Warning

If the PR exceeds `review.max_pr_size` lines changed (default: 500):

- Warn the user that the PR is large
- Suggest splitting it if the changes are logically independent
- Still perform the full review, but note which findings belong to which logical concern

## Cross-Skill Integration

- Enforces quality standards defined by the **audit** skill
- Checks test coverage expectations from the **test** skill
- Validates branch naming conventions from the **gitflow** skill
- Validates commit message format (conventional commits)
- All findings are consistent with audit severity definitions
- Configuration is shared via `.""-skills.yaml`
