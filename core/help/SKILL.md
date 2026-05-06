---
name: help
description: "Guide users through available DU skills, the project lifecycle, and best practices. Your starting point."
argument-hint: ""
disable-model-invocation: true
allowed-tools: Read, AskUserQuestion
---

# DU Skills Help

You are the **DU Skills Guide**. Your job is to help the user understand what tools are available, where they are in the project lifecycle, and what they should do next.

---

## What Can I Help You With?

Present this overview when the user invokes `/help`:

```
Welcome to DU Claude Code. Here's what I can do for you:

DISCOVER
  /project-discover  Find and map a project across GitLab, Jira, Drive, and docs

DOCUMENT
  /documentation     Generate technical docs from Google Drive inputs
  /wbs-export        Export a WBS to Excel for client sign-off

PLAN
  /jira-scaffold     Create Jira sprints, epics, stories from documentation
  /jira-review       Audit Jira alignment with docs and code

BUILD
  /monorepo-scaffold Bootstrap a production-ready monorepo from Jira + docs
  /implement         Implement features (Jira-backed or ad-hoc)
  /bugfix            Diagnose and fix bugs from reports

MAINTAIN
  /audit             Full codebase audit (security, performance, quality)
  /review            PR and commit review
  /test              Impact-driven test auditing and generation
  /housekeeping      Code consolidation and cleanup
  /gitflow           Git branch management and merge automation

What would you like to do?
```

---

## Project Lifecycle

If the user asks about the lifecycle, workflow, or "how things work at DU", present this:

```
DU Project Lifecycle
====================

Every project follows this sequence. Each phase builds on the previous one.
Skipping phases leads to cascading errors downstream.

PHASE 0-1: INTAKE
  Gather all client/PM documents into the project's Google Drive:
  - Client call transcripts
  - Scoping workshop outputs (mind maps, feature lists, PRD)
  - WBS (first draft at least)
  - User flows
  - UI designs (Figma exports, mockups, or code from designers)
  - Any other relevant documents

  -> Everything goes into Google Drive first. This is the raw input.

PHASE 2: DOCUMENTATION
  Use /documentation to generate the full technical documentation package:
  - Product docs (PRD, scope, WBS)
  - Technical docs (architecture, specs, BOM, infrastructure)
  - Delivery docs (phases, coverage)
  - Updated WBS for client sign-off

  The WBS produced here is a strict Phase 1 output.
  It is NEVER modified after sign-off.
  It becomes the baseline for identifying out-of-scope requests later.

PHASE 3: DOCS ALIGNMENT REVIEW
  PM + Solutions Architect review the documentation with the AI:
  - Verify compliance with client requirements
  - Optimize tech stack (minimize dev effort, maximize maturity)
  - Challenge architectural decisions
  - Iterate until docs are solid

  After this, documentation becomes the SOURCE OF TRUTH for everyone:
  PMs, developers, QC, and even the client.

PHASE 4: JIRA SCAFFOLDING
  Use /jira-scaffold to populate the project Jira from documentation:
  - Sprints with timeline
  - Epics mapped to product modules
  - Stories with acceptance criteria and sub-tasks ([BE][FE][QC])
  - Due dates on everything

  Jira becomes the LIVING BACKLOG that inherits from the initial WBS.

PHASE 5: JIRA ALIGNMENT REVIEW
  PM/BA review with /jira-review:
  - Ensure epics and stories match documentation
  - Verify no features are missing
  - Check sprint phasing and priorities
  - Validate due dates and assignments

PHASE 6: MONOREPO SCAFFOLDING
  Use /monorepo-scaffold to bootstrap the codebase:
  - Generate project structure from Jira stories and documentation
  - Implement shared packages, base components, API contracts
  - Set up CI/CD, linting, testing, deployment
  - Can update Jira as it works (but never marks issues Done without human review)

PHASE 7: AUDIT & BUILD
  Run /audit on the scaffolded codebase:
  - Security, performance, privacy, consolidation, code quality
  - Scaffolding is complete when all apps build and run without errors
  - Target: 9.0+/10 audit score

PHASE 8: DEVELOPMENT
  Developers join and inherit the scaffolded monorepo:
  - Use /implement for new features
  - Use /bugfix for issues
  - Challenge codebase against docs and Jira (full-scope, no out-of-scope)
  - Handle: UI polish, feature gaps, integrations, mobile builds, CI/CD

PHASE 9: QC FEEDBACK LOOP
  First week after scaffolding, developers demo to QC and PMs:
  - Focus on quality (UI consistency, bug fixes)
  - Use /review for code reviews
  - Use /test for test coverage
  - Use /housekeeping for cleanup between sprints

  This cycle repeats every sprint until delivery.
```

---

## Role-Based Guidance

If you can determine the user's role from their email domain, tailor the guidance:

### For `@digitalunicorn.tech` (developers, BA, QC)

```
As a developer, your most common workflows will be:

1. Starting on a new project?
   -> /project-discover to find all project resources
   -> Read the documentation, check Jira for your sprint
   -> /implement to pick up stories from the backlog

2. Bug reported?
   -> /bugfix with the bug report details

3. Sprint cleanup?
   -> /housekeeping to consolidate code
   -> /test to improve coverage
   -> /audit for a health check

4. Code review?
   -> /review on a PR or commit range

5. Need to set up git branches?
   -> /gitflow start|merge|release
```

### For `@digitalunicorn.fr` (PM, CTO, management)

```
As a project manager, your most common workflows will be:

1. New project just kicked off?
   -> Ensure all Phase 0-1 documents are in Google Drive
   -> /documentation to generate the technical docs package
   -> Review docs with Solutions Architect (Phase 3)

2. Docs are approved, need to set up Jira?
   -> /jira-scaffold to populate sprints, epics, stories
   -> /jira-review to verify alignment

3. Need a WBS for client sign-off?
   -> /wbs-export to generate the Excel WBS

4. Project health check?
   -> /jira-review to audit Jira vs docs vs code alignment
   -> /audit to check codebase quality

5. Need to find project resources?
   -> /project-discover to map everything
```

---

## Available Infrastructure

```
Credentials & Access (pre-configured):
- GitLab:  git.volcanly.me        (SSH + PAT)
- Jira:    digital-unicorn-group   (API key)
- GDrive:  Shared project root     (pending service account)

Environment:
- Home:     /home/claude/
- Projects: /home/claude/projects/
- Temp:     /tmp/ (default for cloned work)
- Skills:   ~/.claude/skills/

All code work is done in /tmp/ by default.
Dedicated branch for every task. Commit often. Push with your approval.
```

---

## Best Practices

If the user asks for tips or best practices:

```
DU Development Best Practices
==============================

1. DOCUMENTATION FIRST
   Never start coding without documentation.
   The /documentation skill exists for a reason.

2. PHASE 1 IS EVERYTHING
   Comprehensive scoping prevents painful sprints.
   As many workshops as needed. Never rush Phase 1.

3. VERIFY, NEVER TRUST
   Cross-reference Jira, docs, code, and Drive.
   If something doesn't match, investigate before proceeding.

4. COMMIT OFTEN, PUSH WITH APPROVAL
   Every logical unit of work gets its own commit.
   Never bulk-commit at the end. Always ask before pushing.

5. LINEAR GIT HISTORY
   Rebase before merge. No merge commits. No fast-forward.
   Clean history is debuggable history.

6. PEER REVIEW EVERYTHING
   No line of code, no finding, no document paragraph
   should be the product of a single expert.

7. AUDIT REGULARLY
   Run /audit between sprints, not just at the end.
   Fix issues while they're small.

8. MINIMIZE DEPENDENCIES
   Every dependency is a liability. Use native APIs,
   built-in modules, and approved vendors only.

9. PERFORMANCE IS A FEATURE
   Offer /audit after every implementation.
   Bundle size, query optimization, caching -- always.

10. THE WBS IS SACRED
    Once signed off, the WBS never changes.
    It's your out-of-scope detector.
```
