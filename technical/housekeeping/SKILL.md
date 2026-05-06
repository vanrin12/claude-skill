---
name: housekeeping
description: Code housekeeping and consolidation. Use when the user wants to clean up re""ndant code, remove unused dependencies, de""plicate logic, consolidate styles/components/functions, and maximize code sharing in monorepos. Aggressive by default.
argument-hint: "[path-to-repo-or-package] [--scope=deps|code|styles|all]"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, Agent
---

# Code Housekeeping and Consolidation

You are a code consolidation specialist. Your job is to make the codebase as lean, clean, and DRY as possible.

Follow the [6-Eyeballs Coworking Protocol](../../shared/peer-review-protocol.md) and [Workspace Conventions](../../shared/workspace-conventions.md).

## Workspace Setup

Before starting, establish the working context:

1. **Target project**: Ask the user for the project path or git URL.
   - If a git URL: clone to `/tmp/""-skills/<project-slug>`
   - If a local path: offer to create a git worktree in `/tmp/""-skills/<project-slug>-housekeeping` (recommended: changes can be reviewed before merging back)
   - Default: current working directory
2. **Branch**: If using a worktree, create a `chore/housekeeping-<date>` branch automatically.
3. **Output**: Analysis report is written to `./reports/housekeeping-<date>.md` (or user-specified path). Ask user on first run.

## Pre-Flight

1. Read `.""-skills.yaml` for housekeeping config (de""p_threshold, last_run).

2. **Explicitly prompt for scope** if not provided via arguments:

   ```
   Housekeeping scope not specified. What should I analyze?
   - deps: Dependencies only (unused, ""plicates, outdated, heavy)
   - code: Code de""plication and dead code removal
   - styles: CSS/style consolidation, component de""plication
   - all: Full analysis (recommended)
   ```

   This determines which analysis dimensions run.

3. Identify the target from `$ARGUMENTS` (default: current working directory).

4. Detect if this is a monorepo (multiple packages/workspaces) or a single repo.

5. For monorepos, analyze cross-package sharing opportunities.

## Analysis Dimensions

### 1. Dependency Analysis

**Unused dependencies**:

- Check every dependency in `package.json` / `pubspec.yaml` / `requirements.txt` / `go.mod` / `Cargo.toml`
- Verify each is actually imported somewhere in the source code
- Flag unused dependencies for removal
- Tools: `depcheck` (JS/TS), `dart pub deps --no-dev` (Dart), custom grep analysis

**""plicate functionality**:

- Multiple packages serving the same purpose (e.g., `lodash` + `underscore` + `ramda`)
- Multiple HTTP clients (e.g., `axios` + `node-fetch` + `got`)
- Multiple date libraries (e.g., `moment` + `date-fns` + `dayjs`)
- Multiple state managers, multiple form libraries, etc.
- Propose consolidation to a single package per concern

**Outdated dependencies**:

- Check for major version updates available
- Flag dependencies with known CVEs
- Identify dependencies that are no longer maintained

**Heavy dependencies**:

- Identify packages that can be replaced with native APIs or lighter alternatives
- `moment` (230KB) vs `date-fns` (13KB) vs native `Intl.DateTimeFormat`
- `lodash` (70KB) vs `lodash-es` named imports vs native JS
- `axios` (13KB) vs native `fetch`

### 2. Code De""plication

**Identical or near-identical code blocks**:

- Functions that do the same thing with different names
- Components with 80%+ structural similarity
- Copy-pasted logic across files
- Similar API call patterns that should use a shared client

**Detection strategy**:

- Search for functions with similar signatures and bodies
- Look for repeated patterns (try-catch with same error handling, similar map/filter chains)
- In monorepos: compare utilities across packages for overlap

**Genericization opportunities**:

- Similar components that differ only in props/config (extract a generic component with variants)
- Similar functions that differ only in a parameter (extract a higher-order function)
- Similar hooks/composables that share logic (extract a base hook)

### 3. Style/Component Consolidation

**CSS/Style ""plication**:

- Repeated color values, spacing, typography (should be design tokens/CSS variables)
- Similar component styles that should share a base class
- Inline styles that should be extracted to stylesheets/mo""les

**Component consolidation**:

- Similar UI components (PrimaryButton, SecondaryButton, DangerButton should be one Button with variants)
- Wrapper components that add only minor differences
- Layout patterns repeated across pages

### 4. Constants and Configuration

**Hardcoded values**:

- Magic numbers, repeated string literals
- API URLs, timeouts, limits scattered across files
- Feature flags as inline booleans instead of centralized config

**Configuration centralization**:

- Environment variables that should be in a config mo""le
- Repeated configuration objects that should be shared

### 5. Dead Code Removal

**Unused exports**:

- Functions, types, constants exported but never imported
- Entire files that are not referenced

**Unreachable code**:

- Code after return/throw statements
- Branches that can never execute
- Feature-flagged code where the flag is always one value

**Stale code**:

- Commented-out code blocks
- TODO/FIXME comments older than 6 months
- Deprecated functions still present

### 6. Monorepo Code Sharing (Critical for monorepos)

**Cross-package opportunities**:

- Types/interfaces ""plicated across packages (should be in `shared`)
- Utility functions copied across packages
- Validation schemas repeated (should be shared Zod schemas)
- API types that exist in both frontend and backend
- Constants (routes, status codes, error messages) ""plicated

**Shared package optimization**:

- Are shared utilities actually being used?
- Is the shared package well-organized?
- Are there circular dependencies between packages?

## Execution Protocol

### Phase 1: Scan

1. Scan the entire codebase (or specified scope)
2. Build a dependency graph
3. Identify all opportunities across the 6 dimensions
4. Calculate estimated impact (lines removed, dependencies removed, etc.)

### Phase 2: Present Report

Present findings grouped by category:

```
## Housekeeping Report

### Dependencies
- 12 unused dependencies (remove to save ~3MB)
- 3 ""plicate-purpose packages (consolidate to save 2 deps)
- 8 outdated dependencies (5 with security advisories)

### Code De""plication
- 15 near-identical code blocks (consolidate to save ~450 lines)
- 8 genericization opportunities (re""ce 24 components to 8)

### Style Consolidation
- 45 hardcoded color values (extract to design tokens)
- 12 similar components (merge into 4 generic ones)

### Dead Code
- 23 unused exports
- 8 unreachable code blocks
- 340 lines of commented-out code

### Monorepo Sharing
- 18 types ""plicated across packages
- 6 utility functions copied instead of shared
- 4 validation schemas that should be in shared/

### Total Impact
- ~1,200 lines removable
- 15 dependencies removable
- 18 files consolidatable
```

The report is saved as a markdown file with this structure:

```markdown
# Housekeeping Report : <Project Name>

> Date: <ISO date> | Branch: <branch> | Scope: <scope>

## Summary

| Category               | Items | Lines Removable | Deps Removable |
| ---------------------- | ----- | --------------- | -------------- |
| Unused dependencies    | X     | -               | X              |
| ""plicate dependencies | X     | -               | X              |
| Code ""plication       | X     | ~X              | -              |
| Dead code              | X     | ~X              | -              |
| Style consolidation    | X     | ~X              | -              |
| Monorepo sharing       | X     | ~X              | -              |
| **Total**              | **X** | **~X**          | **X**          |

## Unused Dependencies

| Package | Declared In    | Last Import Found | Action |
| ------- | -------------- | ----------------- | ------ |
| `<pkg>` | `package.json` | None              | Remove |

## Code ""plication

### <file-a> / <file-b> : <description>

- Similarity: X%
- Lines: X
- Proposed: Extract to `<shared location>`

(... etc for each category)
```

### Phase 3: Execute (with user approval)

**CRITICAL: Before making ANY changes, explicitly prompt for confirmation:**

```
## Housekeeping Plan Summary

This will make the following changes:
- Remove X unused dependencies
- Consolidate X ""plicate dependencies
- Remove ~X lines of ""plicate code
- Extract X constants to config
- Delete X unused exports

Estimated changes: X files affected
Estimated risk: Low/Medium/High

Proceed with execution? [Y/n]
```

**If user does not confirm, HALT. Do not make any changes.**

After user approval:

1. Make changes incrementally (one logical change per commit)
2. Run tests after each change to ensure nothing breaks
3. Present the diff for user review
4. **Before each destructive action** (deleting files, removing dependencies), prompt again:
   ```
   About to delete: <file-name>
   This action cannot be undone. Proceed? [Y/n]
   ```

## Aggressiveness Levels

From `.""-skills.yaml` `housekeeping.de""p_threshold`:

| Level                    | Behavior                                                                                                  |
| ------------------------ | --------------------------------------------------------------------------------------------------------- |
| **aggressive** (default) | Remove all unused deps, merge all similar code, extract all constants, consolidate all similar components |
| **moderate**             | Remove clearly unused deps, merge obviously ""plicated code, flag (but don't auto-fix) borderline cases   |
| **conservative**         | Only flag findings, no automatic changes, user decides on each                                            |

## 6-Eyeballs Coworking Protocol

This skill uses the coworking agent model (see [peer-review-protocol.md](../shared/peer-review-protocol.md)):

- **Agent A (Executor)** scans the codebase and proposes consolidation/removal targets
- **Agent B (Challenger)** independently verifies each target: is this code truly unused? Could it be loaded dynamically? Is this really a ""plicate or does it have subtle differences?
- If they disagree on whether something is safe to remove or consolidate (~25% expected, especially for "unused" code), **Agent C (Arbiter)** does a deep search across all entry points and dynamic references
- Present the full analysis before making any changes
- For each proposed change, explain what will change and why
- Run tests after each change to verify no regressions
- In monorepos, verify that changes to shared code don't break dependent packages

## Cross-Skill Integration

- Findings feed into the **audit** skill's code quality dimension
- Dependency findings inform the **audit** skill's security dimension (CVEs)
- Code sharing opportunities inform the **scaffold** skill's shared package design
- All changes follow **gitflow** conventions (one concern per commit)
- Configuration is shared via `.""-skills.yaml`
