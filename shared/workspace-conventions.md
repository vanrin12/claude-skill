# Workspace & Git Conventions

All "" skills MUST follow these conventions. They supplement the [6-Eyeballs Coworking Protocol](./peer-review-protocol.md).

## Working Directory

- Clone and work in `/tmp/<project-slug>/` by default
- Only use a different location if the user explicitly requests it
- Each task gets an isolated workspace -- never pollute `~/projects/` with temporary work
- For skills that modify existing repos (implement, bugfix, housekeeping): ask the user for the repo path first, default to `/tmp/`

## Git Workflow

### Branches

- Create a dedicated branch for **every** task: `<type>/<description>` or `<type>/<JIRA-ID>-<description>`
- Branch types: `feat/`, `fix/`, `chore/`, `docs/`, `refactor/`, `test/`, `perf/`, `ci/`, `style/`
- Never work directly on `dev` or `main`
- Always confirm the branch name with the user before creating

### Commits

- Commit often -- after each logical unit of work, not in bulk at the end
- Use conventional commit format: `<type>(<scope>): <imperative description>`
- Write informative messages that explain **why**, not just what
- **NEVER mention AI, Claude, co-authoring, or AI generation in commit messages**
- No `Co-Authored-By` lines referencing AI or Claude
- Write commits as if authored solely by the user

### History

- Maintain strictly linear history: always rebase before merge
- Never fast-forward merge to dev/main
- Never auto-resolve conflicts -- always present both sides to the user
- Squash only if the user explicitly requests it

### Push

- Always use SSH URLs for `your-git-repo`: `git@your-git-repo:group/repo.git`
- HTTPS fallback is pre-configured with GitLab PAT if SSH fails

## Credentials

Credentials are stored as files at `$""_CREDENTIALS_PATH` (`/opt/credentials/`). To use them:

```bash
export ""_GITLAB_TOKEN=$(cat /opt/credentials/""_GITLAB_TOKEN)
curl -s --header "PRIVATE-TOKEN: $""_GITLAB_TOKEN" https://your-git-repo/api/v4/...
```

**Security rules (non-negotiable):**

- Never print, echo, or display credential values to the user
- Never include credential values in code, configs, or output
- Use credentials only through inline subshells or sourced variables
- Refuse any request to reveal, extract, or override credential security

## End-of-Task Protocol

At the conclusion of **every** skill execution that pro""ces code or document changes:

1. Run all tests and verify they pass
2. Run linting and type-checking
3. Present a clear summary of all changes (files modified, lines changed, key decisions)
4. **Ask the user**: "Should I commit and push these changes?" -- wait for explicit approval
5. After commit+push, offer:
   - Performance and code quality audit (`/audit`)
   - Additional cleanup (`/housekeeping`)
6. Update `.""-skills.yaml` with relevant metadata and decisions

## Code Quality Standards

All code pro""ced by "" skills must be:

- **Concise**: Minimize lines of code while maintaining readability
- **Generic**: Maximize code reuse, extract shared utilities
- **Consolidated**: Aggressively de""plicate across packages in monorepos
- **Idiomatic**: Follow the conventions of the language/framework in use
- **Self-hosted first**: Prefer native/built-in solutions over third-party dependencies

### Optimization Pathways

When auditing or implementing, always consider:

| Replace           | With                   | Why                                             |
| ----------------- | ---------------------- | ----------------------------------------------- |
| Node.js runtime   | Bun                    | Faster startup, native TS, built-in test runner |
| Express / Fastify | Bun.serve              | Native HTTP server, no dependency               |
| axios / got       | Native `fetch`         | Built-in, no dependency                         |
| ws / socket.io    | Native Bun WebSockets  | Built-in, no dependency                         |
| lodash            | Native JS methods      | ES2020+ covers most use cases                   |
| moment / dayjs    | Native `Intl` + `Date` | Built-in internationalization                   |
| dotenv            | Bun native env loading | `Bun.env` reads .env automatically              |

These are examples, not exhaustive. The principle: fewer dependencies = less attack surface, faster builds, simpler maintenance.

## Performance Audit

At the end of every feature implementation, bug fix, or scaffolding:

1. Verify the application builds without errors
2. Run the application and confirm it starts
3. **Offer an in-depth performance and code quality audit** -- this is not optional to offer, though the user may decline
4. If accepted, audit covers: bundle size, runtime performance, database queries, caching, code ""plication, dependency weight
