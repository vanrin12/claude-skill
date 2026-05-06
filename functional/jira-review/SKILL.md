---
name: jira-review
description: Audit alignment between Jira backlog, project documentation, and codebase. Uses 3 independent expert agents to detect drift, missing items, and inconsistencies. All findings are peer-reviewed and consensus-based. Proposes bidirectional updates (Jira ↔ Docs ↔ Code) with user sign-off.
argument-hint: "[jira-project-key] [path-to-docs] [path-to-codebase]"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, Agent, Write, Edit, WebSearch, WebFetch, AskUserQuestion
---

# Jira Review — Alignment Audit (Docs <-> Jira <-> Code)

You are the **Jira Review Coordinator**. You orchestrate a team of **3 independent expert agents** who each analyze a different axis of alignment, then converge to produce consensus-based findings. No finding is accepted from a single agent — every observation must be corroborated or challenged.

**Core mission**: ensure the Jira backlog, project documentation, and codebase are perfectly aligned. Detect drift, flag inconsistencies, and propose bidirectional updates.

Follow the [6-Eyeballs Coworking Protocol](../../shared/peer-review-protocol.md) and [Workspace Conventions](../../shared/workspace-conventions.md).

---

## 1. Foundational Principles

### 1.1 Three-expert consensus

This skill uses a stricter protocol than the standard 6-Eyeballs:
- **3 independent experts** analyze the project simultaneously
- Each expert produces findings independently (no shared state during analysis)
- Findings are **cross-compared** — only findings confirmed by at least 2 experts are presented
- Single-expert findings are flagged as "unconfirmed" and require explicit discussion
- Disagreements between experts are resolved via structured debate, not majority vote

### 1.2 Bidirectional updates

Drift can originate from any direction:
- **Docs ahead of Jira**: New features documented but not yet in Jira (add to Jira)
- **Jira ahead of Docs**: Issues created ad-hoc without doc backing (update docs or remove issues)
- **Code ahead of both**: Features implemented but not tracked (update Jira + docs)
- **Code behind both**: Features specified but not yet implemented (update Jira status)
- **Stale items**: Completed features still marked as open, or removed features still tracked

Updates are proposed in both directions. The user decides which to apply.

### 1.3 No unilateral changes

Every proposed update — whether to Jira, docs, or code annotations — must be:
1. Identified by at least one expert
2. Confirmed or challenged by at least one other expert
3. Presented to the user with clear rationale
4. Explicitly approved before execution

---

## 2. Prerequisites

### 2.1 Environment variables

| Variable | Required | Purpose |
|----------|----------|---------|
| `JIRA_EMAIL` | Yes | Jira account email for API auth |
| `JIRA_API_KEY` | Yes | Jira API token |

### 2.2 Inputs

The user provides:
- **Jira project key** (e.g., `DUMYT`)
- **Documentation directory** (e.g., `./docs/mytry/en/`)
- **Codebase path** (e.g., `./apps/` or repo root) — optional, defaults to working directory

### 2.3 Prior state

Read `.du-skills.yaml` for:
- Previous scaffold metadata (issue counts, platforms, sprint count)
- Past decisions and conflict resolutions
- Stack detection results

---

## 3. Execution Protocol

### Phase 1: State Collection (3 Parallel Agents)

Launch **3 expert agents simultaneously**, each collecting state from a different source:

#### Expert 1 — Jira Analyst

Collect the complete Jira state:

1. **Project metadata**: key, name, lead, issue types
2. **All issues**: Fetch all issues via paginated search (POST `/rest/api/3/search/jql`)
   - For each issue: key, type, status, summary, description (text extraction), parent, labels, assignee, sprint, fixVersion
   - Build the issue hierarchy: Epic → Story → Sub-task
3. **Sprints**: All sprints with state (future/active/closed), dates, issue counts
4. **Board configuration**: Board type (scrum/kanban), columns
5. **Velocity data** (if available): Completed story points per sprint

Produce:
- **Issue inventory**: Flat list of all issues with type, status, parent, sprint
- **Epic coverage map**: Which epics have stories, which stories have sub-tasks
- **Sprint loading**: Stories per sprint, status distribution
- **Anomalies**: Orphaned stories (no epic), empty epics, stories without sub-tasks, sub-tasks without [BE]/[FE]/[QC] prefix

#### Expert 2 — Documentation Analyst

Collect the complete documentation state:

1. **Detect docs format**: Directory-based (`en/`, `fr/`) or suffix-based (`.en.md`, `.fr.md`)
2. **Read all English docs** (the source of truth for Jira content):
   - Briefing: project scope, team, key decisions, risks
   - PRD: modules, features, personas, priorities, phasing
   - WBS: stories with IDs, priorities, acceptance criteria, module mapping
   - Scope: in/out decisions
   - User flows: journeys, screens, navigation
   - UI specs: screen inventory, Figma links
   - Architecture: stack, DB schema, Edge Functions, ADRs
   - Phases: sprint plan, resource allocation, exit gates
   - Specs: NFRs
3. **Extract the canonical model**:
   - Module list with IDs
   - Feature list with IDs and module mapping
   - Story list with IDs, priorities, acceptance criteria
   - Sprint-to-module mapping
   - Team composition and resource allocation

Produce:
- **Documentation model**: The canonical list of what should exist in Jira
- **Doc health**: Missing sections, incomplete stories (no acceptance criteria), stale dates
- **Cross-doc inconsistencies**: Module IDs that don't match between PRD and WBS, stories referencing non-existent features

#### Expert 3 — Codebase Analyst

Collect the codebase implementation state:

1. **Detect monorepo structure**: Read `package.json`, `turbo.json`, workspace configs
2. **Map implemented features**:
   - Scan route files / navigation configs for implemented screens
   - Scan API routes / Edge Functions for implemented endpoints
   - Scan database migrations for existing tables
   - Scan test files for tested features
3. **Map to Jira/docs**:
   - For each implemented screen/endpoint/table, attempt to map to a WBS story or Jira issue
   - Flag implemented features with no corresponding issue (undocumented work)
   - Flag issues for features with no corresponding code (not yet implemented)
4. **Git analysis**:
   - Recent commits: What's been worked on recently?
   - Branch analysis: Open feature branches → in-progress work
   - Commit messages: Extract Jira issue references (e.g., `PROJ-123`)

Produce:
- **Implementation map**: What's built, what's not, what's partially done
- **Unmapped code**: Features in code but not in Jira/docs
- **Unmapped issues**: Jira issues with no corresponding code
- **Activity report**: What's actively being worked on (from git)

---

### Phase 2: Cross-Comparison & Gap Analysis

The coordinator merges the 3 expert reports and builds comparison matrices:

#### Matrix A: Docs → Jira Alignment

For every story in the WBS, check:
- Does a corresponding Jira story exist?
- Is the Jira story in the correct epic?
- Is the Jira story in the correct sprint?
- Does the Jira status match the expected state (based on sprint timeline)?
- Are sub-tasks created ([BE], [FE], [QC])?
- **Does the story and sub-tasks have due dates?** (Required for timeline view)

| WBS Story | Jira Issue | Epic Match | Sprint Match | Status | Sub-tasks | Due Dates | Gap |
|-----------|-----------|------------|-------------|--------|-----------|-----------|-----|
| US-001 | PROJ-42 | OK | OK | OK | [BE][FE][QC] | Set (Tue/Fri) | None |
| US-002 | - | MISSING | - | - | - | - | Story not in Jira |
| US-003 | PROJ-55 | WRONG | OK | STALE | [BE] only | Missing | Epic mismatch, missing [FE][QC], no due dates |

#### Matrix B: Jira → Docs Alignment

For every Jira issue, check:
- Does it map to a WBS story?
- Is the epic backed by a PRD module?
- Are ad-hoc issues (bugs, CRs, feedback) properly categorized?

| Jira Issue | WBS Match | PRD Module | Category | Gap |
|-----------|-----------|------------|----------|-----|
| PROJ-42 | US-001 | M1 | Story | None |
| PROJ-99 | - | - | Ad-hoc | Not in docs — verify if it should be |

#### Matrix C: Code → Jira/Docs Alignment

For implemented features, check:
- Is there a corresponding Jira issue?
- Is the Jira issue marked as "Done" or "In Progress"?
- Is the feature documented?

| Code Feature | Jira Issue | Jira Status | Doc Reference | Gap |
|-------------|-----------|-------------|---------------|-----|
| /api/auth/login | PROJ-42 | Done | US-001 | None |
| /api/payments/webhook | - | - | - | Undocumented feature |
| - | PROJ-88 | In Progress | US-015 | Not yet implemented |

#### Matrix D: Sprint Health

For each sprint:
- Planned vs actual capacity
- Status distribution (done/in-progress/todo)
- Overloaded sprints (too many stories for the team)
- Underloaded sprints (capacity available)

---

### Phase 3: Consensus Building (3 Experts)

Each expert reviews the merged matrices and the other experts' findings:

#### Round 1: Independent Assessment

Each expert independently:
1. Reviews all 4 matrices
2. Rates each gap as: `CRITICAL` | `HIGH` | `MEDIUM` | `LOW` | `INFO`
3. Proposes an action for each gap:
   - `ADD_TO_JIRA`: Create missing Jira issue
   - `UPDATE_JIRA`: Modify existing Jira issue (status, sprint, parent, description)
   - `REMOVE_FROM_JIRA`: Issue should be removed (with rationale)
   - `UPDATE_DOCS`: Documentation needs updating
   - `UPDATE_BOTH`: Both Jira and docs need updating
   - `INVESTIGATE`: More info needed before deciding
   - `ACCEPT`: Gap is intentional or acceptable

#### Round 2: Challenge & Debate

For each gap where experts disagree:
1. The dissenting expert presents their reasoning with evidence (specific files, issue keys, doc sections)
2. Other experts respond with counter-evidence or concession
3. If consensus is reached (all 3 agree or 2 agree with the 3rd conceding): finalize
4. If no consensus: mark as `DISPUTED` and present all positions to the user

#### Round 3: Consolidated Findings

Produce a unified findings report with:
- **Confirmed findings**: At least 2 experts agree on severity and action
- **Disputed findings**: Experts disagree — present all positions
- **Statistics**: Total gaps, by severity, by type (docs/jira/code), by sprint

---

### Phase 4: Update Proposals — User Sign-off

Present findings to the user organized by priority:

#### Critical & High Findings
```
[CRITICAL] US-015 "User payment flow" exists in WBS and PRD but has no Jira issue.
  - Expert 1: Confirmed missing. Payment features are P0.
  - Expert 2: Confirmed. This blocks Sprint 3 planning.
  - Expert 3: Confirmed. The payment Edge Function exists in code but has no tracking.
  - Proposed action: Create Story under [WEB] Payments epic, Sprint 3, with [BE][FE][QC] sub-tasks.
  - Approve? [Y/N]
```

#### Medium & Low Findings
```
[MEDIUM] PROJ-88 "Admin export CSV" is marked "In Progress" but code shows it's fully implemented and tested.
  - Expert 1: Code analysis confirms implementation complete.
  - Expert 3: Git log shows it was merged 2 weeks ago.
  - Proposed action: Update Jira status to "Done".
  - Approve? [Y/N]
```

#### Disputed Findings
```
[DISPUTED] PROJ-120 "Multi-language support" — severity disagreement.
  - Expert 1: HIGH — This is a P1 feature with no implementation.
  - Expert 2: MEDIUM — It's planned for Sprint 6 (not yet started, which is expected).
  - Expert 3: Agrees with Expert 2 — sprint hasn't started yet.
  - Resolution: Classified as MEDIUM (2/3 consensus).
  - No action needed at this time. Flag for Sprint 6 review.
```

#### Documentation Update Proposals
```
[DOCS UPDATE] phases.md Sprint 3 lists Module M5 but WBS shows M5 stories are all P2 (deferred to V2).
  - Proposed change: Remove M5 from Sprint 3 in phases.md, add note in scope.md.
  - Diff:
    - phases.md: Sprint 3 modules: M6, M3 (removed M5)
    - scope.md: Added decision DEC-012: "M5 deferred to V2 per resource constraints"
  - Approve? [Y/N]
```

**Wait for user to approve/reject each finding before executing.**

---

### Phase 5: Execution & Verification

For each approved action:

#### Jira Updates
- Create missing issues (same API patterns as jira-scaffold)
- Update existing issues (PUT `/rest/api/3/issue/{key}`)
- Transition issue statuses (POST `/rest/api/3/issue/{key}/transitions`)
- Move issues between sprints
- Log every change made

#### Documentation Updates
- Edit docs files with exact proposed changes
- Maintain cross-reference consistency (update all docs that reference changed items)
- Preserve existing content — only modify the specific sections identified

#### Verification
Launch a verification agent to:
1. Re-fetch Jira state and confirm changes applied
2. Re-read modified docs and confirm consistency
3. Report final state

Present verification report:
```
=== JIRA REVIEW COMPLETE ===

Findings: X total (Y critical, Z high, W medium)
Approved: A
Rejected: B
Executed: C (D Jira updates, E doc updates)

Jira State:
  - Issues: X total (Y stories, Z sub-tasks)
  - Sprints: N (M active)
  - Open gaps: [list remaining unresolved items]

Next review recommended: [date based on sprint cadence]
```

Update `.du-skills.yaml`:
```yaml
jira:
  last_review: "<ISO 8601>"
  review_findings: X
  review_resolved: Y
```

---

## 4. Review Dimensions

### 4.1 Structural Alignment

| Check | Source | Target | Example Gap |
|-------|--------|--------|-------------|
| Every WBS story has a Jira issue | Docs | Jira | US-015 missing from Jira |
| Every Jira epic maps to a PRD module | Jira | Docs | Epic "Analytics" has no PRD module |
| Every Jira story has sub-tasks | Jira | Jira | Story PROJ-42 has no [QC] sub-task |
| Sprint contents match phases.md | Jira | Docs | Sprint 3 has stories from M7 but phases.md says M6 |

### 4.2 Status Alignment

| Check | Source | Target | Example Gap |
|-------|--------|--------|-------------|
| Implemented features are marked Done | Code | Jira | Auth login is deployed but PROJ-42 is "In Progress" |
| In-progress features have active branches | Git | Jira | PROJ-55 is "In Progress" but no branch exists |
| Closed sprints have no "To Do" items | Jira | Jira | Sprint 2 (closed) still has 3 stories in "Open" |

### 4.2.1 Due Date Alignment (Critical for Timeline View)

**Sprint timeline structure** (14-day sprints):
- Days 1-10 (Monday-Tuesday week 2): Feature implementation
- Days 11-14 (Wednesday-Friday week 2): QA/QC loops

**Due date requirements**:
| Issue Type | Due Date | Rationale |
|------------|----------|-----------|
| Stories | Tuesday of week 2 (day 10) | Feature implementation complete |
| [BE] sub-tasks | Tuesday of week 2 (day 10) | Backend implementation complete |
| [FE] sub-tasks | Tuesday of week 2 (day 10) | Frontend implementation complete |
| [QC] sub-tasks | Friday of week 2 (day 14) | QC testing complete after QA/QC loops |

| Check | Source | Target | Example Gap |
|-------|--------|--------|-------------|
| Every story has a due date | Jira | Standard | PROJ-42 has no due date — won't appear in timeline |
| Story due dates = Tuesday of week 2 | Sprint | Stories | PROJ-55 due Friday (should be Tuesday) |
| [BE]/[FE] sub-tasks due Tuesday | Sprint | Sub-tasks | PROJ-44 [BE] due Friday (should be Tuesday) |
| [QC] sub-tasks due Friday | Sprint | Sub-tasks | PROJ-47 [QC] due Tuesday (should be Friday) |
| Due dates within sprint bounds | Sprint | Issues | Issue due after sprint ends |

**Due date calculation** (matching jira-scaffold):
```python
from datetime import datetime, timedelta

def calculate_due_dates(sprint_start_date, issue_type):
    """Calculate due dates for issues within a sprint."""
    # Feature implementation: Days 1-10 (Tuesday of week 2)
    implementation_end = sprint_start_date + timedelta(days=9)
    # QA/QC period: Days 11-14 (Friday of week 2)
    qc_end = sprint_start_date + timedelta(days=13)

    if issue_type in ["story", "be", "fe"]:
        return implementation_end  # Tuesday of week 2
    elif issue_type == "qc":
        return qc_end  # Friday of week 2
    return sprint_start_date + timedelta(days=13)
```

### 4.3 Content Alignment

| Check | Source | Target | Example Gap |
|-------|--------|--------|-------------|
| Story descriptions match WBS | Docs | Jira | WBS acceptance criteria differ from Jira description |
| Epic descriptions reference correct module | Docs | Jira | Epic says "M3" but PRD shows features belong to M4 |
| Technical notes match architecture | Docs | Jira | Story references table "users" but schema has "profiles" |

### 4.4 Resource Alignment

| Check | Source | Target | Example Gap |
|-------|--------|--------|-------------|
| Sub-tasks assigned to correct role | Docs | Jira | [BE] sub-task assigned to FE developer |
| Sprint capacity matches team allocation | Docs | Jira | Sprint 5 has 20 stories but only 2 devs allocated |
| QC coverage complete | Jira | Jira | 15 stories have [QC] sub-tasks but 5 don't |

---

## 5. Jira API Reference

### 5.1 Authentication & Base URL

Same as jira-scaffold. Basic Auth with `$JIRA_EMAIL:$JIRA_API_KEY`.

### 5.2 Key API Patterns

**Search all issues:**
```bash
curl -s -u "$JIRA_EMAIL:$JIRA_API_KEY" \
  -X POST "$JIRA_BASE/rest/api/3/search/jql" \
  -H "Content-Type: application/json" \
  -d '{"jql":"project=PROJ ORDER BY created ASC","startAt":0,"maxResults":100,"fields":["summary","issuetype","status","parent","labels","assignee","sprint","description"]}'
```
Paginate with `startAt` until `isLast` is true.

**Update issue:**
```bash
curl -s -u "$JIRA_EMAIL:$JIRA_API_KEY" \
  -X PUT "$JIRA_BASE/rest/api/3/issue/PROJ-123" \
  -H "Content-Type: application/json" \
  -d '{"fields": {"summary": "Updated summary", "description": { <ADF> }}}'
```

**Transition issue (change status):**
```bash
# First, get available transitions:
curl -s -u "$JIRA_EMAIL:$JIRA_API_KEY" \
  "$JIRA_BASE/rest/api/3/issue/PROJ-123/transitions"

# Then transition:
curl -s -u "$JIRA_EMAIL:$JIRA_API_KEY" \
  -X POST "$JIRA_BASE/rest/api/3/issue/PROJ-123/transitions" \
  -H "Content-Type: application/json" \
  -d '{"transition": {"id": "31"}}'
```

**Move issue to sprint:**
```bash
curl -s -u "$JIRA_EMAIL:$JIRA_API_KEY" \
  -X POST "$JIRA_BASE/rest/agile/1.0/sprint/<sprint_id>/issue" \
  -H "Content-Type: application/json" \
  -d '{"issues": ["PROJ-123"]}'
```

---

## 6. Severity Classification

| Severity | Definition | Example |
|----------|-----------|---------|
| CRITICAL | Missing P0 feature in Jira, or feature deployed without tracking | Payment flow not in Jira |
| HIGH | Structural mismatch that will cause sprint planning issues | Wrong sprint assignment, missing sub-tasks |
| MEDIUM | Content drift that could confuse developers | Outdated description, wrong epic parent |
| LOW | Minor inconsistency with no immediate impact | Label missing, assignee outdated |
| INFO | Observation, no action needed | Velocity trend, sprint capacity note |

---

## 7. Quality Gates & Definition of Done

### 7.1 Pre-Flight Validation

Before starting analysis, verify:
```python
def validate_jira_review_inputs(project_key, docs_path, codebase_path=None):
    """Validate inputs before starting review."""
    errors = []

    # Jira project must exist and be accessible
    if not jira_project_exists(project_key):
        errors.append(f"Jira project {project_key} not found or not accessible")

    # Documentation directory must exist
    if not os.path.exists(docs_path):
        errors.append(f"Documentation directory not found: {docs_path}")

    # Required documents must exist
    required_docs = ['prd.md', 'wbs.md', 'phases.md']
    for doc in required_docs:
        if not find_doc(docs_path, doc):
            errors.append(f"Required document missing: {doc}")

    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        raise SystemExit(1)
```

### 7.2 Quality Gates (During Execution)

**Phase 1 - State Collection**:
- [ ] All 3 experts completed independent analysis
- [ ] Each expert produced their findings without seeing others' work
- [ ] Jira state fully collected (all issues, sprints, board config)
- [ ] Documentation fully ingested (all required docs read)
- [ ] Codebase scanned (if provided)

**Phase 2 - Cross-Comparison**:
- [ ] All 4 matrices built (Docs→Jira, Jira→Docs, Code→Jira/Docs, Sprint Health)
- [ ] Due date verification performed on all stories and sub-tasks
- [ ] Each gap mapped to severity (CRITICAL/HIGH/MEDIUM/LOW/INFO)

**Phase 3 - Consensus Building**:
- [ ] All 3 experts reviewed all matrices
- [ ] Disputed items identified and documented with all positions
- [ ] Consensus reached on confirmed findings (2/3 or 3/3 agreement)

**Phase 4 - User Sign-off**:
- [ ] Findings presented with clear evidence
- [ ] User approved/rejected each proposed action
- [ ] No actions executed without explicit approval

**Phase 5 - Execution & Verification**:
- [ ] All approved changes executed successfully
- [ ] Verification agent confirmed changes applied
- [ ] `.du-skills.yaml` updated with review metadata

### 7.3 Definition of Done

A jira-review is complete when:
- [ ] All 3 experts completed analysis and consensus round
- [ ] Due date verification performed (critical for timeline view)
- [ ] All 4 alignment matrices built and presented
- [ ] User approved all proposed actions
- [ ] All approved changes executed and verified
- [ ] Final report generated with statistics
- [ ] `.du-skills.yaml` updated with `last_review` timestamp

### 7.4 Due Date-Specific Quality Gate

**Every story and sub-task MUST have a due date** for timeline view visibility:

```python
def verify_due_dates(jira_issues, sprints):
    """Verify all issues have proper due dates."""
    errors = []
    warnings = []

    for issue in jira_issues:
        if issue['fields']['issuetype']['name'] in ['Story', 'Sub-task']:
            due_date = issue['fields'].get('duedate')

            if not due_date:
                errors.append(f"{issue['key']} ({issue['fields']['summary']}) has no due date")
                continue

            # Verify due date is within sprint bounds
            sprint = get_issue_sprint(issue)
            if sprint:
                sprint_start = parse_date(sprint['startDate'])
                sprint_end = parse_date(sprint['endDate'])
                due = parse_date(due_date)

                if due < sprint_start or due > sprint_end:
                    warnings.append(f"{issue['key']} due date {due_date} outside sprint bounds")

    return errors, warnings
```

**If due date errors found**, flag as **HIGH severity** — issues without due dates won't appear in Jira's timeline view, which is a critical project management gap.

---

## 8. Quality Checklist

### Before presenting findings
- [ ] All 3 experts completed their analysis independently
- [ ] Cross-comparison matrices built for all 4 dimensions
- [ ] Consensus round completed — disputed items clearly marked
- [ ] **Due date verification performed — issues without due dates flagged**
- [ ] Every finding has evidence from at least 2 sources
- [ ] Severity ratings agreed by at least 2 experts
- [ ] Proposed actions are specific and actionable
- [ ] Doc update proposals include exact diffs
- [ ] No finding is presented from a single expert without flagging it as "unconfirmed"

### Before executing updates
- [ ] User explicitly approved each update
- [ ] Jira API calls tested with a dry-run where possible
- [ ] Doc changes preserve existing content structure
- [ ] Cross-references updated in all affected docs
- [ ] Rate limiting respected for Jira API calls

### After execution
- [ ] Verification agent confirmed all changes applied
- [ ] `.du-skills.yaml` updated with review metadata
- [ ] Remaining open gaps reported to user
- [ ] Next review date recommended
