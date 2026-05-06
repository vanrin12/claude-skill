# "" Skills for Claude Code

Professional-grade skills for software development agencies. Supports mobile, web, backend, AI, blockchain, and enterprise projects. All skills use multi-expert collaboration — no single-entity decisions.

## Quick Start

### One-line install

```bash
git clone git@your-git-repo:""-v2/claude-skills.git ~/.local/share/""-skills
~/.local/share/""-skills/install.sh /path/to/your/project
```

### Or manually

```bash
# Clone the skills repo
git clone git@your-git-repo:""-v2/claude-skills.git ~/.local/share/""-skills

# In any project, symlink the skills
cd /path/to/your/project
mkdir -p .claude/skills
for skill in functional technical; do
  ln -sf ~/.local/share/""-skills/$skill .claude/skills/
done
```

### Update

```bash
cd ~/.local/share/""-skills && git pull
```

Skills are symlinked, so updates are instant across all projects.

---

## Table of Contents

1. [Project Lifecycle](#project-lifecycle)
2. [All Skills Reference](#all-skills-reference)
3. [6-Eyeballs Coworking Protocol](#6-eyeballs-coworking-protocol)
4. [Quality Gates & Definition of Done](#quality-gates--definition-of-done)
5. [Configuration](#configuration)
6. [Authentication](#authentication)
7. [Contributing](#contributing)

---

## Project Lifecycle

### Starting a New Project

When starting a new software project, ALWAYS follow this order:

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                            PROJECT LIFECYCLE                                         │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│  1. GATHER INPUTS                                                                   │
│     ├── Google Drive (pro""ct brief, WBS, transcripts)                             │
│     └── UI/UX Assets (coded prototype preferred, or wireframes)                    │
│                                                                                     │
│  2. /documentation ─────────────────────────────────────────────────────────┐      │
│     ├── Phase 0: Input validation (Google Drive, UI/UX assets)                 │      │
│     ├── Phase 1-5: 6+ experts draft docs (architecture, BOM, infra, specs)     │      │
│     ├── Phase 6: GitLab repo setup (CI/CD, .gitignore)                          │      │
│     └── Phase 7: FRESH expert team audit (different from drafters)              │      │
│                                                                               │      │
│  3. BRANCH: Choose Your Path ────────────────────────────────────────────────┤      │
│                                                                               │      │
│     ┌─────────────────┐         ┌─────────────────┐                           │      │
│     │  Path A: Full   │         │  Path B: Code   │                           │      │
│     │  Scaffold       │         │  First          │                           │      │
│     └─────────────────┘         └─────────────────┘                           │      │
│            │                            │                                      │      │
│            ▼                            ▼                                      │      │
│     /jira-scaffold              /monorepo-scaffold                              │      │
│     ├── Reads docs               ├── Reads docs                                  │      │
│     ├── Collects metadata        ├── Phase 0: Validation gate                   │      │
│     ├── Creates Jira project     ├── Phase 1-6: 6-10 experts generate code      │      │
│     ├── Generates epics          └── Phase 7: FRESH audit team                  │      │
│     ├── Generates stories                          │                            │      │
│     ├── Generates sub-tasks                       │                            │      │
│     └── Sets ""e dates (feature: Tue week2, QC: Fri week2)                    │      │
│            │                            │                                      │      │
│            └────────────┬───────────────┘                                      │      │
│                         ▼                                                       │      │
│                 /monorepo-scaffold ◄───────────────────────────────────────────┘      │
│                 (if Path A taken, Jira already exists)                                 │
│                 ├── Uses docs for architecture/tech decisions                          │
│                 └── Uses Jira stories for incremental implementation                    │
│                                                                                     │
│  4. DEVELOPMENT CYCLE (Iterative)                                                   │
│                                                                                     │
│     ┌──────────────────────────────────────────────────────────────────────────┐    │
│     │                                                                           │    │
│     │  /gitflow ──► /implement ──► /review ──► /test ──► merge                  │    │
│     │     │              │             │          │                             │    │
│     │     ▼              ▼             ▼          ▼                             │    │
│     │  Branch         Feature       PR        Tests                            │    │
│     │  from Jira      built         reviewed   passing                         │    │
│     │                                                                           │    │
│     └──────────────────────────────────────────────────────────────────────────┘    │
│                                                                                     │
│  5. MAINTENANCE (ongoing)                                                           │
│     ├── /jira-review ──► Verify Jira matches docs & code                           │
│     ├── /audit ─────────► Full codebase health check (7 dimensions)               │
│     ├── /housekeeping ──► Code de""plication and cleanup                          │
│     └── /wbs-export ────► Export Jira to Excel WBS for client delivery            │
│                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Key Principles

1. **Documentation First**: Never scaffold code without documentation. Docs drive both Jira and code.
2. **Jira Guided**: Developers work through Jira stories. All technical tasks pre-defined with ""e dates.
3. **Multi-Expert Collaboration**: Every skill uses 4-6+ experts. No single-entity decisions.
4. **Independent Audit**: Fresh team (not original drafters) audits all deliverables.
5. **GitLab Native**: All skills work with GitLab (groups, repos, CI/CD, SSH remotes).

---

## All Skills Reference

### Functional Skills

#### `/documentation` — Technical Documentation Drafting

**Use when**: You need to create complete technical documentation from client inputs.

**Inputs** (Required):

- Google Drive URL containing: pro""ct brief, WBS, feature list, call transcripts
- UI/UX assets (coded prototype preferred, or Figma exports/screenshots)
- Existing docs repo (optional, for updates)

**Outputs**:

```
<project>/
├── 01-pro""ct/
│   ├── prd.{lang}.md         # Pro""ct requirements, mo""les, features
│   ├── scope.{lang}.md       # In/out decisions, arbitrage register
│   └── wbs.{lang}.md         # User stories with priorities
├── 03-technical/
│   ├── architecture.{lang}.md    # DB schema, Edge Functions, ADRs
│   ├── bom.{lang}.md             # All dependencies with versions
│   ├── infrastructure.{lang}.md  # Hosting, CI/CD, monitoring
│   └── specs.{lang}.md           # NFRs: performance, security, a11y
├── 04-delivery/
│   ├── phases.{lang}.md          # Sprint planning, resources, Gantt
│   └── coverage.{lang}.md        # Platform support matrix
├── .gitlab-ci.yml                # Translation + reindex pipeline
└── .gitignore                    # Excludes data/, *.db, *_state.json
```

**Quality Gates**:

- Phase 0 validation: Google Drive must contain required docs, <30% placeholder content
- Phase 7 audit: FRESH expert team (not drafters) reviews all outputs
- All documents must have cross-references, no "TBD" placeholders

**Team**: 6+ experts (Functional, UX, Technical, Architecture, BOM, Infrastructure, Specs, Phases, Coverage writers) + FRESH audit team

**Integration**: Outputs → `/jira-scaffold` (epics from PRD, stories from WBS) and `/monorepo-scaffold` (architecture → structure, BOM → dependencies)

---

#### `/jira-scaffold` — Jira Project Scaffolding

**Use when**: You need to create a complete Jira project with epics, stories, and technical sub-tasks.

**Inputs** (Required):

- Documentation from `/documentation`
- Project metadata: code (Jira key), full name, PM email (@digitalunicorn.fr), UI/UX designer email
- Team member emails (optional: BA, Tech Lead, Lead QC, Lead FE, Lead BE)

**Outputs**:

- Jira Project with:
  - Sprints: Sprint 1, Sprint 2, ..., Sprint N, Phase 3: Closing
  - Epics: [PLATFORM] Mo""le Name
  - Stories: [Platform] Verb + noun (US-XXX) with **""e dates** (Tuesday of week 2)
  - Sub-tasks: [BE], [FE], [QC] with **""e dates** ([BE]/[FE]: Tuesday week 2, [QC]: Friday week 2)
  - Phase 0/1/3 tasks
- Fixed board administrators (5 roles): PM + 4 standing "" roles

**Quality Gates**:

- PM email validation: must match `^[a-zA-Z0-9._%+-]+@digitalunicorn\.fr$`
- All administrators must resolve successfully (HALT if any fail)
- Every story MUST have technical sub-tasks (developers never create their own)
- ""e dates set on all stories and sub-tasks for timeline view visibility

**Sprint Timeline** (14 days):

- Days 1-10 (Monday-Tuesday week 2): Feature implementation ([BE]/[FE] ""e)
- Days 11-14 (Wednesday-Friday week 2): QA/QC loops ([QC] ""e)

**Team**: Scaffold team (4-6 experts) + Audit team (2 FRESH experts)

**Integration**: Inputs ← `/documentation` (PRD → epics, WBS → stories, phases → sprints)

---

#### `/jira-review` — Jira Compliance Audit

**Use when**: You need to verify Jira matches documentation and code.

**Inputs**:

- Jira project key
- Documentation directory path
- Codebase directory path

**Outputs**:

- Alignment audit report (3 matrices: Jira ↔ Docs, Jira ↔ Code, Docs ↔ Code)
- Proposed updates (bidirectional: docs updates, Jira updates, code changes)
- Discrepancy list with severity ratings

**Quality Gates**:

- 3 parallel experts (Jira, Docs, Codebase) independently analyze
- Cross-comparison builds 4 alignment matrices
- Disputed findings flagged for user review
- User approval required for each proposed update

**Team**: 3 experts + consensus team

---

#### `/wbs-export` — Jira to Excel Export

**Use when**: You need to export Jira to Excel WBS format for client delivery.

**Inputs**:

- Jira project key
- Documentation directory

**Outputs**:

- Excel file with 4 sheets: "Work Breakdown Structure", "Features", "Team", "Timeline"
- Gantt chart with dark blue fill (FF002060)
- Exact "" template formatting

**Quality Gates**:

- 2 agents: Functional (content) + Planning (format)
- All cells must be populated (no blanks)
- Sheet names must match exactly
- User sign-off required before final delivery

**Team**: 2 experts + validation team

---

### Technical Skills

#### `/monorepo-scaffold` — Codebase Scaffolding

**Use when**: You need to generate a complete, pro""ction-ready monorepo from documentation.

**Inputs** (Required):

- Documentation from `/documentation`
- Jira project (from `/jira-scaffold`, strongly recommended)
- GitLab credentials (for group/repo creation)

**Outputs** (architecture-dependent):

```
<project>/
├── apps/
│   ├── mobile/          # Expo or Flutter (iOS + Android)
│   ├── admin/           # Admin dashboard
│   └── web/             # Web app (if web-first)
├── packages/
│   ├── shared/          # Types, schemas, clients
│   ├── ui/              # Shared components
│   └── hooks/           # Shared providers/hooks
├── supabase/            # Migrations, Edge Functions
├── infra/               # Docker, deployment configs
├── .gitlab-ci.yml       # Full CI/CD pipeline
├── .""-skills.yaml      # Project configuration
└── README.md
```

**Quality Gates**:

- Phase 0: Validation gate (docs exist with content, Jira accessible, GitLab token available)
- Phase 2: Architecture consensus (user sign-off required)
- Phase 7: FRESH audit team (not scaffolders) reviews generated code
- All packages must resolve, type-check passes, no CVEs in dependencies

**Team**: Core team (4: Architect, FE Lead, BE Lead, DevOps Lead) + Specialists (2-6) + FRESH audit team

**Integration**: Inputs ← `/documentation` (architecture) and `/jira-scaffold` (stories for incremental implementation)

---

#### `/gitflow` — Git Workflow Automation

**Use when**: You need to create branches, merge to dev/main, handle rebase conflicts, or integrate with Jira.

**Inputs**:

- Action: `start`, `merge`, `release`, `status`
- Jira issue ID or work description
- Project path (default: current directory)

**Outputs**:

- Properly named branches following conventions
- Merged commits via rebase-merge strategy
- Jira issue transitions (if configured)

**Branch Types**:

- `feat/` - New features
- `fix/` - Bug fixes
- `chore/` - Dependencies, tooling
- `docs/` - Documentation
- `refactor/` - Restructuring
- `test/` - Tests
- `perf/` - Performance
- `ci/` - CI/CD
- `style/` - Formatting

**Quality Gates**:

- Jira configuration validated before use (explicit prompt if missing)
- Branch creation verified (HALT on failure)
- Never auto-resolve merge conflicts without user input
- Jira transition as required step (ask user explicitly)

**Integration**: Reads/writes `.""-skills.yaml` (gitflow, jira sections)

---

#### `/implement` — Feature Implementation

**Use when**: You need to build a feature guided by a Jira sub-task.

**Inputs**:

- Jira sub-task key or ad-hoc feature description
- Project path (default: current directory)

**Outputs**:

- Implemented feature in isolated worktree
- Peer-programmed code (every file reviewed by 2+ agents)
- Tests (optional, mandatory for payment/security features)
- Merged to dev via rebase-merge

**Gates** (7 total, 3 require user sign-off):

1. Project discovery
2. Feature selection (Jira housekeeping or ad-hoc)
3. Implementation planning → **User sign-off required**
4. Branch & worktree setup
5. Implementation (peer-programmed)
6. Testing
7. Validation → **User sign-off required**
8. Merge & cleanup → **User sign-off required**

**Quality Gates**:

- All code peer-reviewed (6-eyeballs protocol)
- Acceptance criteria validated
- DoD checklist: compiles, lints, formats, tests pass, no regressions

**Team**: 2 experts peer-programming + Arbiter on conflict

**Integration**: Uses `/gitflow` for branch management, updates Jira on completion

---

#### `/test` — Impact-Driven Test Auditing and Implementation

**Use when**: You need meaningful test coverage (not just inflated percentages).

**Inputs**:

- Repo path
- Action: `audit`, `implement`, `both`
- Test type: `unit`, `integration`, `e2e`, `all`

**Outputs**:

- Test impact audit report OR implemented tests
- Bullshit tests flagged for removal
- Impact score (1-10, weighted by test quality not just quantity)

**Test Impact Classification**:

- **Tier 1 (Critical)**: Auth security, input validation, data integrity, permissions, encryption, compliance, payments
- **Tier 2 (High)**: Core user flows, API contracts, database operations, real-time, error handling
- **Tier 3 (Medium)**: Component behavior, formatting, navigation, a11y
- **Tier 4 (Bullshit)**: Snapshot-only, "renders without crashing", mock-only, no assertions → Flag for removal

**Quality Gates**:

- Coverage target prompt (70/80/90%+) if not configured
- Test strategy prompt (critical-first/balanced/comprehensive) if not configured
- All tests must catch real bugs (no implementation-detail tests)
- Verification: tests pass, coverage measured, impact score calculated

**Team**: Executor + Challenger (questions every test: "What real bug does this catch?") + Arbiter

**Integration**: Findings feed into `/audit` (test coverage dimension), `/housekeeping` (Tier 4 removal), `/review` (PR validation)

---

#### `/review` — PR/Commit Review

**Use when**: You need to review a PR, commit, or branch before merging.

**Inputs**:

- PR number, commit hash, or branch name

**Outputs**:

- Review report with findings by severity (Critical/High/Medium/Low/Info)
- Test coverage assessment
- Test proposals (if gaps identified)

**Review Dimensions** (7 total):

1. Coherence - Does code match intent?
2. Commit Message - Conventional format?
3. Code Quality - Linter, types, patterns
4. Security - Injection, auth, secrets
5. Performance - N+1, optimization opportunities
6. Test Coverage - Are tests meaningful?
7. Documentation - Is it documented?

**Quality Gates**:

- All findings peer-reviewed (6-eyeballs)
- Severity classification cross-validated
- User sign-off required for test proposals

**Team**: Executor + Challenger + Arbiter

---

#### `/audit` — Full Codebase Audit

**Use when**: You need a comprehensive health check across all quality dimensions.

**Inputs**:

- Repo path
- Focus dimension (optional): security, privacy, performance, consolidation, architecture, devops, code-quality, ux-ui, test-coverage

**Outputs**:

- 7+ markdown reports by dimension:
  - security.md (20% weight)
  - performance.md (20%)
  - privacy.md (15%)
  - consolidation.md (15%)
  - code-quality.md (10%)
  - ux-ui.md (10%)
  - test-coverage.md (10%)
- Prioritized remediation plan
- Overall score (1-10)

**Quality Gates**:

- 6-10 expert auditors (1-2 per dimension, parallel execution)
- Cross-validation between auditors
- Each finding includes: severity, evidence (file:line), remediation
- All findings peer-reviewed before presentation

**Team**: 6-10 experts + consensus team

**Integration**: Outputs feed into `/housekeeping` (consolidation), `/test` (coverage gaps), `/review` (standards)

---

#### `/housekeeping` — Code Consolidation and Cleanup

**Use when**: You need to clean up re""ndant code, remove unused dependencies, de""plicate logic.

**Inputs**:

- Repo path
- Scope: `deps`, `code`, `styles`, `all`
- Aggressiveness: `aggressive` (default), `moderate`, `conservative`

**Outputs**:

- Housekeeping report:
  - Unused dependencies (safe to remove)
  - ""plicate dependencies (consolidation opportunities)
  - Code ""plication (near-identical blocks)
  - Dead code (unused exports, unreachable code)
  - Monorepo sharing opportunities
- Consolidated code (if approved)

**Analysis Dimensions** (6):

1. Dependencies - Unused, ""plicates, outdated, heavy
2. Code De""plication - Identical blocks, genericization opportunities
3. Style/Component Consolidation - CSS, component variants
4. Constants and Configuration - Hardcoded values, config centralization
5. Dead Code Removal - Unused exports, unreachable code, stale code
6. Monorepo Code Sharing - Cross-package type/utility/schema sharing

**Quality Gates**:

- Scope prompt if not specified
- Explicit confirmation before ANY changes (HALT without approval)
- Per-deletion confirmation for destructive actions
- Tests run after each change

**Team**: Executor (scans and proposes) + Challenger (verifies each target: "Is this truly unused?") + Arbiter

**Integration**: Findings inform `/audit` recommendations, `/scaffold` shared package design

---

## 6-Eyeballs Coworking Protocol

All "" skills operate under a permanent coworking protocol where **two agents collaborate on every task, actively challenging and cross-validating each other**.

### The Model

1. **Agent A (Executor)**: Performs the primary work, pro""ces initial proposal
2. **Agent B (Challenger)**: Independently verifies, challenges assumptions, flags gaps
3. **Agent C (Arbiter)**: Invoked when A and B disagree (~25% of non-trivial decisions)

### When to Invoke the Arbiter

The Arbiter is invoked when the Executor and Challenger disagree on:

- Severity classification (Critical vs High)
- Architecture decisions
- Scope boundaries
- Remediation approach
- Risk assessment

### Evidence Requirements

All peer reviews MUST include:

1. **File citations**: Every finding references `file:line` where possible
2. **Rationale**: Why this was classified as critical/high/medium/low
3. **Repro""cibility**: Steps to repro""ce issues or verification commands
4. **Counter-evidence checked**: What alternative explanations were ruled out

### Conflict Resolution Record

When the Arbiter is invoked, record the resolution in `.""-skills.yaml`:

```yaml
decisions:
  - date: "2026-03-20T14:30:00Z"
    skill: "audit"
    decision: "Classified token-in-localStorage as critical. Arbiter sided with Challenger: XSS exploit path confirmed."
```

---

## Quality Gates & Definition of Done

### Universal DoD (ALL skills)

- [ ] All deliverables peer-reviewed by at least 2 agents
- [ ] Evidence provided for every claim (file:line citations)
- [ ] No unresolved conflicts between agents
- [ ] User signed off at every required gate
- [ ] `.""-skills.yaml` updated with relevant metadata
- [ ] No regressions intro""ced

### Code DoD (technical skills)

- [ ] TypeScript compiles without errors
- [ ] Linter passes
- [ ] Formatter applied
- [ ] All existing tests pass
- [ ] New tests written and passing (if applicable)
- [ ] No hardcoded secrets, no `any` types, no `as` casts

### Docs DoD (functional skills)

- [ ] All document IDs consistent across docs
- [ ] No placeholder content ("TBD", empty sections)
- [ ] Cross-references valid (links, section references)
- [ ] Mermaid diagrams render correctly
- [ ] Content matches source language

### Jira DoD (jira skills)

- [ ] Every issue has a non-empty description
- [ ] Parent-child relationships correct
- [ ] Sprint assignments match planning
- [ ] Labels applied where required
- [ ] ""e dates set on stories and sub-tasks
- [ ] Assignees set where team members known

---

## Configuration

All skills read from and write to `.""-skills.yaml` at the repo root:

```yaml
project:
  name: "" # Auto-detected
  client: "" # Set by user
  repo_url: "" # Git remote
  monorepo: false # Auto-detected

stack:
  detected: [] # Auto-detected frameworks
  platform_primary: "" # "mobile-first" or "web-first"
  languages: [] # TypeScript, Dart, etc.

jira:
  base_url: "https://digital-unicorn-group.atlassian.net"
  project_key: "" # e.g., """BA"
  board_id: null
  pm_email: "" # Validated: @digitalunicorn.fr
  designer_email: ""
  sprint_count: null
  epic_count: null
  story_count: null

gitflow:
  base_branch: "dev"
  release_branch: "main"

tests:
  coverage_target: 70 # Prompted if not set
  strategy: "critical-first" # Prompted if not set
  frameworks: [] # Auto-detected

audit:
  coverage_target: "critical-paths"
  overall_score: null

housekeeping:
  de""p_threshold: "aggressive"
  last_run: ""

decisions: []
  # Past user decisions tracked across invocations
```

### Schema Validation

Skills validate their configuration sections before use. Invalid configuration HALTS execution with clear error messages.

---

## Authentication

Skills use GitLab and Jira API keys. Configure as environment variables:

```bash
# GitLab
export GITLAB_TOKEN="glpat-..."

# Jira
export JIRA_EMAIL="your.email@example.com"
export JIRA_API_KEY="..."  # From https://id.atlassian.com/manage-profile/security/api-tokens
```

---

## Skill Matrix

| Skill              | Prerequisites                  | Outputs                 | Dependencies        | Best For        |
| ------------------ | ------------------------------ | ----------------------- | ------------------- | --------------- |
| /documentation     | Google Drive URL, UI/UX assets | Complete technical docs | -                   | New projects    |
| /jira-scaffold     | Docs, team emails              | Jira project + backlog  | /documentation      | Initial setup   |
| /monorepo-scaffold | Docs, Jira (opt)               | Pro""ction codebase     | /documentation      | Initial setup   |
| /gitflow           | Git repo, Jira (opt)           | Branches, merges        | -                   | Daily dev       |
| /implement         | Jira issue or feature desc     | Feature merged          | /gitflow            | Feature dev     |
| /review            | PR, commit, or branch          | Review report           | -                   | PR reviews      |
| /test              | Repo path                      | Audit + tests           | /audit config       | Quality         |
| /audit             | Repo path                      | Health report           | -                   | Periodic checks |
| /housekeeping      | Repo path                      | Cleanup report          | /scaffold decisions | Maintenance     |
| /jira-review       | Jira + docs + code             | Alignment report        | -                   | Maintenance     |
| /wbs-export        | Jira, docs                     | Excel WBS               | -                   | Client delivery |

---

## Contributing

When adding or updating skills:

1. Follow the 6-eyeballs protocol
2. Ensure cross-skill integration is documented
3. Update the README with the new skill's place in the lifecycle
4. Test the skill end-to-end before committing
5. Use conventional commit format

---

## License

Internal "" tool. Not for external distribution.
