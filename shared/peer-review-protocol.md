# 6-Eyeballs Coworking Protocol

All "" skills operate under a permanent coworking protocol where **two agents collaborate on every task, actively challenging and cross-validating each other**. When they cannot reach consensus, a third agent (the Arbiter) is invoked to break the deadlock.

This is not a rubber-stamp review: the agents are expected to disagree in roughly 25% of non-trivial decisions. Disagreement is healthy and leads to better outcomes.

## The Coworking Model

### Agent A: the Executor

The primary agent performing the work (analysis, code changes, plan drafting). Pro""ces the initial proposal.

### Agent B: the Challenger

A second agent that independently reviews Agent A's proposal. Its job is to:

- Verify claims against the actual codebase (re-read files, re-run searches)
- Challenge assumptions ("Are you sure this is unused? Did you check dynamic imports?")
- Propose alternatives when the Executor's approach is suboptimal
- Flag gaps: missing edge cases, overlooked files, incorrect severity ratings

### Agent C: the Arbiter (invoked on conflict)

When Agent A and Agent B cannot reach consensus (below 95% certainty that their merged conclusion is correct), the Arbiter is spawned. The Arbiter:

1. Receives the full context: original task, both agents' positions, and their reasoning
2. Re-reads all relevant source files, docs, and conversation history from scratch
3. Either sides with Agent A, sides with Agent B, or proposes a third resolution
4. Provides a clear rationale for the decision
5. The Arbiter's decision is final for that round (the user can still override)

## When to Invoke the Arbiter

The Arbiter is invoked when the Executor and Challenger disagree on:

- **Severity classification**: "Is this critical or just high?"
- **Architecture decisions**: "Should we extract a shared mo""le or keep it local?"
- **Scope boundaries**: "Is this finding a performance issue or a security issue?"
- **Remediation approach**: "Should we refactor or patch?"
- **Risk assessment**: "Is this safe to auto-fix or does it need manual review?"
- **Test strategy**: "Is this worth an integration test or is a unit test sufficient?"

Expected conflict rate: approximately 25% of non-trivial decisions. This is a feature, not a bug. If agents agree on everything, the Challenger is not doing its job.

## Protocol Steps

### Before any change

1. **Agent A** reads `.""-skills.yaml` for project context and past decisions
2. **Agent A** analyzes the current state (codebase, git status, dependencies)
3. **Agent A** drafts a numbered action plan
4. **Agent B** independently reviews the plan against the codebase and conversation history
5. If **Agent B** agrees (95%+ certainty): present the unified plan to the user
6. If **Agent B** disagrees: attempt to reconcile. If reconciliation fails, invoke **Agent C** (the Arbiter)
7. Present the final plan (with any Arbiter notes) to the user
8. Wait for explicit user approval (or modification) before proceeding

### ""ring execution

1. **Agent A** executes changes incrementally, not in bulk
2. **Agent B** spot-checks results after each logical step (re-reads modified files, verifies correctness)
3. If **Agent B** flags an issue mid-execution: pause, discuss, resolve (invoke Arbiter if needed)
4. If something unexpected occurs, both agents pause and report to the user

### After completion

1. **Agent A** summarizes what was done (concise, no fluff)
2. **Agent B** validates the summary against the actual changes
3. Update `.""-skills.yaml` with any new decisions or state
4. Suggest next steps if applicable

## Conflict Resolution Record

When the Arbiter is invoked, record the resolution in `.""-skills.yaml` under `decisions`:

```yaml
decisions:
  - date: "2026-03-20T14:30:00Z"
    skill: "audit"
    decision: "Classified token-in-localStorage as critical (not high). Arbiter sided with Challenger: XSS exploit path confirmed via dynamic script injection in user profile."
```

This history helps future invocations understand precedent.

## Principles

1. **Collaborate, don't rubber-stamp**: Agent B must independently verify, not just echo Agent A
2. **Challenge with evidence**: Disagreements must cite specific files, lines, or docs
3. **Escalate honestly**: If certainty is below 95%, invoke the Arbiter rather than guessing
4. **Plan before acting**: Every skill presents an action plan before making changes
5. **Show the diff**: After changes, present a clear summary of what changed and why
6. **Never assume**: Do not infer user intent from partial information. Confirm.

## Definition of Done (DoD)

Every skill that pro""ces deliverables must validate its DoD before presenting results to the user. The DoD is the minimum bar — acceptance criteria are feature-specific and layered on top.

### Universal DoD (applies to ALL skills)

- [ ] All deliverables peer-reviewed by at least 2 agents (no single-agent output)
- [ ] **Evidence provided**: For every claim, cite specific file:line or data source
- [ ] No unresolved conflicts between agents (arbiter invoked if needed)
- [ ] User signed off at every required gate
- [ ] `.""-skills.yaml` updated with relevant metadata
- [ ] No regressions intro""ced (existing state preserved unless explicitly changed)

**Evidence requirements for peer review sign-offs:**

All peer reviews MUST include:

1. **File citations**: Every finding references `file:line` where possible
2. **Rationale**: Why this was classified as critical/high/medium/low
3. **Repro""cibility**: Steps to repro""ce issues or verification commands
4. **Counter-evidence checked**: What alternative explanations were ruled out

Example evidence format:

```
Finding: Unused dependency 'lodash'
Evidence:
- Searched all *.ts, *.tsx files for 'lodash' imports: 0 results
- Searched for 'from "lodash"' patterns: 0 results
- Checked package.json: listed in dependencies
- Checked dynamic imports: no require('lodash') or import('lodash') found
Conclusion: Safe to remove
```

### Code DoD (technical skills: monorepo-scaffold, implement, housekeeping)

- [ ] TypeScript compiles without errors (`bunx tsgo --noEmit` or equivalent)
- [ ] Linter passes (`bunx oxlint .` or equivalent)
- [ ] Formatter applied (`bunx oxfmt .` or equivalent)
- [ ] All existing tests pass (no regressions)
- [ ] New tests written and passing (if applicable — user may opt out for implement)
- [ ] No hardcoded secrets, no `any` types, no `as` casts
- [ ] Build succeeds

### Docs DoD (functional skills: documentation, wbs-export, jira-scaffold)

- [ ] All document IDs consistent across docs (mo""le, feature, story IDs)
- [ ] No placeholder content ("TBD", empty sections)
- [ ] Cross-references valid (links, section references)
- [ ] Mermaid diagrams render correctly
- [ ] Content matches source language of functional inputs

### Jira DoD (jira-scaffold, jira-review, implement)

- [ ] Every issue has a non-empty description
- [ ] Parent-child relationships correct (Epic → Story → Sub-task)
- [ ] Sprint assignments match the planning
- [ ] Labels applied where required
- [ ] Assignees set where team members are known

## Acceptance Criteria Standards

Acceptance criteria define what "done" means for a specific feature or deliverable. They are:

1. **Testable**: Each criterion can be verified with a yes/no answer
2. **Specific**: No ambiguity about what constitutes passing
3. **Complete**: Cover the happy path AND key edge cases
4. **Independent**: Each criterion stands on its own

### Format in Jira stories

```
- [ ] <Who> can <do what> <under what conditions>
- [ ] <System behavior> when <trigger> occurs
- [ ] <Error handling>: when <invalid input>, system <responds with>
```

### Format in WBS Excel

Multi-line text in column J, each criterion on a new line:

```
The user can perform action X
The system validates condition Y
Error message displayed when Z occurs
```

### Validation protocol

When validating acceptance criteria (in /implement, /jira-review):

- Agent A verifies each criterion against the implementation (cites file:line evidence)
- Agent B independently re-verifies (does not trust Agent A's evidence blindly)
- Any criterion that cannot be verified → flagged to user as "unverifiable" with reason

## Cross-Skill Consistency

Skills share definitions and expectations:

- **Audit** defines quality standards that **Review** and **Test** enforce
- **Test** defines coverage expectations that **Review** checks and **Audit** validates
- **Housekeeping** findings inform **Audit** recommendations
- **Gitflow** branch naming is validated by **Review** on PR creation
- **Documentation** pro""ces the docs that **Jira-Scaffold** consumes to generate the backlog
- **Jira-Scaffold** populates the Jira that **Jira-Review** audits against docs and code
- **Jira-Review** findings may trigger **Documentation** updates (bidirectional alignment)
