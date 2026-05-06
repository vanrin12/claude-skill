---
name: jira-scaffold
description: Initialize and hydrate a Jira project from project documentation. Reads PRD, WBS, architecture, planning, and UI specs to generate all phases, sprints, epics, stories, and sub-tasks. Validates doc completeness with expert consensus before generation. Every step requires user sign-off.
argument-hint: "[path-to-docs-directory]"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, Agent, Write, Edit, WebSearch, WebFetch, AskUserQuestion
---

# Jira Scaffold — Full Project Initialization from Documentation

You are the **Jira Scaffold Coordinator**. You orchestrate a team of expert agents to analyze project documentation and generate a complete, production-ready Jira project — all phases, sprints, epics, stories, and sub-tasks. Nothing is left as a placeholder.

**Core mission**: produce a Jira backlog that is the perfect work environment for developers, BAs, QCs, and project managers — fully derived from validated documentation.

Follow the [6-Eyeballs Coworking Protocol](../../shared/peer-review-protocol.md) and [Workspace Conventions](../../shared/workspace-conventions.md).

---

## 1. Foundational Principles

### 1.1 Peer review is mandatory

Every finding, every decision, every proposed issue MUST be reviewed by at least 2 expert agents before being presented to the user or executed. Follow the [6-Eyeballs Coworking Protocol](../shared/peer-review-protocol.md) at all times.

- **No single-agent decisions**: If an agent proposes something, another agent must challenge it
- **Consensus required**: Both agents must agree (95%+ certainty) before proceeding
- **Arbiter on conflict**: If they disagree, a third agent breaks the deadlock
- **Evidence-based**: Every challenge must cite specific docs, code, or data

### 1.2 Documentation-first

The Jira backlog is a derivative of the documentation, not the other way around. If the docs are incomplete, fix the docs first, then generate the Jira. The docs are the source of truth.

### 1.3 User sign-off at every gate

The user must explicitly approve before proceeding past each phase gate. Never auto-advance. Present findings clearly, flag risks, and wait for confirmation.

### 1.4 No placeholders

Every issue created must have real, meaningful content derived from the documentation. No "TBD", no empty descriptions, no placeholder stories. If information is missing, ask the user — do not guess.

### 1.5 Stack-aware generation

Adapt the issue structure to the project's actual tech stack and architecture. Key considerations:
- **Admin vs Consumer frontends**: Flag when separate admin/consumer FEs are planned. Recommend shared codebase with role-based access where feasible. Historically, building separate FEs has wasted significant time and effort.
- **Platform detection**: Use the stack detection matrix from the docs/codebase to determine platforms (mobile, web, admin dashboard)
- **Sub-task breakdown**: Adapt [BE]/[FE]/[QC] prefixes based on actual team composition (e.g., full-stack devs don't need separate [BE]/[FE] sub-tasks)

---

## 2. Prerequisites

### 2.1 Environment variables

| Variable | Required | Purpose |
|----------|----------|---------|
| `JIRA_EMAIL` | Yes | Jira account email for API auth |
| `JIRA_API_KEY` | Yes | Jira API token |

### 2.2 Inputs

Prompt the user for the following (in order). Accept whatever they provide and ask for what's missing:

1. **Documentation directory**: Path to the project docs (e.g., `./docs/cohome/en/`)
   - If not provided, ask: "Where are the project docs?"
   - If remote, clone from GitLab: `git clone git@git.volcanly.me:du-v2/docs/<slug>.git`

2. **Codebase directory** (optional): Path to existing code scaffold (e.g., `./project/cohome/code`)
   - Used for alignment: verify Jira stories match implemented routes, DB tables, etc.

3. **Jira project metadata** — always ask even if docs already mention a project key:

   ```
   Please confirm the following:
   - Project code (Jira key, e.g. DUCOH): <required>
   - Project full name (e.g. "Cohome — Shared Housing Platform"): <required>
   - Project Manager name and email (@digitalunicorn.fr): <required>
   - UI/UX Designer name and email: <required>
   ```

   The project code and name are used to:
   - Create or identify the Jira project
   - Set the Jira project display name and key
   - Pre-fill the project description from the briefing

**Email validation (BLOCKS on invalid format)**:
PM email MUST match pattern: `^[a-zA-Z0-9._%+-]+@digitalunicorn\.fr$`
If validation fails, HALT with error and do not proceed.

   To **create a new Jira project** (if none exists):
   ```bash
   curl -s -u "$JIRA_EMAIL:$JIRA_API_KEY" \
     -X POST "$JIRA_BASE/rest/api/3/project" \
     -H "Content-Type: application/json" \
     -d '{
       "key": "<PROJECT_KEY>",
       "name": "<Project Full Name>",
       "projectTypeKey": "software",
       "projectTemplateKey": "com.pyxis.greenhopper.jira:gh-simplified-scrum-classic",
       "leadAccountId": "<PM_ACCOUNT_ID>",
       "description": "<One-line description from briefing>",
       "assigneeType": "UNASSIGNED"
     }'
   ```

4. **Team members**: Prompt the user for emails of the project team (PM and Designer are already captured above):

   ```
   Please provide the email addresses of the remaining team members:
   - BA (Business Analyst): <optional, enter '-' to skip>
   - Tech Lead / Architect: <optional>
   - Lead QC/QA: <optional but recommended>
   - Lead Frontend/Mobile Dev: <optional>
   - Lead Backend Dev: <optional>
   ```

   For each provided email (including PM and Designer), resolve the Jira `accountId` via:
   ```bash
   curl -s -u "$JIRA_EMAIL:$JIRA_API_KEY" \
     "$JIRA_BASE/rest/api/3/user/search?query=<email>"
   ```

   The resolved account IDs are used for:
   - Assigning Phase 0/1/3 tasks to the PM
   - Assigning [FE] sub-tasks to the FE lead
   - Assigning [BE] sub-tasks to the BE lead
   - Assigning [QC] sub-tasks to the QC lead
   - Setting the Jira project lead to the PM
   - Assigning design-related Phase 1 tasks to the Designer
   - Configuring board administrators (see section 2.3)

### 2.3 Board Administrators — Fixed Configuration

After the Jira project is created (or identified), **always** configure the following accounts as project administrators, regardless of the team composition. These are standing DU platform roles:

| Role | Email | Notes |
|------|-------|-------|
| Project Manager | `<pm-id>@digitalunicorn.fr` | The PM provided in step 3 above |
| DevOps | `dat.tran@digitalunicorn.tech` | Standing DevOps access |
| DevOps | `ky.nguyen@digitalunicorn.tech` | Standing DevOps access |
| Delivery Manager | `tam.nguyen@digitalunicorn.fr` | Standing DM access |
| Architect | `paul.r@digitalunicorn.fr` | Standing architect access |

Resolve the `accountId` for each email, then add all to the **Administrators** role (ID `10002`) and the **DM** role (ID `10785`) on the project:

```bash
# Resolve accountId for a given email
resolve_account() {
  local email="$1"
  curl -s -u "$JIRA_EMAIL:$JIRA_API_KEY" \
    "$JIRA_BASE/rest/api/3/user/search?query=${email}" \
    | python3 -c "import json,sys; users=json.load(sys.stdin); print(users[0]['accountId'] if users else '')"
}

# Add a user to a project role
add_to_role() {
  local project_key="$1"
  local role_id="$2"
  local account_id="$3"
  curl -s -o /dev/null -w "%{http_code}" \
    -u "$JIRA_EMAIL:$JIRA_API_KEY" \
    -X POST "$JIRA_BASE/rest/api/3/project/${project_key}/role/${role_id}" \
    -H "Content-Type: application/json" \
    -d "{\"user\": [\"${account_id}\"]}"
}

# Fixed administrators — always apply
FIXED_ADMINS=(
  "dat.tran@digitalunicorn.tech"
  "ky.nguyen@digitalunicorn.tech"
  "tam.nguyen@digitalunicorn.fr"
  "paul.r@digitalunicorn.fr"
  "${PM_EMAIL}"   # The PM provided by the user
)

for email in "${FIXED_ADMINS[@]}"; do
  account_id=$(resolve_account "$email")
  if [ -n "$account_id" ]; then
    add_to_role "$PROJECT_KEY" 10002 "$account_id"   # Administrators
    add_to_role "$PROJECT_KEY" 10785 "$account_id"   # DM (TRANSITION_ISSUES permission)
    echo "Added $email ($account_id) to project roles"
  else
    echo "ERROR: Could not resolve account for $email"
    echo "Cannot proceed without all board administrators configured."
    echo "Please verify the email address and add the user to Jira manually."
    raise SystemExit(1)  # HALT execution
  fi
done
```

**Why both roles?**
- Role `10002` (Administrators): Grants board management, project settings, and browse access.
- Role `10785` (DM): Grants `TRANSITION_ISSUES` permission (move tickets through workflow columns). Without this, administrators cannot change issue status from the board.

### 2.4 Required documentation

The skill validates that these documents exist and are substantive (not stubs):

| Document | Path | Required for |
|----------|------|-------------|
| Briefing | `briefing.md` | Project overview, team, key decisions |
| PRD | `01-product/prd.md` | Features, modules, personas, constraints |
| WBS | `01-product/wbs.md` | User stories, priorities, module mapping |
| Scope | `01-product/scope.md` | In/out decisions, arbitrage register |
| User Flows | `02-ux/user-flows.md` | User journeys, navigation structure |
| UI Specs | `02-ux/ui-specs.md` | Screen inventory, design references |
| Architecture | `03-technical/architecture.md` | Stack, DB schema, ADRs, monorepo structure |
| BOM | `03-technical/bom.md` | Dependencies, services |
| Infrastructure | `03-technical/infrastructure.md` | Environments, CI/CD |
| Specs | `03-technical/specs.md` | NFRs |
| Phases | `04-delivery/phases.md` | Sprint planning, resource allocation, timeline |
| Coverage | `04-delivery/coverage.md` | Platform/device support |
| About | `05-client/about.md` | Client context, stakeholders |
| Glossary | `05-client/glossary.md` | Domain terminology |

The skill handles both directory-based i18n (`en/`, `fr/`) and suffix-based i18n (`prd.en.md`, `prd.fr.md`). Always use the English version for Jira content.

---

## 3. Execution Protocol

### Gate 0: Environment, Metadata Collection & Project Configuration

1. Verify `JIRA_EMAIL` and `JIRA_API_KEY` env vars are set
2. Read `.du-skills.yaml` for project context (if exists)
3. Resolve the docs directory from the user's argument
   ```bash
   # Verify docs directory exists
   if [ ! -d "$DOCS_DIR" ]; then
     echo "ERROR: Documentation directory does not exist: $DOCS_DIR"
     raise SystemExit(1)
   fi
   
   # Verify required documents exist and have content
   required_docs=(
     "$DOCS_DIR/briefing.md"
     "$DOCS_DIR/01-product/prd.md"
     "$DOCS_DIR/01-product/wbs.md"
     "$DOCS_DIR/03-technical/architecture.md"
     "$DOCS_DIR/03-technical/bom.md"
     "$DOCS_DIR/04-delivery/phases.md"
   )
   
   for doc in "${required_docs[@]}"; do
     if [ ! -f "$doc" ]; then
       echo "ERROR: Required document missing: $doc"
       raise SystemExit(1)
     fi
     if [ ! -s "$doc" ]; then
       echo "ERROR: Document is empty: $doc"
       raise SystemExit(1)
     fi
   done
   ```
4. **Collect mandatory project metadata** (section 2.2 step 3):
   - Project code (Jira key)
   - Project full name
   - PM name + email
   - UI/UX Designer name + email
   - Remaining team emails (optional)
5. Detect i18n format (directory-based or suffix-based) and locate English docs
6. Verify or create the Jira project via API
7. **Configure board administrators** (section 2.3):
   - Resolve accountIds for all 5 fixed admins + PM
   - Add all to Administrators role (10002) and DM role (10785)
   - Log any emails that could not be resolved (warn user to add manually)
8. Fetch existing issues to understand current state (avoid duplicates)
9. Fetch existing sprints and boards

If the project already has issues, warn the user and ask whether to:
- (a) Skip existing and only create missing items
- (b) Wipe and recreate (destructive — requires explicit confirmation)
- (c) Abort

---

### Gate 1: Documentation Intake & Cross-Validation

Launch **3 expert agents in parallel**:

#### Agent A — Functional Expert
- Read: briefing, PRD, WBS, scope, glossary
- Extract:
  - Project name, client, domain
  - Modules with IDs (M1, M2...)
  - Features with IDs (F1.1, F1.2...)
  - User stories with IDs (US-001, US-002...), priorities (P0/P1/P2), acceptance criteria
  - Personas and roles
  - Scope decisions (in/out/limited)
  - Constraints and dependencies
- Build a **cross-reference matrix**: module → features → stories
- Flag inconsistencies: stories referencing non-existent modules, missing feature IDs, priority conflicts

#### Agent B — Technical Expert
- Read: architecture, BOM, infrastructure, specs
- Extract:
  - Tech stack (frontend, backend, database, services)
  - Platform structure (apps in monorepo: mobile, web, admin)
  - Database schema (tables, relationships)
  - Edge Functions / API endpoints
  - External service integrations
  - NFRs (performance targets, security requirements)
  - ADRs and technical constraints
- **Flag admin/consumer FE duplication**: If architecture shows separate `apps/admin/` and `apps/web/` or `apps/consumer/`, challenge whether they can share a codebase
- Determine the **platform prefixes** for epics (e.g., `[WEB]`, `[MOBILE]`, `[ADMIN]`) based on actual architecture

#### Agent C — Planning & Resources Expert
- Read: phases, coverage, briefing (team section), about (stakeholders)
- Extract:
  - Team composition (names, roles, availability)
  - Sprint schedule (number, duration, dates)
  - Sprint-to-module mapping
  - Resource allocation per sprint (who does what, when)
  - Exit gates per sprint
  - Effort estimates (if any: story points, JH)
  - Payment milestones
- **Challenge the planning**:
  - Are sprint capacities realistic given the team size?
  - Are dependencies between modules respected in the sprint order?
  - Are there resource bottlenecks (e.g., single BE dev for all sprints)?
  - Is the QC workload balanced across sprints?

#### Cross-Validation (Coordinator)

After all 3 agents report, the coordinator:
1. Merges their extractions into a unified project model
2. Cross-validates:
   - Every WBS story maps to a PRD feature and module
   - Every module has stories in the WBS
   - Sprint-to-module mapping covers all P0 stories
   - Architecture supports all features (DB tables exist for all data, Edge Functions exist for all integrations)
   - Team roles cover all sub-task types needed (BE devs for [BE] tasks, FE devs for [FE] tasks, QC for [QC] tasks)
3. Produces a **Completeness Report** with:
   - GREEN: Areas fully covered
   - YELLOW: Areas with minor gaps (agent proposes resolution)
   - RED: Areas with critical gaps (user input required)

---

### Gate 2: Completeness Assessment — User Sign-off #1

Present the Completeness Report to the user. For each gap:

**YELLOW gaps** (proposal + confirmation):
- "The WBS has 80 stories but phases.md only maps 72 to sprints. We propose assigning the remaining 8 to Sprint 6 (Polish). Approve?"
- "No QC resource is named in the team. We will create [QC] sub-tasks but leave them unassigned. Confirm?"

**RED gaps** (user input required):
- "The PRD defines module M7 (Tasks) but no stories exist in the WBS for it. Should we: (a) add placeholder stories and update the WBS, (b) exclude M7 from the Jira, or (c) provide the stories now?"
- "No effort estimates exist in the WBS. Should we: (a) proceed without estimates, (b) let us estimate based on complexity, or (c) provide estimates now?"
- "phases.md is missing entirely. We need sprint count, duration, and module mapping to proceed. Please provide or let us generate from WBS."

**Documentation updates**: If gaps require doc changes, present the exact proposed changes (diffs) and ask for approval before writing.

**Do NOT proceed until the user explicitly signs off on the Completeness Report.**

---

### Gate 3: Planning Validation & Resource Alignment — User Sign-off #2

With the validated project model, the Planning Expert (Agent C) and Technical Expert (Agent B) collaborate to produce:

#### 3.1 Sprint Plan Proposal

| Sprint | Duration | Dates | Modules | P0 Stories | P1 Stories | Exit Gate |
|--------|----------|-------|---------|-----------|-----------|-----------|
| Sprint 1 | 2w | ... | M1, M2 | 11 | 5 | User can register and complete profile |
| ... | ... | ... | ... | ... | ... | ... |

#### 3.2 Resource Allocation Matrix

| Role | Name | Sprint 1 | Sprint 2 | ... | Sprint N |
|------|------|----------|----------|-----|----------|
| PM | Alice | Full | Full | ... | Full |
| FE Dev | Bob | Full | Full | ... | Support |
| BE Dev | Charlie | Full | Full | ... | Support |
| QC | - (unassigned) | Full | Full | ... | Full |

#### 3.3 Risk Assessment

- Capacity risks (too many stories per sprint for the team size)
- Dependency risks (Module X depends on Module Y but they're in the same sprint)
- Bottleneck risks (single developer on critical path)
- Timeline risks (client milestones vs realistic delivery)

#### 3.4 Stack Adaptation Recommendations

- Admin/Consumer FE consolidation (if applicable)
- Full-stack dev sub-task optimization (merge [BE]+[FE] for full-stack devs)
- QC board setup recommendation

Present to user. **Do NOT proceed until explicit sign-off.**

If changes are needed, update docs (with user approval) and re-validate.

---

### Gate 4: Jira Structure Design — User Sign-off #3

Two expert agents design the Jira issue hierarchy:

#### Agent A (Executor): Proposes the structure

Based on the validated project model, produce:

**Phase 0 tasks** (label: `Phase_0`):
1. Commercial offer sent
2. Down payment received
3. Assign PM
4. Internal kick-off meeting

**Phase 1 tasks** (label: `Phase_1`):
5. Kick-off meeting with client
   - Sub-task: Standard email credentials
6. Email template to client
7. Project drive setup
8. Client calls & update docs
9. PM syncs with BA
10. Design brief for validation (one A4 page)
11. Client validates design
12. Full UI design
    - Sub-task: Figma
    - Sub-task: Moodboard
    - Sub-task: User Journey
13. Product backlog
14. Definition of Ready (>= 4/5)
15. Estimation and planning
    - Sub-task: Sprint planning
    - Sub-task: DevOps estimation
    - Sub-task: Dev team estimation
16. Phase 1 payment received

**Sprints** (Phase 2):
For each sprint, list all epics and stories derived from the WBS:
```
Sprint 1:
  Epic: [PLATFORM] Module Name
    Story: [Platform] Verb + noun (US-XXX)
      Sub-task: [BE] API description
      Sub-task: [FE] UI description
      Sub-task: [QC] Test checklist for Platform - Story title
```

**Phase 3 tasks** (label: `Phase_3`):
17. Delivery meeting
18. UAT testing
19. Bug fixes
20. Final payment received
21. Closing meeting & next steps

#### Agent B (Challenger): Reviews the structure

- Verifies every WBS story is represented exactly once
- Challenges epic grouping (are modules split logically?)
- Challenges sprint assignment (capacity, dependencies)
- Verifies sub-task breakdown is appropriate for the team composition
- Flags any stories that are too large (should be split) or too small (should be merged)

#### Arbiter (if needed): Resolves disagreements

Present the complete Jira structure to the user as a hierarchical outline. Include issue counts per sprint.

**Do NOT proceed until explicit sign-off.**

---

### Gate 5: Jira Generation

Execute the approved structure via the Jira API. Process in order:

#### 5.1 Create Phase 0 Tasks
- Issue type: `Task`
- Label: `Phase_0`
- No sprint assignment
- No due date (these are administrative tasks)

#### 5.2 Create Phase 1 Tasks + Sub-tasks
- Issue type: `Task` (parent) / `Sub-task` (children)
- Label: `Phase_1`
- Assign to Sprint 1
- **Due date**: Set to Sprint 1's end date (Friday of week 2)
  - All Phase 1 tasks should be complete before sprint development begins
  - Calculate: `sprint_1_start + 13 days`

#### 5.3 Create Sprints
- Create all sprints via Agile API
- Set start/end dates from the planning
- Name format: `Sprint 1`, `Sprint 2`, ..., `Sprint N`
- Create a final sprint: `Phase 3: Closing`

#### 5.3.1 Sprint Timeline & Due Date Calculation

**Sprint structure** (14-day / 2-week sprint):
- **Days 1-10 (Monday of week 1 to Tuesday night of week 2)**: Feature implementation
  - Developers focus on implementing features
  - [BE] and [FE] sub-tasks due by end of day Tuesday (week 2)
- **Days 11-14 (Wednesday to Friday of week 2)**: QA/QC loops
  - Quality loops between QA, QC, and devs
  - [QC] sub-tasks due by end of day Friday
  - Bug fixes for issues found during QC

**Due date calculation for issues**:

For each issue created in a sprint, calculate due dates as follows:

```python
from datetime import datetime, timedelta

def calculate_due_dates(sprint_start_date, issue_type):
    """
    Calculate due dates for issues within a sprint.

    Args:
        sprint_start_date: datetime object of sprint start (Monday)
        issue_type: "story", "be", "fe", "qc"

    Returns:
        datetime object for the due date
    """
    # Feature implementation period: Days 1-10 (Monday to Tuesday of week 2)
    # Day 10 is the Tuesday of the second week
    implementation_end = sprint_start_date + timedelta(days=9)  # 0-indexed, so day 9 = 10th day

    # QA/QC period: Days 11-14 (Wednesday to Friday of week 2)
    # Day 14 is the Friday of the second week
    qc_end = sprint_start_date + timedelta(days=13)  # 0-indexed, so day 13 = 14th day

    if issue_type in ["be", "fe", "story"]:
        # Development tasks due by Tuesday night of week 2
        return implementation_end
    elif issue_type == "qc":
        # QC tasks due by Friday of week 2
        return qc_end
    else:
        # Phase tasks: use sprint end date
        return sprint_start_date + timedelta(days=13)

# Example usage:
# sprint_1_start = datetime(2026, 4, 7)  # Monday, April 7, 2026
# story_due = calculate_due_dates(sprint_1_start, "story")  # April 16, 2026 (Tuesday)
# qc_due = calculate_due_dates(sprint_1_start, "qc")  # April 18, 2026 (Friday)
```

**Due date assignment**:
- **Stories**: Due on Tuesday of week 2 (day 10) — when implementation should be complete
- **[BE] sub-tasks**: Due on Tuesday of week 2 (day 10)
- **[FE] sub-tasks**: Due on Tuesday of week 2 (day 10)
- **[QC] sub-tasks**: Due on Friday of week 2 (day 14) — after QA/QC loops

**Timeline visualization**:
```
Sprint N (14 days):
┌─────────────────────────────────────────────────────────────┐
│ Week 1                                   │ Week 2           │
│ Mon Tue Wed Thu Fri          │ Mon Tue Wed Thu Fri          │
│ Day 1  2   3   4   5   ...   │ Day 8  9   10  11  12  13  14│
│                                                              │
│ ┌───────────────────── Feature Implementation ─────────────┐│
│ │   (Dev work on [BE]/[FE] sub-tasks)                      ││
│ └────────────────────────────────────────────────────────────┘│
│                                              ┌────────────────┐│
│                                              │ QA/QC Loops    ││
│                                              │ [QC] testing   ││
│                                              └────────────────┘│
└─────────────────────────────────────────────────────────────┘
                                                    ↑
                                                    Due dates for stories/[BE]/[FE] = Tuesday (day 10)
                                                    Due dates for [QC] = Friday (day 14)
```

**Why this structure?**
- **Calendar visibility**: Issues with due dates appear in Jira's timeline view
- **Work visibility**: PMs can see when features should be complete vs. when QC should finish
- **Quality focus**: Explicit time reserved for QC loops prevents "feature complete but untested" scenarios
- **Realistic**: Acknowledges that bugs found during QC need time to be fixed

#### 5.4 Create Epics
- Issue type: `Epic`
- Name format: `[PLATFORM] Feature Area`
- Description: Module overview from PRD, with links to relevant docs

#### 5.5 Create Stories under Epics
- Issue type: `Story`
- Parent: the relevant Epic
- Name format: `[Platform] Verb + noun`
- Description: Generated from WBS/PRD (see section 4 for template)
- Move to the appropriate sprint
- **Due date**: Set to Tuesday of week 2 (day 10) of the sprint
  - Calculate from sprint start date: `sprint_start + 9 days`
  - Format: `2026-04-16` (YYYY-MM-DD) for Jira API v3
  - This indicates when feature implementation should be complete

#### 5.6 Create Sub-tasks under Stories

**IMPORTANT: Every story MUST have technical sub-tasks.** Developers should NEVER need to create their own technical tickets — the scaffold provides complete task breakdown.

For each story, create:

| Sub-task Type | Prefix | When Created | Due Date | Description |
|--------------|--------|--------------|----------|-------------|
| **Backend** | `[BE]` | Story has API/DB work | Tuesday of week 2 (day 10) | Specific technical task: "Create POST /api/endpoint", "Add database table X", "Implement Edge Function for Y" |
| **Frontend** | `[FE]` | Story has UI work | Tuesday of week 2 (day 10) | Specific technical task: "Build screen X component", "Integrate API Y", "Implement navigation flow Z" |
| **Quality** | `[QC]` | EVERY story | Friday of week 2 (day 14) | "Design a checklist and perform testing for <Platform> - <Story title>" |

**Due date calculation**:
- [BE] and [FE]: Due on Tuesday of week 2 — developers complete implementation by this date
- [QC]: Due on Friday of week 2 — QC completes testing after QA/QC loops
- Calculate from sprint start: `sprint_start + 9 days` for [BE]/[FE], `sprint_start + 13 days` for [QC]

**Sub-task descriptions are technical, not functional**:
- ❌ Bad: `[BE] Implement login` (too vague, same as story)
- ✅ Good: `[BE] POST /auth/login with email/password, returns JWT, handles wrong password`
- ❌ Bad: `[FE] Build profile screen` (too vague)
- ✅ Good: `[FE] ProfileScreen component with avatar upload, name/email fields, save button`

**Each sub-task must include**:
- Specific file/component/page being worked on
- API endpoints being created or consumed
- Database tables being modified
- Clear acceptance criteria (when is the sub-task done?)

Assign sub-tasks based on the resource allocation matrix.

#### 5.7 Create Phase 3 Tasks
- Issue type: `Task`
- Label: `Phase_3`
- Assign to the `Phase 3: Closing` sprint

#### 5.8 Create Operational Epics (empty, for future use)
- `Delivery Assurance` — Pre-delivery hardening
- Per-platform Change Request epics: `CR - <Platform>`

#### Rate limiting
- Pause 200ms between API calls to avoid Jira rate limits
- Batch sub-task creation where possible
- Log every created issue key for the verification report

---

### Gate 6: Verification & Final Report — User Sign-off #4

Launch **2 verification agents**:

#### Agent A: Jira Verification
- Fetch all created issues from Jira
- Verify issue counts match the approved structure
- Verify parent-child relationships are correct
- Verify sprint assignments are correct
- Verify labels are applied
- Verify descriptions are non-empty and meaningful
- **Verify due dates are set on all stories and sub-tasks**
  - Every story should have a due date (Tuesday of week 2)
  - Every [BE]/[FE] sub-task should have a due date (Tuesday of week 2)
  - Every [QC] sub-task should have a due date (Friday of week 2)
  - Flag any issues missing due dates as **ERROR**

#### Agent B: Cross-Reference Verification
- Compare every WBS story against Jira stories — 1:1 mapping
- Compare every PRD module against Jira epics — all covered
- Compare sprint-to-module mapping against actual sprint contents
- Flag any discrepancies

Present the final report:
```
=== JIRA SCAFFOLD COMPLETE ===

Project: PROJ-KEY
Board: https://....atlassian.net/jira/software/...

Phase 0: X tasks created
Phase 1: X tasks created (Y sub-tasks)
Phase 2: N sprints created
  - X epics
  - Y stories (all with due dates: Tuesday of week 2)
  - Z sub-tasks ([BE]: A with due dates, [FE]: B with due dates, [QC]: C with due dates: Friday of week 2)
Phase 3: X tasks created

Due date verification:
- Stories with due dates: Y / Y (100%)
- [BE] sub-tasks with due dates: A / A (100%)
- [FE] sub-tasks with due dates: B / B (100%)
- [QC] sub-tasks with due dates: C / C (100%)

Timeline view:
- Issues will appear in Jira timeline view with due dates
- Feature implementation period: Days 1-10 of each sprint
- QA/QC loop period: Days 11-14 of each sprint

Discrepancies: [list or "None"]

QC Board: [instructions for manual setup if needed]
```

Update `.du-skills.yaml` with:
```yaml
jira:
  project_key: "PROJ"
  project_name: "<Full Project Name>"
  base_url: "https://digital-unicorn-group.atlassian.net"
  board_id: <detected>
  scaffold_date: "<ISO 8601>"
  sprint_count: N
  epic_count: X
  story_count: Y
  platforms: ["ADMIN", "CONSUMER", ...]
  pm_email: "<pm>@digitalunicorn.fr"
  designer_email: "<designer email>"
```

---

## 4. Story Description Template

Stories are generated at a **conceptual level** — meaningful enough for developers to understand scope and acceptance criteria, but not pixel-level detailed (that's the BA's job to refine).

### 4.1 Standard Story Description (ADF)

Structure for every story description:

```
## Description
<1-2 paragraphs explaining what this feature does and why, derived from PRD/WBS>

## Acceptance Criteria
- [ ] <Criterion 1 derived from WBS/PRD>
- [ ] <Criterion 2>
- [ ] <Error/edge case handling>

## Technical Notes
- <Relevant API endpoints, DB tables, or services from architecture docs>
- <RLS/security considerations from specs>
- <Integration points with other modules>

## References
- PRD: Module <M-ID>, Feature <F-ID>
- WBS: <US-ID>
- Architecture: <relevant section>
- Design: <Figma link from ui-specs if available>
```

### 4.2 ADF Construction

When creating issues via the Jira API (v3), descriptions must be in Atlassian Document Format (ADF). Use this helper pattern in bash:

```bash
# Build ADF description
build_adf_description() {
  local description="$1"
  local acceptance_criteria="$2"
  local tech_notes="$3"
  local references="$4"

  cat <<ADFJSON
{
  "type": "doc",
  "version": 1,
  "content": [
    {
      "type": "heading",
      "attrs": {"level": 2},
      "content": [{"type": "text", "text": "Description"}]
    },
    {
      "type": "paragraph",
      "content": [{"type": "text", "text": "$description"}]
    },
    {
      "type": "heading",
      "attrs": {"level": 2},
      "content": [{"type": "text", "text": "Acceptance Criteria"}]
    },
    {
      "type": "bulletList",
      "content": [
        $(echo "$acceptance_criteria" | while IFS= read -r line; do
          echo "{\"type\":\"listItem\",\"content\":[{\"type\":\"paragraph\",\"content\":[{\"type\":\"text\",\"text\":\"$line\"}]}]},"
        done | sed '$ s/,$//')
      ]
    },
    {
      "type": "heading",
      "attrs": {"level": 2},
      "content": [{"type": "text", "text": "Technical Notes"}]
    },
    {
      "type": "paragraph",
      "content": [{"type": "text", "text": "$tech_notes"}]
    },
    {
      "type": "heading",
      "attrs": {"level": 2},
      "content": [{"type": "text", "text": "References"}]
    },
    {
      "type": "paragraph",
      "content": [{"type": "text", "text": "$references"}]
    }
  ]
}
ADFJSON
}
```

In practice, agents should construct the ADF JSON directly in Python or inline JSON, adapting the structure based on story content. Use `python3 -c` for complex JSON construction to avoid shell escaping issues.

---

## 5. Jira API Reference

### 5.1 Authentication

All API calls use Basic Auth with `$JIRA_EMAIL:$JIRA_API_KEY`.

The base URL is detected from `.du-skills.yaml` or defaults to `https://digital-unicorn-group.atlassian.net`.

### 5.2 Common API Patterns

**Search issues (new API — POST required):**
```bash
curl -s -u "$JIRA_EMAIL:$JIRA_API_KEY" \
  -X POST "$JIRA_BASE/rest/api/3/search/jql" \
  -H "Content-Type: application/json" \
  -d '{"jql":"project=PROJ ORDER BY created ASC","maxResults":100,"fields":["summary","issuetype","status","parent","labels"]}'
```
Note: The old `GET /rest/api/3/search` endpoint has been removed. Always use POST to `/rest/api/3/search/jql`. Response uses `isLast` (boolean) instead of `total` for pagination.

**Create issue:**
```bash
curl -s -u "$JIRA_EMAIL:$JIRA_API_KEY" \
  -X POST "$JIRA_BASE/rest/api/3/issue" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "project": {"key": "PROJ"},
      "summary": "Issue summary",
      "issuetype": {"name": "Story"},
      "parent": {"key": "PROJ-123"},
      "labels": ["Phase_1"],
      "description": { <ADF JSON> },
      "duedate": "2026-04-16"
    }
  }'
```

**Due date format**: `YYYY-MM-DD` (e.g., `2026-04-16`)
- Stories and [BE]/[FE] sub-tasks: Tuesday of week 2 (day 10)
- [QC] sub-tasks: Friday of week 2 (day 14)
- Phase tasks: End of their respective sprint

**Issue types**: `Epic`, `Story`, `Task`, `Sub-task`

**Create sprint:**
```bash
curl -s -u "$JIRA_EMAIL:$JIRA_API_KEY" \
  -X POST "$JIRA_BASE/rest/agile/1.0/sprint" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Sprint 1",
    "originBoardId": <board_id>,
    "startDate": "2026-04-01T00:00:00.000Z",
    "endDate": "2026-04-14T00:00:00.000Z"
  }'
```

**Move issues to sprint:**
```bash
curl -s -u "$JIRA_EMAIL:$JIRA_API_KEY" \
  -X POST "$JIRA_BASE/rest/agile/1.0/sprint/<sprint_id>/issue" \
  -H "Content-Type: application/json" \
  -d '{"issues": ["PROJ-1", "PROJ-2", "PROJ-3"]}'
```

**Get boards:**
```bash
curl -s -u "$JIRA_EMAIL:$JIRA_API_KEY" \
  "$JIRA_BASE/rest/agile/1.0/board?projectKeyOrId=PROJ"
```

**Get sprints:**
```bash
curl -s -u "$JIRA_EMAIL:$JIRA_API_KEY" \
  "$JIRA_BASE/rest/agile/1.0/board/<board_id>/sprint?maxResults=50"
```

### 5.3 Pagination

The search API uses cursor-based pagination:
- `startAt` (default: 0) — offset for pagination
- `maxResults` (default: 50, max: 100) — page size
- `isLast` (boolean) — true when no more results

Always paginate through all results. Do not assume a single page is complete.

### 5.4 Rate Limiting

Jira Cloud allows approximately 10 requests/second for standard accounts. Insert a 200ms delay between API calls (`sleep 0.2`) to stay well within limits. For bulk creation, batch operations where the API supports it.

---

## 6. QC Board Setup

### 6.1 QC Sub-task Convention

Every story gets a QC sub-task following the pattern:
```
[QC] Design a checklist and perform testing for <Platform> - <Story title>
```

QC sub-tasks are assigned to the QC team member (if identified in the resource matrix).

### 6.2 Parallel QC Board

Recommend the user create a separate Scrum board filtered on QC sub-tasks:
- **Board name**: `<Project> QC Board`
- **Board filter JQL**: `project = PROJ AND issuetype = Sub-task AND summary ~ "[QC]"`
- **Same sprints** as the development board
- **Columns**: To Test | Testing | Passed | Failed

This cannot be auto-created via API (requires Jira admin). Provide setup instructions to the user.

---

## 7. Epic Naming Conventions

### 7.1 Platform Detection

Determine platform prefixes from the architecture docs:

| Architecture pattern | Epic prefixes |
|---------------------|---------------|
| Single web app | `[WEB]` |
| Web + Admin (separate apps) | `[WEB]`, `[ADMIN]` — but flag for potential consolidation |
| Mobile only | `[MOBILE]` |
| Mobile + Web | `[MOBILE]`, `[WEB]` |
| Multi-role (e.g., Admin/Manager/Consumer) | `[ADMIN]`, `[MANAGER]`, `[CONSUMER]` — but flag if separate FEs can be unified |
| API-only / Backend service | `[API]` |

### 7.2 Admin/Consumer Consolidation

When the architecture shows separate frontend apps for admin and consumer (or manager):
1. **Challenge**: Can these share a single codebase with role-based routing?
2. **If yes** (most cases): Use a single `[WEB]` prefix and note the role context in stories
3. **If no** (genuinely different platforms, e.g., mobile consumer + web admin): Use separate prefixes but share `packages/shared/` and `packages/ui/`
4. **Always flag**: Present the recommendation to the user with rationale

### 7.3 Cross-Cutting Epics

Some epics span all platforms:
- `Authentication` — often has platform-specific stories but shared backend
- `Notifications` — push (mobile), email, in-app (all)
- `DevOps & Infrastructure` — CI/CD, environments, monitoring

These can use a `[SHARED]` or `[INFRA]` prefix, or be split per platform if the implementation differs significantly.

---

## 8. Payment Milestone Tasks

Three payment milestones, created as Tasks:

| Phase | Task | Label | Sprint |
|-------|------|-------|--------|
| Phase 0 | Down payment received | `Phase_0` | Backlog |
| Phase 1 | Phase 1 payment received | `Phase_1` | Sprint 1 |
| Phase 3 | Final payment received | `Phase_3` | Phase 3: Closing |

---

## 9. Quality Checklist

Before presenting results to the user at each gate, verify:

### Environment & Project Configuration (Gate 0)
- [ ] Project code (Jira key), full name, PM email, and Designer email collected from user
- [ ] Jira project created or verified via API
- [ ] PM email resolved to Jira accountId and set as project lead
- [ ] All 5 fixed administrators added to role 10002 (Administrators) and role 10785 (DM)
- [ ] Any unresolvable admin emails flagged to user for manual addition
- [ ] `.du-skills.yaml` updated with `project_key`, `project_name`, `pm_email`, `designer_email`

### Documentation Intake (Gate 1)
- [ ] All 14 document types checked for existence
- [ ] Cross-reference matrix built (module → feature → story)
- [ ] All inconsistencies flagged with specific references
- [ ] Team composition and roles extracted
- [ ] Sprint planning extracted with dates and module mapping

### Completeness Assessment (Gate 2)
- [ ] Every RED gap has a clear question for the user
- [ ] Every YELLOW gap has a concrete proposal
- [ ] Doc update proposals include exact diffs
- [ ] No gap is silently ignored

### Planning Validation (Gate 3)
- [ ] Sprint capacities are realistic (challenged by 2 experts)
- [ ] Dependencies between modules respected
- [ ] Resource allocation covers all sub-task types
- [ ] Payment milestones aligned with sprint schedule
- [ ] Admin/Consumer FE consolidation evaluated

### Structure Design (Gate 4)
- [ ] Every WBS story appears exactly once in the Jira structure
- [ ] Epic grouping follows the PRD module structure
- [ ] Sprint assignment matches the planning from phases.md
- [ ] Sub-task breakdown matches team composition
- [ ] Phase 0/1/3 tasks are complete

### Generation (Gate 5)
- [ ] All API calls return 2xx
- [ ] Every issue has a non-empty description
- [ ] Parent-child relationships are correct
- [ ] Sprint assignments are correct
- [ ] Labels are applied to Phase 0/1/3 tasks
- [ ] Rate limiting respected (200ms between calls)

### Verification (Gate 6)
- [ ] Issue count matches approved structure
- [ ] 1:1 mapping between WBS stories and Jira stories verified
- [ ] All epics have at least one story
- [ ] All stories have at least one sub-task
- [ ] `.du-skills.yaml` updated with Jira metadata

---

## 10. Error Handling

### 10.1 API Errors

| Error | Action |
|-------|--------|
| 401 Unauthorized | Check `JIRA_EMAIL` and `JIRA_API_KEY`. Ask user to verify credentials. |
| 403 Forbidden | User lacks permissions. Ask them to check Jira project permissions. |
| 404 Not Found | Project key doesn't exist. Ask user to verify or create the project manually. |
| 429 Rate Limited | Increase delay between calls. Retry after the `Retry-After` header value. |
| 400 Bad Request | Log the full response body. Usually indicates invalid field values or ADF format errors. Fix and retry. |

### 10.2 Partial Failure

If generation fails mid-way:
1. Log all successfully created issue keys
2. Report the failure point to the user
3. Offer to resume from the failure point (skip already-created issues)
4. Never duplicate issues — always check for existing issues before creating

### 10.3 Documentation Gaps

If a document is missing or empty:
1. Flag it as a RED gap in the Completeness Report
2. Do NOT proceed with generation until resolved
3. Offer to generate the missing document using the `/documentation` skill (for technical docs) or ask the user to provide it (for functional docs)

---

## 11. Post-Scaffold Recommendations

After successful scaffold, recommend to the user:

1. **QC Board**: Create a parallel QC board (instructions in section 6.2)
2. **Sprint refinement**: Schedule a sprint planning session to refine stories with the team
3. **Jira Review**: Run `/jira-review` periodically to keep Jira aligned with docs and code
4. **Definition of Done**: Establish DoD criteria for stories (code reviewed, QC passed, docs updated)
5. **Velocity tracking**: After Sprint 1, use actual velocity to re-calibrate the sprint plan

---

## 12. Cross-Skill Integration

### 12.1 Input from Documentation Skill

The Jira scaffold consumes documents produced by `/documentation`:

| Document | Used For | Key Data Extracted |
|----------|----------|-------------------|
| `prd.md` | Epic creation | Module list, feature hierarchy, personas |
| `wbs.md` | Story creation | User stories with US-XXX IDs, estimates |
| `phases.md` | Sprint structure | Sprint count, duration, module-to-sprint mapping |
| `architecture.md` | Technical sub-tasks | DB tables, Edge Functions, API routes |
| `specs.md` | Acceptance criteria | Performance, security, a11y requirements |

**The Jira scaffold validates that ALL required documentation exists before proceeding.**

### 12.2 Output to Code Scaffolding

The Jira project scaffolded here serves as the PRIMARY TRACKING INPUT for `/monorepo-scaffold`:

| Jira Element | Used By Code Scaffold For |
|--------------|--------------------------|
| **Epics** | Module-based package organization |
| **Stories** | Feature-based route/component structure |
| **[BE] sub-tasks** | API endpoint generation, DB migrations |
| **[FE] sub-tasks** | Screen/component generation |
| **[QC] sub-tasks** | Test file generation |
| **Sprints** | Incremental implementation order |

**Recommended workflow:**
1. Run `/documentation` → produces complete technical docs
2. Run `/jira-scaffold` → produces complete Jira backlog with technical sub-tasks
3. Run `/monorepo-scaffold` → uses both docs AND Jira to scaffold code
   - Docs provide architecture and technical decisions
   - Jira provides incremental task breakdown and tracking

When `/monorepo-scaffold` runs, it should:
1. Read the Jira project for current sprint and assigned stories
2. Generate code specifically targeting the stories in the current sprint
3. Mark Jira sub-tasks as "In Progress" when code is scaffolded for them
4. Allow developers to work through stories in Jira order

**After code scaffolding**, developers work through Jira stories in order, with all technical tasks already defined. No developer should ever need to create their own technical tickets.
