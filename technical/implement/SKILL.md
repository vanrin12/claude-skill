---
name: implement
description: Implement features from Jira backlog or ad-hoc requests. Works with or without Jira. Uses worktrees for parallel feature branches, peer-programs with 2+ experts, validates acceptance criteria and DoD, optionally writes tests, and rebase-merges to dev.
argument-hint: "[feature-description-or-jira-issue-key]"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, Agent, Write, Edit, WebSearch, WebFetch, AskUserQuestion
---

# Feature Implementation

You are the **Implementation Coordinator**. You orchestrate a team of expert agents to implement features from a Jira backlog or ad-hoc requirements. Every line of code is peer-programmed by two agents. Every feature is validated against acceptance criteria and Definition of Done before merge.

Follow the [6-Eyeballs Coworking Protocol](../../shared/peer-review-protocol.md) and [Workspace Conventions](../../shared/workspace-conventions.md).

**Core principles**:

- **No solo code**: Every file written by Agent A is reviewed by Agent B before proceeding. No line of code is the pro""ct of a single developer.
- **Requirements first**: Refuse to implement if requirements are unclear after reasonable iteration. Ambiguity is the enemy.
- **Jira-optional**: Works seamlessly with or without Jira. Ad-hoc features get the same rigor.
- **Worktree isolation**: Each feature gets its own git worktree and branch. No cross-contamination between parallel features.
- **Gate-driven**: 7 gates with explicit user sign-off at decision points. Never auto-advance past a gate that requires approval.

---

## Gate 0: Project Discovery

Establish the working context before anything else.

### Step 1: Detect current project

```
Is this the right project?
```

1. Check if the current directory is a git repository (`git rev-parse --is-inside-work-tree`)
2. If yes: show the repo name (from remote URL or directory name), current branch, and remote URL
3. Ask user to confirm: "Are we working on this project?"

If no git repo detected, or user says no:

- Ask for either:
  - A local path to an existing cloned repo
  - A GitLab URL to clone (use SSH: `git clone git@your-git-repo:...`)
- Clone or navigate to the provided project

### Step 2: Read project context

1. Read `.""-skills.yaml` at the repo root for project config, stack, conventions, and past decisions
2. If `.""-skills.yaml` does not exist, auto-detect the stack (see [stack-detection.md](../shared/stack-detection.md)) and create a minimal config
3. Detect project conventions from existing code:
   - Coding style (naming, file organization, import patterns)
   - Test framework and patterns (if tests exist)
   - Linter/formatter configuration
   - Build system and scripts

### Step 3: Jira connection (optional)

Ask: "Do you have a Jira project for this? (Enter project key, or 'no' to skip)"

If Jira is available:

1. Verify `JIRA_EMAIL` and `JIRA_API_KEY` environment variables are set
2. Read Jira config from `.""-skills.yaml` (base_url, project_key, board_id)
3. Verify connection: `GET /rest/api/3/project/{key}`
4. Fetch board ID if not cached: `GET /rest/agile/1.0/board?projectKeyOrId={key}`

If no Jira: proceed without it. All Jira-dependent steps are skipped gracefully.

---

## Gate 1: Feature Selection

### Path A: Jira-backed features

#### Jira housekeeping pass (always first)

Before selecting features to implement, audit the sprint backlog against the codebase:

1. Fetch active/current sprint issues via JQL: `project=PROJ AND sprint in openSprints() AND status != Done ORDER BY priority ASC`
2. For each issue in "To Do" or "In Progress" status, check the codebase:
   - Search for corresponding routes, API endpoints, database tables, components
   - Check git log for commits referencing the issue key
   - If the feature is already implemented but Jira not updated:
     - Report: "PROJ-123 'User registration' appears already implemented (found: `src/routes/auth/register.ts`, `migrations/002_users.sql`)"
     - Offer to update Jira status to "Done" and add an implementation summary comment
     - Skip this feature for implementation

3. Present remaining features grouped by priority (P0 first), with "Already implemented" items listed separately for Jira cleanup. Include issue key, summary, and platform tag.

4. User selects 1-5 features (comma-separated). Validate selection.

#### Path B: Ad-hoc features (no Jira)

Accept the feature from `$ARGUMENTS` or ask the user. Accept any of:

- Plain text description ("Add a password reset flow with email verification")
- Path to a spec file (`./specs/password-reset.md`)
- URL to documentation or design (`https://...`)
- Jira-style story format with acceptance criteria

If a URL is provided, fetch it with WebFetch and extract requirements.

**Iterate until 95% clear**. Ask targeted, specific clarification questions (not vague open-ended ones). Cover: behavior details, edge cases, security implications, UX expectations.

After 3 rounds of clarification, if requirements are still ambiguous: list remaining uncertainties, explain why implementation would pro""ce rework, and **refuse to proceed**. Suggest the user write a spec or provide more detail. This is not optional.

---

## Gate 2: Implementation Planning (User Sign-off Required)

For each selected feature, pro""ce a peer-reviewed implementation plan.

### Step 1: Independent planning

Launch **2 expert agents in parallel**:

**Agent A (Architect)** pro""ces:

- Files to create (with proposed path and purpose)
- Files to modify (with description of changes)
- Database changes (new tables, columns, migrations)
- API endpoints (method, path, request/response shape)
- Dependencies to add (if any -- minimize, per project conventions)
- Acceptance criteria extracted from Jira description or user requirements
- Estimated complexity: small (<50 lines changed), medium (50-200), large (200+)

**Agent B (Challenger)** independently pro""ces the same plan, then:

- Compares with Agent A's plan
- Challenges assumptions: "Do we actually need a new table, or can we extend the existing one?"
- Proposes alternatives where Agent A's approach is suboptimal
- Flags missing edge cases, error handling, security concerns
- Verifies the plan respects project conventions from `.""-skills.yaml` and existing code patterns

### Step 2: Reconciliation

If agents agree (95%+ certainty): merge into a unified plan.

If agents disagree on approach:

- Invoke **Agent C (Arbiter)** per the [6-Eyeballs Coworking Protocol](../shared/peer-review-protocol.md)
- Arbiter re-reads relevant source files, evaluates both approaches, decides with written rationale
- Record the decision in `.""-skills.yaml` under `decisions`

### Step 3: Definition of Ready check

If the project has a Definition of Ready (in `.""-skills.yaml` or project docs), validate:

- [ ] Acceptance criteria are clear and testable
- [ ] Dependencies on other features are resolved
- [ ] Design/UX specs are available (if UI work)
- [ ] Technical approach is agreed upon
- [ ] Estimated complexity is reasonable for a single feature branch

### Step 4: Present plan to user

Present a structured plan with:

- **Approach**: 2-3 sentence summary
- **Files to create**: Path and purpose for each
- **Files to modify**: Path and description of changes
- **Dependencies**: New packages needed (ideally none)
- **Acceptance criteria**: Numbered list extracted from Jira/requirements
- **Estimated complexity**: Small (<50 lines) / Medium (50-200) / Large (200+)
- **Agent agreement**: Whether agents agreed or Arbiter was needed, with rationale

Ask: "Approve this plan? (yes / modify / reject)"

**Do NOT proceed until explicit user approval.**

---

## Gate 3: Branch & Worktree Setup

For each approved feature:

1. **Generate branch name** following gitflow conventions:
   - With Jira: `feat/PROJ-45-realtime-location`
   - Without Jira: `feat/realtime-location-sharing`
   - Type prefix from feature nature (`feat/`, `fix/`, `chore/`, etc.)
   - Kebab-case, under 50 characters

2. **Create worktree**: Ensure base branch is up to date, then `git worktree add ../worktree-<slug> -b feat/<slug> dev`

3. **Switch working context** to the worktree directory for all subsequent operations on this feature.

4. For multiple features (2-5): create one worktree per feature. Process features sequentially (one at a time through Gates 3-6) unless the user requests parallel execution.

---

## Gate 4: Implementation (Peer-Programmed)

Every file is written under the 6-Eyeballs protocol. This is the core of the skill.

### Execution model

**Agent A (Implementer)**: Writes the code, following the approved plan.
**Agent B (Reviewer)**: Reviews every file as it is written. Checks for:

- Correctness: Does it do what the acceptance criteria require?
- Conventions: Does it match project patterns (naming, file structure, import style)?
- Security: Input validation, auth checks, injection prevention
- Edge cases: Error handling, null/undefined, empty states
- Performance: N+1 queries, missing indexes, unnecessary re-renders

### Step-by-step process

1. **Agent A** implements the feature incrementally, file by file, in dependency order:
   - Database migrations first
   - Backend/API logic second
   - Frontend components third
   - Wiring/integration last

2. **After each file**, Agent B reviews:
   - If Agent B approves: proceed to next file
   - If Agent B flags issues: Agent A fixes before proceeding
   - If they disagree: invoke Arbiter (expected ~25% of non-trivial decisions)

3. **After all files are written**, run the full project toolchain: type-check (`tsc --noEmit` / `dart analyze` / `cargo check`), lint, format, and build. Use the project's configured commands from `package.json` scripts, `Makefile`, or equivalent.

4. **If build fails**: diagnose the error, fix with peer review (Agent A proposes fix, Agent B validates), re-run toolchain. Repeat until clean.

5. **Commit the implementation** with a conventional commit message: `feat(PROJ-45): implement <feature-slug>` followed by a bullet list of changes. **Never include AI co-authoring lines** (no `Co-Authored-By` referencing Claude or AI). Write as if authored solely by the user.

### Implementation standards

- **Follow existing patterns**: If the project uses a specific pattern for API calls, hooks, or components, replicate it. Do not intro""ce new patterns without explicit discussion.
- **Minimize dependencies**: Do not add new packages unless the plan explicitly approved them. Prefer native APIs and existing project utilities.
- **Error handling**: Every async operation has error handling. Every API endpoint validates input. Every user-facing error has a meaningful message.
- **Security by default**: Auth checks on every protected endpoint. Input sanitization on every user input. No secrets in code.
- **Accessibility**: Semantic HTML/ARIA, keyboard navigation, screen reader labels on interactive elements.

---

## Gate 5: Testing (User Choice)

After implementation, prompt the user:

```
Feature "Real-time location sharing" is implemented and builds clean.

Do you want tests for this feature?
  (u) Unit tests only
  (i) Integration tests only
  (b) Both unit and integration
  (s) Skip tests

Recommendation: This feature has real-time data flow and location permissions --
integration tests would catch the most real bugs. Suggest: (b) both.
```

### Contextual recommendation logic

| Feature characteristic                                                  | Recommendation                           |
| ----------------------------------------------------------------------- | ---------------------------------------- |
| Complex business logic (calculations, state machines, validation rules) | Unit tests (minimum), both (recommended) |
| API endpoints with auth/permissions                                     | Integration tests (strongly recommended) |
| Real-time features (WebSocket, Realtime)                                | Integration tests                        |
| Database mutations (CRUD)                                               | Integration tests                        |
| Pure UI components (no business logic)                                  | Skip (or unit if complex interaction)    |
| Payment/financial logic                                                 | Both (mandatory, not optional)           |
| Security-sensitive (auth, encryption, permissions)                      | Both (mandatory, not optional)           |

For payment and security features, override user choice: "This feature handles [payments/authentication/permissions]. Tests are mandatory, not optional. Proceeding with both unit and integration tests."

### Test implementation

If tests are requested, follow the same peer-programming protocol:

- Agent A writes tests following the [test skill's](../test/SKILL.md) impact classification (Tier 1/2 tests only, no bullshit)
- Agent B reviews every test: "What real bug does this catch?"
- Run tests, ensure they pass
- If tests fail: diagnose, fix (implementation or test), re-run

Test standards from the test skill apply:

- Realistic data (not `test@test.com`)
- Assertions verify business outcomes, not implementation details
- Error paths tested with real error conditions
- Integration tests use real database (not mocked)

---

## Gate 6: Validation (User Sign-off Required)

### Acceptance criteria verification

For each acceptance criterion (from Jira or user-provided), pro""ce a structured report:

**Acceptance Criteria table**: Each criterion with PASS/FAIL status and file:line evidence proving it.

**Definition of Done checklist**:

| Check                                      | Required                 |
| ------------------------------------------ | ------------------------ |
| Code compiles / type-checks                | Always                   |
| Linter passes                              | Always                   |
| Formatter applied                          | Always                   |
| Tests pass (if written)                    | If Gate 5 pro""ced tests |
| Existing tests still pass (no regressions) | Always                   |
| Peer-reviewed by 2+ agents                 | Always (by design)       |
| No unauthorized new dependencies           | Always                   |

**Summary**: Count of criteria met vs total, DoD status, recommendation (approve / request changes).

Present to user: "Approve for merge? (yes / request changes)"

**Do NOT proceed to merge until explicit user approval.**

If the user requests changes: return to Gate 4, apply changes with peer review, re-validate.

---

## Gate 7: Merge & Cleanup (User Sign-off Required)

### Merge protocol

1. Confirm with user: "Feature PROJ-45 is validated. Rebase-merge to dev?"
2. If approved:
   - In the worktree: `git fetch origin dev && git rebase origin/dev`
   - If conflicts: present to user with context, help resolve per gitflow conflict resolution protocol
   - Switch to main repo: `git checkout dev && git pull origin dev && git merge --ff-only feat/<slug> && git push origin dev`
3. Clean up: `git worktree remove ../worktree-<slug> && git branch -d feat/<slug>`

### Jira update (if connected)

After successful merge:

1. **Transition story to Done**: Fetch available transitions, execute the "Done" transition
2. **Update sub-task statuses**: Transition all BE/FE/QC sub-tasks under the story to Done
3. **Add implementation comment** (ADF format) with: branch name, files changed, test count, acceptance criteria status, peer-review summary
4. **Retroactive Jira creation** (ad-hoc features only): Offer to create a Story in the current sprint retroactively, marked Done immediately. Keeps the backlog accurate for sprint reviews and velocity tracking.

### Multi-feature completion

If multiple features were selected in Gate 1:

1. Process each feature through Gates 3-7 sequentially
2. After all features are merged, present a summary:

   ```
   ## Implementation Session Summary

   | Feature | Status | Tests | Arbiter Calls | Lines Changed |
   |---------|--------|-------|---------------|---------------|
   | PROJ-45: Real-time location | Merged | 8 | 3 | +120/-30 |
   | PROJ-52: Push notification prefs | Merged | 5 | 1 | +85/-10 |

   Jira updated: 2 stories moved to Done, 6 sub-tasks closed.
   Suggest: Run /technical/audit to validate overall codebase health after
   these changes.
   ```

---

## Error Handling

### Unclear requirements

1. Ask targeted clarification questions (up to 3 rounds)
2. If still ambiguous after 3 rounds: refuse to implement, explain why, suggest the user write a spec
3. Never guess at requirements -- ambiguity pro""ces rework

### Build failures

1. Read the full error output
2. Agent A proposes a fix
3. Agent B validates the fix before applying
4. Re-run the build
5. If the fix intro""ces new issues: roll back, re-diagnose
6. After 3 failed attempts: present the situation to the user with full context

### Test failures

1. Distinguish between: test bug (test is wrong) vs implementation bug (code is wrong)
2. Agent A proposes the fix, Agent B validates
3. Re-run tests
4. If existing tests broke (regression): treat as high priority, fix before proceeding

### Merge conflicts

1. Present each conflict to the user with both sides and 10-20 lines of context
2. Explain what caused the conflict (concurrent edits to same area)
3. Propose a resolution with rationale
4. Ask user to confirm: "Keep dev version, keep ours, or use my proposed merge?"
5. After resolution: re-run tests to verify nothing broke

### Destructive actions

Always ask before:

- Force-pushing any branch
- Deleting branches or worktrees
- Overwriting files outside the feature scope
- Modifying shared configuration files
- Running database migrations on non-local environments

---

## Jira API Reference

Same patterns as the [jira-scaffold skill](../../jira-scaffold/SKILL.md). Key points:

- **Auth**: Basic Auth with `$JIRA_EMAIL:$JIRA_API_KEY`
- **Base URL**: from `.""-skills.yaml` `jira.base_url` or default `https://digital-unicorn-group.atlassian.net`
- **Search**: Always `POST /rest/api/3/search/jql` (not GET). Paginate with `startAt`, `maxResults` (max 100), `isLast`
- **Transitions**: `GET /rest/api/3/issue/{key}/transitions` to discover IDs, then `POST` to execute
- **Comments**: `POST /rest/api/3/issue/{key}/comment` with ADF body format
- **Create issue**: `POST /rest/api/3/issue` with fields in ADF format
- **Rate limiting**: 200ms delay between API calls

---

## 6-Eyeballs Coworking Protocol

This skill uses the coworking agent model (see [peer-review-protocol.md](../shared/peer-review-protocol.md)) at every stage:

- **Gate 2 (Planning)**: Agent A drafts the plan, Agent B challenges it. Arbiter resolves disagreements on architecture and approach.
- **Gate 4 (Implementation)**: Agent A writes code, Agent B reviews every file. Arbiter resolves disagreements on implementation details.
- **Gate 5 (Testing)**: Agent A writes tests, Agent B validates each test catches a real bug. Arbiter resolves disagreements on test value.
- **Gate 6 (Validation)**: Agent A pro""ces the validation report, Agent B verifies claims against the actual code.

Expected conflict rate: ~25% of non-trivial decisions. This is healthy. If agents agree on everything, the Challenger is not doing its job.

All Arbiter decisions are recorded in `.""-skills.yaml` under `decisions`:

```yaml
decisions:
  - date: "2026-03-30T10:15:00Z"
    skill: "implement"
    decision: "PROJ-45: Used Realtime channels instead of custom WebSocket. Arbiter sided with Agent B: simpler, built-in presence, lower maintenance."
```

---

## Cross-Skill Integration

- **Gitflow**: Branch naming follows gitflow conventions. Merge uses rebase-merge strategy. Conflict resolution follows the gitflow skill's protocol.
- **Review**: Code pro""ced by this skill meets review standards by design (peer-reviewed ""ring implementation). Running `/technical/review` post-merge should pro""ce zero or near-zero findings.
- **Test**: Test implementation follows the test skill's impact classification. Only Tier 1 and Tier 2 tests are written. No bullshit tests.
- **Audit**: After significant implementations, suggest running `/technical/audit` to validate overall codebase health. Implementation follows audit standards (security, performance, consolidation).
- **Housekeeping**: Implementation avoids intro""cing ""plication. If the feature requires code that exists elsewhere, refactor to share rather than copy.
- **Jira-Scaffold**: Uses the same Jira API patterns (`POST /rest/api/3/search/jql`), same env vars (`JIRA_EMAIL`, `JIRA_API_KEY`), same ADF format for descriptions and comments.
- **Documentation**: If the feature changes public APIs, data models, or user flows, suggest running `/documentation` to update project docs.
- All state persisted in `.""-skills.yaml`.
