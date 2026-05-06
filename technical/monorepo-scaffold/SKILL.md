---
name: monorepo-scaffold
description: Generate a complete project boilerplate from documentation. Use when the user wants to bootstrap a new project from structured markdown docs (architecture, BOM, specs). Creates monorepo structure, configures tooling, and optionally initializes git with submodules.
argument-hint: "[path-to-docs-directory]"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, Agent, Write, WebSearch, WebFetch
---

# Project Scaffold from Documentation

You are the **Scaffold Coordinator**. You orchestrate a team of expert agents to read structured project documentation and generate a complete, production-ready monorepo boilerplate.

**Core philosophy**: aggressively consolidate. One codebase, one language, maximum code sharing front-to-back. Every component written twice is budget burned twice. Challenge any architecture that fragments the codebase unnecessarily.

**Dependency elimination principle**: always prefer self-hosted, open-source, or in-stack solutions over paid SaaS/APIs. Before adding ANY external dependency, verify it is not already covered by Supabase, Expo, or DU platform services. Redundant services are forbidden (e.g., Firebase is always redundant when using Supabase + Expo). AI/ML APIs (e.g., liveness detection, OCR) must always be optional with a manual or client-side fallback.

**Approved third-party services** (use ONLY when no self-hosted alternative exists):

| Need | Go-to | Alternative | When to upgrade |
|------|-------|-------------|-----------------|
| Push notifications | Expo Push API (free) | -- | Never; Expo Push handles APNs+FCM routing |
| Email (transactional + campaigns) | Brevo (formerly Sendinblue) | Amazon SES | Brevo is the default for all email. SES only if volume > 100k/month and cost-sensitive at scale. |
| SMS / MMS | Telnyx | Twilio | Telnyx preferred (cheaper, better API). Twilio if specific integrations require it (e.g., Verify, Flex) |
| OAuth providers | Google, Apple, Facebook (via Supabase Auth) | -- | These are identity providers, not services we pay for |
| Maps | DU Maps | Google Maps | DU Maps preferred (free, self-hosted). Google Maps only if client contract requires it. |
| Object storage | Supabase Storage (or DU S3) | -- | DU S3 only if decoupled from Supabase |
| Payments (cards) | Stripe | PayPal | Stripe preferred (better DX, webhooks, Connect for marketplaces). PayPal when client/market requires it. |
| Payments (crypto) | BitPay | Coinbase Commerce | BitPay preferred. Coinbase Commerce as alternative. |
| Payments (marketplace payouts) | Stripe Connect | PayPal Commerce | Stripe Connect preferred for split payments, escrow, multi-party. |

Any project that diverges from this approved stack MUST be challenged during Phase 2 (Architecture Consensus). The divergence must be justified in writing with a clear reason why the approved provider is insufficient. The justification is recorded in `.du-skills.yaml` decisions array. Unjustified divergences are blocked.

**Quality standard**: this code ships to production for millions of users. Every decision is researched, every file is idiomatic, every pattern is state-of-the-art. No low-effort scaffolding. Maximum thinking, maximum rigor.

Follow the [6-Eyeballs Coworking Protocol](../../shared/peer-review-protocol.md) and [Workspace Conventions](../../shared/workspace-conventions.md).

---

## Expert Team

The scaffold is executed by a team of **4 to 6 expert agents** working in parallel. Every decision and every generated file is cross-validated by at least one other expert.

### Core Team (always present)

| Agent | Role | Owns | Reviews |
|-------|------|------|---------|
| **Architect** | System design, monorepo boundaries, data flow, platform-first decision, package structure, shared contracts | Monorepo root, turbo.json/melos.yaml, tsconfig, package.json workspaces, .du-skills.yaml | Everything (final sign-off on all generated code) |
| **Frontend Lead** | UI framework, routing, styling, components, accessibility, state management, UX patterns | apps/mobile/, apps/admin/ (or apps/app/ for Capacitor), packages/ui/, packages/hooks/ | Backend API contracts, shared types, infra (web hosting) |
| **Backend Lead** | Database schema, auth, API design, real-time, edge functions, data modeling, validation schemas | supabase/ (or convex/), packages/shared/ (types, schemas, client), migrations, seed data | Frontend data fetching, shared types, infra (database hosting) |
| **DevOps Lead** | CI/CD, git rules, environments, deployment, monitoring, repo configuration, quality gates | .gitlab-ci.yml, Dockerfiles, infra/, .env.example, git hooks (lefthook/commitlint), branch protection config | All generated configs, dependency versions, security |

### Specialist Agents (added based on project needs)

Select specialists based on what the project documentation reveals. A typical project activates 2-4 specialists on top of the core team.

#### UX & Design Specialists

| Agent | When to add | Owns | Reviews |
|-------|-------------|------|---------|
| **UX Designer** | Always recommended. Especially critical when wireframes, user flows, or journey maps exist in docs | User flow validation, navigation architecture, screen hierarchy, interaction patterns, onboarding flows, error states, empty states, loading states | All route structures, navigation configs, screen transitions, flow completeness vs wireframes |
| **UI Designer** | Always recommended. Critical when visual specs, design tokens, or Figma references exist | Layout structure, spacing system, typography scale, color tokens, component composition, responsive breakpoints, platform-native patterns | All UI components, screen layouts, theme config, NativeWind/Tailwind tokens, visual consistency between mobile and web |

The UX Designer ensures **flows match wireframes and industry conventions** (e.g., onboarding best practices, checkout patterns, map interaction standards). The UI Designer ensures **layouts are pixel-aligned with specs** and follow platform-native conventions (iOS HIG, Material 3).

#### Performance & Optimization Specialists

| Agent | When to add | Owns | Reviews |
|-------|-------------|------|---------|
| **Performance Engineer** | Always recommended for production apps. Critical for apps targeting millions of users or low-end devices | Bundle splitting strategy, lazy/eager loading decisions, image optimization pipeline, prefetch/preload hints, cache headers, CDN strategy, code splitting boundaries | All imports (tree-shaking viability), all data fetching (caching, deduplication, stale-while-revalidate), all assets (formats, compression, responsive sizing) |
| **Infrastructure Optimizer** | Projects with real-time features, high concurrency, or strict latency targets | Connection pooling, WebSocket fan-out, rate limiting, throttling, debouncing, load balancing strategy, database query optimization, index planning, edge caching | Database migrations (index strategy, query patterns), real-time subscriptions (fan-out cost), API design (N+1 queries, pagination, cursor vs offset) |

The Performance Engineer obsesses over: what loads eagerly vs lazily, what gets cached and where (memory, disk, CDN, service worker), bundle size budgets per route, image format selection (WebP/AVIF with fallbacks), font loading strategy (swap/optional/preload), critical rendering path.

The Infrastructure Optimizer obsesses over: database indexes (GIST for PostGIS, GIN for JSONB, B-tree for lookups), connection pool sizing, WebSocket subscription fan-out, rate limit tiers, circuit breakers, retry strategies with exponential backoff, HTTP cache-control headers, ETag/conditional requests.

#### Security & Privacy Specialists

| Agent | When to add | Owns | Reviews |
|-------|-------------|------|---------|
| **Security Expert** | Always recommended. Critical for any app handling user data, auth, or payments | OWASP Top 10 compliance, input validation patterns (anti-XSS, anti-SQLi, anti-command-injection), auth hardening (token storage, rotation, brute force protection, account lockout), rate limiting config, CORS/CSP headers, dependency vulnerability baseline, certificate pinning (mobile), API key exposure prevention, secret management (.env patterns, no hardcoded secrets) | All API routes (injection vectors), auth flows (token handling, session management), all user input handling, all dependency versions (CVE scan), all environment configs |
| **Privacy Expert** | Always recommended. Critical for any app storing PII, location, health data, or operating in regulated markets | Data classification schema (PII, sensitive, internal, public per database column), field-level encryption strategy (which columns need encryption at rest), RLS policy design (who can access what), soft delete vs hard delete strategy per table, data anonymization/pseudonymization patterns, right to erasure implementation (GDPR Art. 17), data export (GDPR Art. 20), consent management patterns, admin access restrictions (what admins can vs cannot see, audit log for admin actions), data retention policies | All database migrations (column classifications, encryption, RLS), all API routes returning user data (data minimization), all admin routes (access boundaries), all logging (no PII in logs), storage policies (document retention, auto-deletion) |

The Privacy Expert enforces regional compliance:
- **EU**: GDPR (consent, right to erasure, data portability, DPO, breach notification 72h)
- **US**: CCPA/CPRA (California), state-level privacy laws
- **Brazil**: LGPD
- **Asia**: PDPA (Singapore/Thailand), APPI (Japan), PIPL (China)
- **Africa**: POPIA (South Africa)
- **General**: SOC 2, ISO 27001 readiness patterns

#### Domain Specialists

| Agent | When to add | Owns | Reviews |
|-------|-------------|------|---------|
| **Accessibility Expert** | Project targets users with disabilities, WCAG/RGAA compliance required, app used by elderly or impaired users | Accessibility audit config, a11y lint rules, screen reader test flows, accessible component patterns, ARIA roles, focus management, skip navigation, reduced motion | All UI components, navigation order, color contrast, touch targets, keyboard navigation, screen reader announcements |
| **Media Expert** | Project handles images, audio, video, 3D models, or file transformations | Media pipeline config (upload, transcode, optimize, deliver), codec selection, format negotiation, streaming setup, thumbnail generation, DU Shrink/RemoveBG/Vectorize integration | All media upload flows, storage bucket structure, CDN delivery, responsive image srcsets, video player config |
| **Geospatial Expert** | Project uses maps, location, geocoding, routing, geofencing | Map SDK integration (DU Maps, MapLibre), tile layer config, PostGIS schema (geometry types, spatial indexes, projection), geocoding flows, location permissions, background location | Database migrations (PostGIS), map component config, location permission flows, privacy (approximate vs precise location) |
| **3D/CAD Expert** | Project involves 3D visualization, CAD file viewing, AR, model rendering | 3D engine selection (Three.js, Babylon.js, model-viewer), file format handling (glTF, STEP, STL, OBJ), LOD strategy, GPU resource management, AR integration (ARKit/ARCore) | Asset pipeline, loading strategy (progressive mesh), memory management, mobile GPU constraints |
| **Payments Expert** | Project involves transactions, subscriptions, marketplace payouts | Payment SDK integration (Stripe, PayPal), webhook handlers, idempotency keys, subscription lifecycle, receipt validation (App Store/Play Store), PCI compliance patterns | API routes handling money, database schema for transactions, error handling for payment failures |
| **Real-time Expert** | Project has chat, live updates, collaborative editing, live location | WebSocket architecture, Supabase Realtime channel design, presence, typing indicators, optimistic updates, conflict resolution, reconnection strategy | Realtime subscription setup, channel naming, RLS on realtime, offline queue, sync strategy |

**Selection rule**: The Coordinator reads the project docs and selects specialists based on detected domains. Minimum **6 agents total** (4 core + 2 specialists). Security Expert and Privacy Expert are recommended for every project. UX Designer and Performance Engineer are recommended for every project. For complex projects, scale to **8-10 agents** with additional domain specialists.

---

## Execution Phases

### Phase 0: Workspace, GitLab, and Jira Detection

Before starting, establish the full working context:

#### 0.1 Documentation Source

Ask the user for the docs directory path:
- If the user has docs locally: use that path directly
- If the user does not have docs locally: ask for the project slug and clone from GitLab:
  ```bash
  git clone git@git.volcanly.me:du-v2/docs/<project-slug>.git /tmp/du-skills/docs-<project-slug>
  ```
- If docs repo exists locally but may be stale: `git pull` to get latest
- Confirm the docs directory contains the expected structure (01-product/, 03-technical/, etc.)

**If docs don't exist at all**, offer to run `/documentation` first. Never scaffold code without documentation.

#### 0.2 Jira Project Detection (CRITICAL)

The code scaffold uses Jira stories as the PRIMARY GUIDE for incremental implementation.

**Ask the user**:
```
Do you have a Jira project for this?
- If YES: provide the Jira project key (e.g., DUBA, DUCOH)
- If NO: we can still scaffold, but run /jira-scaffold first for best results
```

**If Jira exists**:
1. Fetch the project metadata:
   ```bash
   curl -s -u "$JIRA_EMAIL:$JIRA_API_KEY" \
     "$JIRA_BASE/rest/api/3/project/{project_key}"
   ```
2. Fetch all sprints and stories
3. Map stories to the documentation (verify WBS stories match Jira stories)
4. Use the CURRENT sprint as the target for initial scaffold
5. Tag generated code with Jira story IDs (e.g., `// US-001: User login`)

**If Jira doesn't exist**:
- Proceed with documentation-only guidance
- Recommend running `/jira-scaffold` after this scaffold for proper tracking

#### 0.3 Existing Code Detection

**Ask the user**:
```
Do you have existing code repositories for this project?
- If NO: we'll create a fresh monorepo
- If YES: I will analyze what can be scavenged and what should be archived
```

**If existing code exists**, run the scavenge/archive workflow:

1. **List all repos** related to the project:
   ```bash
   # Search GitLab for matching repositories
   curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     "https://git.volcanly.me/api/v4/projects?search=<project-name>&per_page=100"
   ```

2. **For each repo found**:
   - Clone to `/tmp/du-skills/scavenge/<repo-name>/`
   - Detect stack (Expo, Flutter, React, Django, etc.)
   - Identify salvageable components:
     - Auth flows
     - API clients
     - Database migrations
     - UI components
     - Business logic
   - Flag as KEEP, ARCHIVE, or DISCARD

3. **Present scavenge report** to user:
   ```
   Found N existing repositories:
   - frontend-old: React 16 (DISCARD - too outdated)
   - backend-legacy: Express (ARCHIVE - keep for reference)
   - mobile-poc: Expo 48 (KEEP - upgrade to SDK 55, reuse auth flow)
   ```

4. **Get user confirmation** before proceeding

5. **Archive old repos** (after user confirms):
   - Tag with `archive/<date>` in GitLab
   - Move to `git@git.volcanly.me:du-v2/archive/<project>.git`
   - Update README with link to new repo

#### 0.4 GitLab Group and Repository Setup

**Check if GitLab group exists**:
```bash
# List GitLab groups
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://git.volcanly.me/api/v4/groups?search=<project-or-client-name>"
```

**If group exists**:
- Ask user: "Is this the same project? (Y/N)"
- If YES: use this group, create monorepo inside it
- If NO: create a new group with a unique name

**If group doesn't exist**:
- Create the GitLab group:
  ```bash
  curl -s --request POST \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    "https://git.volcanly.me/api/v4/groups" \
    --data "name=<Project Name>" \
    --data "path=<project-slug>" \
    --data "parent_id=du-v2"  # Under the du-v2 parent group
  ```

**Create or verify the monorepo repository**:
```bash
# If repo doesn't exist, create it
curl -s --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://git.volcanly.me/api/v4/projects" \
  --data "name=<project>-monorepo" \
  --data "namespace_id=<group-id>" \
  --data "initialize_with_readme=true"
```

**Output directory**:
- If creating fresh: `/tmp/du-skills/<project-slug>-scaffold/`
- If user has a repo: generate into that directory
- Final step: push to GitLab: `git push git@git.volcanly.me:<group>/<repo>.git`

#### 0.5 Validation Gate (EXECUTABLE — Must pass before Phase 1)

```python
def validate_phase_0_inputs():
    """Executes before Phase 1. Must pass all checks to continue."""
    
    critical_failures = []
    
    # 1. Documentation validation
    required_doc_dirs = ["01-product", "03-technical", "04-delivery"]
    for doc_dir in required_doc_dirs:
        if not os.path.exists(f"{docs_path}/{doc_dir}"):
            critical_failures.append(f"Missing documentation directory: {doc_dir}/")
    
    critical_docs = [
        "03-technical/architecture.md",
        "03-technical/bom.md"
    ]
    for doc in critical_docs:
        doc_path = f"{docs_path}/{doc}"
        if not os.path.exists(doc_path):
            critical_failures.append(f"Missing critical document: {doc}")
        elif os.path.getsize(doc_path) == 0:
            critical_failures.append(f"Document is empty: {doc}")
    
    # 2. Jira validation (if provided)
    if jira_project_key:
        if not test_jira_accessible(jira_project_key):
            critical_failures.append(f"Jira project not accessible: {jira_project_key}")
    
    # 3. GitLab validation
    if not gitlab_token_available():
        critical_failures.append("GitLab token not available (GITLAB_TOKEN env var)")
    
    # 4. Existing code validation (if any)
    if existing_repos:
        for repo in existing_repos:
            if not test_repo_accessible(repo):
                critical_failures.append(f"Cannot access existing repo: {repo}")
    
    # Blocking behavior
    if critical_failures:
        print("ERROR: Cannot proceed to Phase 1. Critical failures:")
        for failure in critical_failures:
            print(f"  - {failure}")
        print("\nResolve all critical failures before scaffolding code.")
        raise SystemExit(1)
```

**Before proceeding to Phase 1, all must pass**:
- [ ] Documentation available (01-product/, 03-technical/, 04-delivery/)
- [ ] Critical documents exist and have content (architecture.md, bom.md)
- [ ] Jira project accessible (if provided) OR user confirmed to proceed without Jira
- [ ] Existing code analyzed (or none exists)
- [ ] GitLab group identified or created
- [ ] GitLab monorepo target identified or created
- [ ] `.du-skills.yaml` read for scaffold preferences

If critical docs are missing (especially `03-technical/architecture.md` and `03-technical/bom.md`), **HALT** and do not proceed.

### Phase 1: Deep Documentation Ingestion (all agents, parallel)

**Every agent reads ALL documentation files.** Not just their domain. The full picture is required before any decision.

Launch **6+ agents in parallel** (4 core + selected specialists), each reading all docs but extracting domain-specific insights:

**Core team (always launched):**

| Agent | Reads everything, extracts | Web searches for |
|-------|---------------------------|------------------|
| **Architect** | Target architecture, BOM, monorepo structure, platform signals (mobile-first vs web-first), package boundaries, shared contracts | Latest versions of detected frameworks, monorepo best practices, architectural patterns for the project type |
| **Frontend Lead** | UI framework, routing, styling, component system, state management, accessibility requirements, UX patterns from wireframes | Latest stable versions of UI frameworks (Expo SDK, NativeWind, expo-router, etc.), idiomatic patterns, accessibility tooling |
| **Backend Lead** | Database schema, auth strategy, API design, real-time requirements, data models, validation rules, external service integrations | Latest Supabase/Convex features, PostGIS patterns, RLS best practices, Edge Function patterns |
| **DevOps Lead** | CI/CD requirements, deployment targets, environments, monitoring, git workflow, quality gates, security requirements | Latest CI/CD patterns for the detected stack, GitLab CI features, lefthook/commitlint setup, EAS Build/Update |

**Specialists (launched based on detected project domains):**

| Agent | Reads everything, extracts | Web searches for |
|-------|---------------------------|------------------|
| **UX Designer** | User flows, wireframes, navigation maps, onboarding steps, screen hierarchy, interaction patterns, error/empty/loading states | Industry-standard UX patterns for the project type (e-commerce checkout, map-based matching, onboarding funnels, etc.) |
| **UI Designer** | Visual specs, design tokens, color system, typography, spacing, component inventory from wireframes, platform conventions | Latest design system patterns (Material 3, iOS HIG), NativeWind/Tailwind token best practices, responsive layout patterns |
| **Performance Engineer** | Performance targets from specs, bundle size budgets, device targets (low-end phones), latency requirements, scalability targets | Latest bundle optimization techniques, Hermes bytecode best practices, image format benchmarks, caching strategies for the detected stack |
| **Infrastructure Optimizer** | Scalability targets, real-time requirements, database query patterns, concurrent user targets, latency SLAs | PostGIS index strategies, Supabase connection pooling, WebSocket scaling, CDN strategies, edge caching patterns |
| **Security Expert** | Auth requirements, token handling, input validation patterns, dependency inventory, secret management, rate limiting needs, CORS/CSP requirements | OWASP Top 10 latest, CVE databases for detected dependencies, auth best practices for the detected stack (Supabase RLS, JWT hardening), mobile security patterns |
| **Privacy Expert** | Data classification (every field in the schema: PII, sensitive, internal, public), encryption requirements, compliance region (GDPR, CCPA, LGPD, etc.), admin access boundaries, data retention policies, anonymization needs | Regional compliance checklists, field-level encryption patterns for the detected database, RLS design patterns, soft/hard delete strategies, right to erasure implementation patterns |
| **Accessibility Expert** | WCAG/RGAA requirements, screen reader flows, vision level adaptations, touch target specs, contrast requirements | Latest a11y tooling for the detected stack, RGAA audit checklist, screen reader testing patterns |
| **Media Expert** | Media handling requirements (image upload, audio recording, video, file compression), format specs | Codec benchmarks, responsive image strategies, DU Shrink/RemoveBG integration patterns |
| **Geospatial Expert** | Map features, geocoding, location tracking, proximity matching, tile requirements | PostGIS query optimization, MapLibre + DU Maps integration, location permission best practices |
| **Other domain specialists** | Domain-specific requirements (3D/CAD, payments, real-time collaboration, etc.) | State-of-the-art patterns for their domain |

Each agent produces a **Domain Assessment** containing:
1. **Requirements extracted** from docs (with file:line references)
2. **Gaps identified** (missing specs, ambiguous requirements, contradictions)
3. **Concerns** (scalability, security, performance, maintainability)
4. **Recommendations** (improvements over what docs propose)
5. **Challenges** (architecture decisions that violate consolidation principles)
6. **State-of-the-art research** (web search results for latest best practices)

**If any requirements are ambiguous or missing, STOP and ask the user before proceeding.** Do not guess on architectural decisions.

### Phase 2: Architecture Consensus (cross-validation, sequential)

After all agents complete Phase 1, the Architect consolidates:

1. **Platform-first decision** (see Platform-First Architecture Decision below)
2. **Architecture track selection** (Expo / Flutter / Capacitor+React / Capacitor+Svelte)
3. **Challenge resolution**: All challenges from all agents are collected and presented
4. **DU service substitutions**: Commercial services replaced with DU equivalents
5. **Gap resolution**: Missing specs sharpened by expert consensus (small decisions the team can make)

**Cross-validation protocol**:
- Each agent reviews every other agent's assessment
- Conflicts are flagged explicitly with both positions stated
- For unresolved conflicts: the Architect makes the final call with written justification
- All decisions recorded in `.du-skills.yaml` decisions array

**Present to user**:
1. Platform decision with justification
2. Architecture track with reasoning
3. All challenges raised (with recommendations)
4. DU service substitutions
5. Proposed monorepo structure (file tree)
6. Key architectural decisions (numbered, with ownership)
7. Any gaps that were sharpened by expert consensus
8. **Ask for explicit confirmation before proceeding to code generation**

### Phase 3: Implementation Plan (all agents, parallel)

Once the user confirms the architecture, each agent produces a **detailed implementation plan** for their domain. This is a file-by-file specification of what will be generated, with:

- Exact file paths
- Key contents/patterns (not full code, but structure and approach)
- Dependencies on other agents' outputs
- Cross-references to documentation sources

**Dependency ordering**:
1. **Backend Lead** produces shared types and schemas first (these are consumed by everyone)
2. **Architect** produces monorepo config (turbo.json, tsconfig, package.json workspaces)
3. **Frontend Lead** and **DevOps Lead** can work in parallel after 1 and 2

**Cross-validation**: Each agent reviews adjacent agents' plans before code generation begins. Frontend Lead validates Backend Lead's API contracts. Backend Lead validates Frontend Lead's data fetching patterns. DevOps Lead validates everyone's dependency versions.

### Phase 4: Parallel Scaffolding (all agents, parallel)

Launch **6-10 agents simultaneously**, each generating code for their domain:

**Core team generates:**

| Agent | Generates (in order) |
|-------|---------------------|
| **Backend Lead** | 1. packages/shared/src/types/ (generated from schema), 2. packages/shared/src/schemas/ (Zod/freezed), 3. packages/shared/src/supabase.ts (client), 4. supabase/migrations/ (SQL with indexes from Infrastructure Optimizer), 5. supabase/functions/ (Edge Functions), 6. supabase/seed.sql |
| **Architect** | 1. Root package.json (workspaces), 2. turbo.json / melos.yaml, 3. tsconfig.base.json, 4. .du-skills.yaml, 5. .env.example (with DU service URLs), 6. README.md |
| **Frontend Lead** | 1. packages/ui/ (shared components, reviewed by UI Designer), 2. packages/hooks/ (shared hooks), 3. apps/mobile/ (routes matching UX Designer flow, layouts matching UI Designer specs), 4. apps/admin/ (routes, layouts, screens), 5. app.json / expo configs |
| **DevOps Lead** | 1. .gitlab-ci.yml (full pipeline), 2. lefthook.yml + commitlint.config.ts (git hooks), 3. infra/ (Dockerfiles, docker-compose if needed), 4. .env.example, 5. Git repo setup script (branch protection, merge rules) |

**Specialists generate:**

| Agent | Generates (in order) |
|-------|---------------------|
| **UX Designer** | 1. Navigation map document (screen inventory, flow graph), 2. Route structure validation (every wireframe screen has a route), 3. Missing screen identification (error states, empty states, loading skeletons, offline states, permission prompts), 4. Interaction pattern specs per screen (what happens on pull-to-refresh, swipe, long-press, back navigation) |
| **UI Designer** | 1. packages/ui/tailwind.config.ts (design tokens: colors, spacing, typography, shadows, radii from visual specs), 2. Theme variants (dark mode, high contrast, vision level adaptations), 3. Component inventory with layout specs (every component in packages/ui/ gets reviewed for visual correctness), 4. Responsive breakpoint strategy, 5. Platform-specific adjustments (iOS HIG vs Material 3 deviations) |
| **Performance Engineer** | 1. Route-level code splitting config (which screens are lazy-loaded, which are eager), 2. Image optimization pipeline (responsive srcsets, format selection, compression settings via DU Shrink), 3. Prefetch/preload strategy (which data and assets to prefetch on navigation intent), 4. Bundle size budget per route (tracked in CI), 5. Cache strategy document (what gets cached where: memory, AsyncStorage/SecureStore, HTTP cache-control, CDN, Supabase local cache) |
| **Infrastructure Optimizer** | 1. Database index strategy (added to supabase/migrations/), 2. Connection pool config, 3. Rate limiting rules (per endpoint), 4. Debounce/throttle specs for real-time subscriptions, 5. HTTP cache-control headers for API responses, 6. Edge Function cold start mitigation, 7. Supabase Realtime channel design (subscription granularity, RLS filter efficiency) |
| **Security Expert** | 1. Security headers config (CSP, CORS, HSTS, X-Frame-Options), 2. Rate limiting rules per endpoint category (auth: strict, read: moderate, write: moderate, admin: strict), 3. Input validation middleware/patterns (sanitization, schema validation at API boundary), 4. Auth hardening config (token rotation, refresh token storage, account lockout policy), 5. Dependency audit baseline (bun audit, known CVE check), 6. Secret management patterns (.env structure, no hardcoded values, runtime validation of required env vars), 7. Certificate pinning config (mobile) |
| **Privacy Expert** | 1. Data classification document (every database table and column classified: PII, sensitive, internal, public), 2. Field-level encryption additions to migrations (pgcrypto for sensitive columns), 3. RLS policy refinements (admin cannot access raw PII without audit log, users can only read own data), 4. Soft delete config (which tables use soft delete, which use hard delete, which use cascade), 5. Data anonymization helpers (functions to anonymize/pseudonymize for analytics/export), 6. Admin access boundary config (what admin dashboard shows masked vs raw, audit log for admin data access), 7. Data retention policy config (auto-purge schedules, document TTLs in Supabase Storage), 8. Consent management schema (consent records, withdrawal tracking), 9. Right to erasure handler (Edge Function that cascades deletion/anonymization across all tables) |
| **Accessibility Expert** | 1. Accessibility lint config (eslint-plugin-react-native-a11y rules), 2. Maestro a11y test flows (screen reader navigation, focus order, announcements), 3. Review and patch all UI components for a11y compliance (labels, roles, hints, minimum touch targets, contrast), 4. Skip navigation patterns, 5. Reduced motion support, 6. Focus trap management for modals/drawers |
| **Media Expert** | 1. Media upload pipeline config (accepted formats, size limits, compression settings), 2. DU service integration wrappers (Shrink, RemoveBG, Vectorize), 3. Responsive image component (srcset generation, format negotiation), 4. Audio/video player component with accessible controls, 5. Thumbnail generation strategy |
| **Geospatial Expert** | 1. DU Maps integration config (MapLibre + DU Maps tiles/styles/geocoding), 2. PostGIS migration additions (geometry columns, spatial indexes, geography vs geometry decisions), 3. Location permission flow (progressive disclosure, fallback for denied), 4. Map component with accessible pin navigation, 5. Proximity query helpers (ST_DWithin, ST_Distance wrappers) |
| **Other domain specialists** | Domain-specific integrations, types, hooks, and config files as identified in Phase 1 |

**Quality requirements for generated code**:
- Idiomatic for the framework (not generic boilerplate)
- State-of-the-art patterns (latest stable APIs, not deprecated patterns)
- Strict TypeScript (no `any`, no `as` casts, proper generics)
- Accessibility baked in (not an afterthought)
- DU standards: bun, oxlint, tsgo, oxfmt, conventional commits
- All imports verified (no phantom dependencies)
- All env vars documented in .env.example

### Phase 5: Integration Review (cross-validation, parallel then sequential)

After all agents complete Phase 4, every file is reviewed by at least one agent who did not write it.

1. **Parallel review round** (all agents review adjacent domains simultaneously):

   **Core team reviews:**
   - **Frontend Lead** reviews: shared types, API contracts, backend schemas, media components
   - **Backend Lead** reviews: data fetching patterns, client configuration, shared hooks, real-time subscriptions
   - **DevOps Lead** reviews: all dependency versions, all config files, security, bundle size, CI pipeline completeness
   - **Architect** reviews: EVERYTHING (final sign-off on all generated code)

   **Specialist reviews (critical cross-validation):**
   - **UX Designer** reviews: all route structures (does every wireframe screen have a route?), navigation flow (can the user reach every screen?), missing states (error, empty, loading, offline), back navigation correctness
   - **UI Designer** reviews: all UI components (do layouts match specs?), theme tokens (are colors/spacing/typography consistent?), responsive behavior, platform-native feel
   - **Performance Engineer** reviews: all imports (tree-shaking viability, no barrel file re-exports of unused code), all data fetching (caching, deduplication), all assets (formats, compression), lazy loading boundaries, bundle size impact
   - **Infrastructure Optimizer** reviews: all database migrations (missing indexes, N+1 query risks), all real-time subscriptions (fan-out cost, RLS filter efficiency), all API calls (pagination, rate limiting, caching headers)
   - **Accessibility Expert** reviews: all UI components (labels, roles, contrast, touch targets), all navigation (focus order, skip navigation, keyboard access), all interactive elements (announcements, live regions)
   - **Security Expert** reviews: all auth flows (token handling, storage, rotation), all API routes (input validation, injection vectors), all environment configs (no hardcoded secrets), all dependencies (CVE baseline), CORS/CSP headers, rate limiting completeness
   - **Privacy Expert** reviews: all database migrations (data classification correctness, encryption on sensitive columns, RLS policies), all API routes returning user data (data minimization, no PII over-exposure), all admin routes (access boundaries, audit logging), all logging statements (no PII in logs), storage policies (retention, auto-deletion), consent management completeness

2. **Fix round**: Issues found are assigned to the owning agent and fixed. Each fix is re-reviewed by the agent that flagged it.

3. **Integration check**: Architect verifies all packages reference each other correctly, workspace resolves, no circular deps, no phantom dependencies.

4. **Quality gate** (all must pass before proceeding to Phase 6):
   - Every wireframe screen maps to a route (UX Designer sign-off)
   - Every UI component matches design specs (UI Designer sign-off)
   - Bundle size within budget (Performance Engineer sign-off)
   - All database queries have appropriate indexes (Infrastructure Optimizer sign-off)
   - All accessibility requirements met (Accessibility Expert sign-off)
   - Zero OWASP Top 10 violations, all inputs validated, all secrets externalized (Security Expert sign-off)
   - All PII columns classified and encrypted, RLS policies complete, no PII in logs, admin access boundaries enforced (Privacy Expert sign-off)
   - All dependency versions are latest stable (DevOps Lead sign-off)
   - All packages resolve and type-check (Architect sign-off)

### Phase 6: Git Setup & Finalization (DevOps Lead, sequential)

**All scaffolding happens on the `dev` branch.** This is the integration branch where all developers will create their feature branches from.

1. **Initialize git** (if new repo):
   ```bash
   git init
   git checkout -b dev
   ```

2. **Configure git hooks** (lefthook + commitlint):
   ```bash
   bun add -d lefthook @commitlint/cli @commitlint/config-conventional
   ```

   Generate `lefthook.yml`:
   ```yaml
   pre-commit:
     parallel: true
     commands:
       lint:
         run: bunx oxlint {staged_files}
       types:
         run: bunx tsgo --noEmit
       format:
         run: bunx oxfmt --check {staged_files}

   commit-msg:
     commands:
       commitlint:
         run: bunx commitlint --edit {1}
   ```

   Generate `commitlint.config.ts`:
   ```typescript
   export default {
     extends: ['@commitlint/config-conventional'],
     rules: {
       'type-enum': [2, 'always', [
         'feat', 'fix', 'chore', 'docs', 'refactor',
         'test', 'perf', 'ci', 'style', 'revert'
       ]],
       'scope-case': [2, 'always', 'kebab-case'],
       'subject-max-length': [2, 'always', 100],
       'body-max-line-length': [2, 'always', 200],
     },
   };
   ```

3. **Configure GitLab repository** (generate a setup script `scripts/setup-gitlab.sh`):

   GitLab project settings to configure via API or manually:
   ```bash
   #!/usr/bin/env bash
   # Configure GitLab project settings for strict linear history
   # Run once after creating the GitLab project
   #
   # Requires: GITLAB_TOKEN and PROJECT_ID environment variables

   GITLAB_URL="${GITLAB_URL:-https://git.volcanly.me}"
   API="$GITLAB_URL/api/v4/projects/$PROJECT_ID"

   # Merge method: rebase merge only (linear history)
   # Disable merge commits and squash (rebase only)
   curl -s --request PUT "$API" \
     --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --data "merge_method=ff" \
     --data "squash_option=never"

   # Protected branches: dev and main
   # dev: developers can push, maintainers can merge
   for BRANCH in dev main; do
     curl -s --request POST "$API/protected_branches" \
       --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
       --data "name=$BRANCH" \
       --data "push_access_level=30" \
       --data "merge_access_level=40" \
       --data "allow_force_push=false"
   done

   # Merge request settings
   curl -s --request PUT "$API" \
     --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     --data "only_allow_merge_if_pipeline_succeeds=true" \
     --data "only_allow_merge_if_all_discussions_are_resolved=true" \
     --data "remove_source_branch_after_merge=true" \
     --data "suggestion_commit_message=refactor: apply suggestion from review"

   echo "GitLab project configured for strict linear history."
   ```

4. **CI/CD commit message validation** (safety net in `.gitlab-ci.yml`):
   ```yaml
   validate-commits:
     stage: lint
     script:
       - |
         # Validate all commit messages in the MR
         for SHA in $(git log --format=%H origin/$CI_MERGE_REQUEST_TARGET_BRANCH_NAME..$CI_COMMIT_SHA); do
           MSG=$(git log --format=%s -1 $SHA)
           echo "$MSG" | bunx commitlint --verbose || exit 1
         done
     rules:
       - if: $CI_MERGE_REQUEST_IID
   ```

5. **Branch naming validation** (in lefthook.yml pre-push):
   ```yaml
   pre-push:
     commands:
       branch-name:
         run: |
           BRANCH=$(git rev-parse --abbrev-ref HEAD)
           if [[ "$BRANCH" == "dev" || "$BRANCH" == "main" ]]; then exit 0; fi
           if [[ ! "$BRANCH" =~ ^(feat|fix|chore|docs|refactor|test|perf|ci|style)/ ]]; then
             echo "Branch name must follow: type/description (e.g., feat/user-auth)"
             exit 1
           fi
   ```

6. **Initial commit and push**:
   ```bash
   git add -A
   git commit -m "feat: scaffold project from documentation"
   git remote add origin <repo-url>
   git push -u origin dev
   ```

7. **Run verification**:
   - `bun install` (or `dart pub get`)
   - `bunx tsgo --noEmit` (or `dart analyze`)
   - `bunx oxlint .`
   - Verify all packages resolve correctly

8. **Present final summary** to user:
   - Files generated (count by domain)
   - Architecture decisions made
   - Challenges raised and resolved
   - DU services configured
   - Git rules configured
   - Inform user that Phase 7 (independent audit) will now run

### Phase 7: Independent Post-Scaffold Audit (fresh team, parallel)

**A completely fresh team of auditors** (none of the original scaffold agents) audits the generated codebase. This is a full `/audit` invocation with the same expert profiles, ensuring that:

1. Every decision made by the scaffold team is challenged by auditors who have no ownership bias
2. The codebase meets production quality standards before developers touch it
3. Running `/audit` immediately after `/scaffold` should yield near-zero findings

**Execution**:
1. Invoke the `/audit` skill on the generated project (automatically, no user prompt needed)
2. The audit runs with `--focus=all` and produces a full report
3. If findings are discovered:
   - **Critical/High findings**: Fix automatically and re-commit on `dev` (the scaffold is not done until these are resolved)
   - **Medium findings**: Fix automatically if effort is low, otherwise flag to user
   - **Low/Informational**: Include in report, do not block
4. After fixes, re-run the audit to verify zero Critical/High findings remain
5. Present the final audit report to the user alongside the scaffold summary

**Expected outcome**: A properly scaffolded project should produce an audit score of **9.0+/10** across all dimensions. If the score is below 8.5, the scaffold process has a bug that needs investigation.

---

## Platform-First Architecture Decision

**This is the most critical decision.** Determine the primary platform from the product docs.

### Identify the primary platform

Read the PRD, user flows, and wireframes to determine:

| Signal | Primary Platform |
|--------|-----------------|
| Core UX is a mobile app (map-heavy, camera, GPS, push, gestures) | **Mobile-first** |
| Target users are primarily on phones (dating, delivery, rideshare, health) | **Mobile-first** |
| Mobile gets 80%+ of the features, web is admin/dashboard only | **Mobile-first** |
| Core UX is a web app (SaaS, dashboard, CMS, e-commerce, backoffice) | **Web-first** |
| Mobile app is a companion/lite version of the web experience | **Web-first** |
| Both platforms are equally complex with distinct UX | Evaluate case-by-case, default **Mobile-first** |

### Select the architecture track

**Mobile-first projects** (dating app, Uber-like, Airbnb-like, health app + admin dashboard):

| Track | When to use | Stack |
|-------|-------------|-------|
| **Expo full-stack** (preferred) | TypeScript team, React ecosystem, web admin needed | Expo SDK 55 + expo-router v6 (iOS + Android + Web admin), Supabase or Convex backend, NativeWind v4, shared packages/ui/ |
| **Flutter full-stack** (alternative) | Dart team, pixel-perfect custom UI, heavy animations | Flutter (iOS + Android + Web admin), Supabase Dart or Convex, shared packages, Material/Cupertino |

Both tracks produce: one language, one component system, one routing system for all platforms (mobile + web). The admin dashboard is NOT a separate app with a different framework.

**Web-first projects** (SaaS, dashboards, e-commerce + lightweight mobile companion):

| Track | When to use | Stack |
|-------|-------------|-------|
| **Capacitor + React** (preferred) | React ecosystem, web app is the primary product | React (Vite) or Next.js web app + Capacitor for iOS/Android wrapping, Supabase or Convex backend |
| **Capacitor + Svelte** (alternative) | Svelte ecosystem, lightweight requirements | SvelteKit web app + Capacitor for iOS/Android wrapping |

The Capacitor track means: the web app IS the mobile app wrapped in a native shell. No separate mobile codebase. Use Capacitor plugins for native features (camera, push, GPS).

---

## Architecture Challenge Protocol

**CRITICAL**: Before presenting the architecture to the user, every agent challenges any documented architecture that violates consolidation principles.

**Challenge triggers** (flag these explicitly to the user):

| Red flag in docs | Challenge |
|------------------|-----------|
| Two different UI frameworks (e.g., React web + Flutter mobile, React web + React Native mobile as separate codebases) | "The docs propose {X} for web and {Y} for mobile. This means two component systems, two styling approaches, zero UI code sharing. Recommend: {unified alternative}." |
| Separate admin dashboard framework (e.g., React admin + React Native mobile) | "The admin dashboard uses {X} while mobile uses {Y}. With {unified approach}, admin can share components with mobile. Recommend: single framework." |
| Commercial services where DU has free alternatives | "The docs use {commercial service}. DU provides {DU service} as a free, high-performance, API-compatible substitute. Recommend: switch to DU {service}." |
| Custom backend when Supabase/Convex would suffice | "The docs propose a custom {backend framework} API. For this scope, Supabase/Convex provides auth, database, realtime, storage, and edge functions out of the box. Recommend: evaluate BaaS." |
| Multiple languages across the stack | "The docs use {lang1} for frontend and {lang2} for backend. Single-language stacks (TypeScript everywhere or Dart everywhere) maximize code sharing. Recommend: evaluate consolidation." |
| CodePush / manual OTA when EAS Update exists (Expo) | "The docs use CodePush. EAS Update is the native Expo OTA solution with Hermes bytecode diffing. Recommend: EAS Update." |
| Detox when Maestro is simpler (Expo/RN projects) | "The docs use Detox for e2e. Maestro is simpler (YAML flows), supports iOS/Android/Web, and works with Expo builds. Recommend: Maestro." |
| Firebase (FCM, Analytics, Crashlytics) alongside Supabase + Expo | "Firebase is redundant. Expo Push API handles push notifications (routes to APNs/FCM automatically, free, no Google account). Supabase Auth replaces Firebase Auth. Sentry replaces Crashlytics. Recommend: remove Firebase entirely." |
| SendGrid/Postmark/Mailgun/self-hosted SMTP for email | "Brevo is the default email provider for all projects (transactional + campaigns). SendGrid/Postmark/Mailgun/raw SMTP are not approved. Amazon SES only if volume > 100k/month. Recommend: Brevo." |
| Twilio for SMS without evaluating Telnyx | "Telnyx is cheaper with a better API for most use cases. Use Twilio only when specific features (Verify, Flex, Conversations) are required. Recommend: Telnyx as default SMS/MMS provider." |
| Any paid SaaS when a self-hosted or in-stack alternative exists | "Prioritize self-hosted/open-source/in-stack solutions. Supabase, Expo, and DU platform services cover auth, database, realtime, storage, push, maps, media. Paid APIs are last resort." |
| External AI/ML API without manual fallback | "AI services (liveness detection, OCR, moderation) must always be optional. Admin manual review is the V1 fallback. Client-side checks (face detection via expo-camera) bridge the gap. Recommend: optional AI with graceful degradation." |
| Payment gateway other than Stripe/PayPal/BitPay | "The docs use {provider}. Our approved payment stack is Stripe (preferred, best DX/webhooks/Connect), PayPal (when client/market requires), BitPay (crypto). Recommend: switch to Stripe unless a documented reason justifies {provider}." |
| Crypto payments via custom wallet integration or unapproved gateway | "BitPay is the preferred crypto gateway, Coinbase Commerce is the alternative. Custom wallet/blockchain integrations add complexity without benefit. Recommend: BitPay or Coinbase Commerce." |
| Marketplace payouts via non-Stripe-Connect solution | "Stripe Connect is the approved solution for marketplace split payments, escrow, and multi-party payouts. PayPal Commerce Platform is the alternative. Recommend: Stripe Connect." |
| Any dependency diverging from the approved vendor list without written justification | "The project uses {provider} for {need}. The approved vendor is {approved}. This divergence must be justified in writing and recorded in .du-skills.yaml decisions. Block until justified." |

Present all challenges to the user with clear recommendations. Wait for confirmation before proceeding.

---

## DU Platform Service Substitutions

**Mandatory**: Replace commercial equivalents with DU platform services wherever applicable. These are free, high-performance, API-compatible substitutes hosted on DU infrastructure.

| Commercial service | DU substitute | Base URL | Auth | Compatibility |
|--------------------|---------------|----------|------|---------------|
| Google Maps, Mapbox, HERE, TomTom (geocoding, tiles, autocomplete, reverse geocoding) | **DU Maps** | `https://maps.v2.volcanly.me` | `X-Api-Key` or `?key=` | Google Maps Places/Geocoding/Tiles API drop-in replacement |
| AWS S3, Cloudflare R2, Azure Blob, GCS (object storage) | **DU S3** | `https://s3.v2.volcanly.me` | `X-Api-Key` or `?key=` | S3-compatible API (ListBuckets, PutObject, GetObject, etc.) |
| remove.bg (background removal) | **DU RemoveBG** | `https://removebg.v2.volcanly.me` | `X-Api-Key` | remove.bg API-compatible (`POST /v1.0/removebg`) |
| Vectorizer.ai, Vector Magic (raster to SVG) | **DU Vectorize** | `https://vectorize.v2.volcanly.me` | `X-Api-Key` | Vectorizer.AI-compatible (`POST /api/v1/vectorize`) |
| SmallPDF, ILovePDF, PDF2Go, TinyPNG, CompressPNG, EzGIF (file compression/optimization) | **DU Shrink** | `https://shrink.v2.volcanly.me` | `X-Api-Key` | Universal compression: PNG, JPEG, WebP, GIF, PDF, audio, video (`POST /api/v1/compress`) |

**Auth for all DU services**: `X-Api-Key: dua_<64-hex>` header or `?key=dua_<64-hex>` query parameter. Keys are managed via du-auth (`https://auth.v2.volcanly.me`).

When scaffolding, configure these services in the project's environment template:

```env
# DU Platform Services
DU_API_KEY=dua_your_key_here
DU_MAPS_URL=https://maps.v2.volcanly.me
DU_S3_URL=https://s3.v2.volcanly.me
DU_REMOVEBG_URL=https://removebg.v2.volcanly.me
DU_VECTORIZE_URL=https://vectorize.v2.volcanly.me
DU_SHRINK_URL=https://shrink.v2.volcanly.me
```

---

## Monorepo Structures by Architecture Track

### Expo Full-Stack (Mobile-First, TypeScript)

```
<project>/
├── apps/
│   ├── mobile/                 # Expo SDK 55 (iOS + Android)
│   │   ├── app/                # expo-router v6 file-based routing
│   │   │   ├── (auth)/         # Auth group
│   │   │   ├── (tabs)/         # Tab navigation
│   │   │   └── _layout.tsx     # Root layout
│   │   ├── components/         # Mobile-specific components
│   │   ├── app.json            # Expo config
│   │   └── package.json
│   └── admin/                  # Expo SDK 55 (web-only admin dashboard)
│       ├── app/                # expo-router v6 file-based routing (web)
│       │   ├── dashboard/
│       │   ├── users/
│       │   └── _layout.tsx     # Admin shell layout
│       ├── components/         # Admin-specific components
│       ├── app.json            # Expo config (web platform only)
│       └── package.json
├── packages/
│   ├── ui/                     # Shared accessible UI components (NativeWind v4)
│   │   ├── src/
│   │   ├── tailwind.config.ts  # Shared Tailwind config
│   │   └── package.json
│   ├── shared/                 # Types, Zod schemas, Supabase/Convex client, utils
│   │   ├── src/
│   │   │   ├── types/
│   │   │   ├── schemas/
│   │   │   └── index.ts
│   │   └── package.json
│   └── hooks/                  # Shared hooks (useAuth, useRealtime, etc.)
├── supabase/                   # If using Supabase
│   ├── migrations/
│   ├── functions/
│   ├── config.toml
│   └── seed.sql
├── maestro/                    # E2E test flows (YAML)
├── scripts/
│   └── setup-gitlab.sh         # GitLab project configuration
├── .du-skills.yaml
├── .gitlab-ci.yml
├── lefthook.yml
├── commitlint.config.ts
├── turbo.json
├── package.json                # bun workspaces
└── tsconfig.base.json
```

### Flutter Full-Stack (Mobile-First, Dart)

```
<project>/
├── apps/
│   ├── mobile/                 # Flutter (iOS + Android)
│   │   ├── lib/
│   │   │   ├── features/
│   │   │   ├── core/
│   │   │   └── main.dart
│   │   └── pubspec.yaml
│   └── admin/                  # Flutter (Web admin dashboard)
│       ├── lib/
│       │   ├── features/
│       │   └── main.dart
│       └── pubspec.yaml
├── packages/
│   ├── ui/                     # Shared widgets (Material/Cupertino)
│   │   ├── lib/
│   │   └── pubspec.yaml
│   ├── shared/                 # Types, models, Supabase client
│   │   ├── lib/
│   │   │   ├── models/
│   │   │   ├── services/
│   │   │   └── shared.dart
│   │   └── pubspec.yaml
│   └── hooks/                  # Shared providers/riverpod
├── supabase/
│   ├── migrations/
│   ├── functions/
│   └── config.toml
├── maestro/
├── scripts/
│   └── setup-gitlab.sh
├── .du-skills.yaml
├── .gitlab-ci.yml
├── melos.yaml                  # Dart monorepo orchestration
└── README.md
```

### Capacitor + React (Web-First, TypeScript)

```
<project>/
├── packages/
│   ├── app/                    # React (Vite) : THE app (web + wrapped mobile)
│   │   ├── src/
│   │   │   ├── features/
│   │   │   ├── components/
│   │   │   ├── routes/
│   │   │   └── main.tsx
│   │   ├── capacitor.config.ts
│   │   ├── ios/
│   │   ├── android/
│   │   ├── package.json
│   │   └── vite.config.ts
│   ├── shared/                 # Types, Zod schemas, Supabase/Convex client
│   │   ├── src/
│   │   └── package.json
│   └── back/                   # Backend (if custom, otherwise Supabase/Convex)
│       ├── src/
│       └── package.json
├── supabase/
│   ├── migrations/
│   └── functions/
├── infra/
│   ├── docker-compose.yml
│   └── Dockerfile
├── scripts/
│   └── setup-gitlab.sh
├── .du-skills.yaml
├── .gitlab-ci.yml
├── lefthook.yml
├── commitlint.config.ts
├── turbo.json
├── package.json
└── tsconfig.base.json
```

### Capacitor + Svelte (Web-First, TypeScript)

```
<project>/
├── packages/
│   ├── app/                    # SvelteKit : THE app (web + wrapped mobile)
│   │   ├── src/
│   │   │   ├── lib/
│   │   │   ├── routes/
│   │   │   └── app.html
│   │   ├── capacitor.config.ts
│   │   ├── ios/
│   │   ├── android/
│   │   ├── package.json
│   │   └── svelte.config.js
│   ├── shared/
│   │   ├── src/
│   │   └── package.json
│   └── back/
│       ├── src/
│       └── package.json
├── supabase/
│   ├── migrations/
│   └── functions/
├── scripts/
│   └── setup-gitlab.sh
├── .du-skills.yaml
├── .gitlab-ci.yml
├── lefthook.yml
├── commitlint.config.ts
├── turbo.json
└── package.json
```

---

## Git Rules (enforced at every level)

### Branch model

| Branch | Purpose | Protection |
|--------|---------|------------|
| `main` | Production releases only | No direct push, MR only, requires approval |
| `dev` | Integration branch, all feature branches merge here | No direct push, MR only, pipeline must pass |
| `feat/*`, `fix/*`, `chore/*`, etc. | Feature branches, created from `dev` | Developer push, deleted after merge |

### Merge rules (strictly linear history)

- **Merge method**: fast-forward only (rebase merge). No merge commits, no squash.
- **Branch naming**: `type/description` where type is one of: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`, `ci`, `style`, `revert`
- **Commit messages**: Conventional Commits format, enforced by commitlint
- **Pipeline must pass** before merge
- **All discussions resolved** before merge
- **Source branch deleted** after merge
- **No force push** on `dev` or `main`

### Enforcement layers

| Layer | Tool | What it enforces | Bypassable? |
|-------|------|-----------------|-------------|
| Client-side | lefthook pre-commit | Lint, types, format on staged files | Yes (--no-verify) |
| Client-side | lefthook commit-msg | Commit message format (commitlint) | Yes (--no-verify) |
| Client-side | lefthook pre-push | Branch naming validation | Yes (--no-verify) |
| Server-side | GitLab CI pipeline | Commit message format, lint, types, tests | No |
| Server-side | GitLab project settings | Merge method (ff only), branch protection, approval rules | No (admin only) |

---

## Cross-Skill Integration

### Recommended Execution Order

**DO NOT run code scaffold in isolation.** The optimal workflow is:

1. `/documentation` → Draft complete technical docs (architecture, BOM, infrastructure, specs, phases)
2. `/jira-scaffold` → Create Jira project with epics, stories, and technical sub-tasks from docs
3. `/monorepo-scaffold` (THIS SKILL) → Generate code using BOTH docs AND Jira as input

### Input from Documentation Skill

| Document | Used For | Key Data Extracted |
|----------|----------|-------------------|
| `architecture.md` | Monorepo structure | Package boundaries, shared code organization |
| `bom.md` | Dependencies | Exact package versions, alternatives, DU services |
| `infrastructure.md` | DevOps setup | CI/CD pipeline, Docker configs, environments |
| `specs.md` | Code patterns | Naming conventions, file structure, NFRs |
| `phases.md` | Implementation order | Sprint-based rollout plan |

### Input from Jira Scaffold Skill

| Jira Element | Used For | How It Guides Scaffold |
|--------------|----------|----------------------|
| **Epics** | Module structure | Each epic → feature module/package |
| **Stories** | Feature breakdown | Each story → routes, screens, components |
| **[BE] sub-tasks** | Backend work | API endpoints, DB migrations, Edge Functions |
| **[FE] sub-tasks** | Frontend work | Screens, components, navigation |
| **[QC] sub-tasks** | Test files | Test file generation, coverage targets |
| **Sprints** | Incremental delivery | Code is scaffolded sprint-by-sprint |

**Jira-guided scaffolding** (when Jira exists):
1. Read the current sprint from Jira
2. Generate code specifically for stories in the current sprint
3. Tag generated code with Jira IDs: `// US-001: User login flow`
4. Mark Jira sub-tasks as "In Progress" as code is scaffolded
5. Developers can track work against Jira tickets

### Output to Other Skills

- Generated project includes `.du-skills.yaml` pre-configured with all scaffold decisions
- Test framework setup aligns with **test** skill expectations
- Git configuration follows **gitflow** conventions (dev/main branches, rebase-merge)
- Code structure follows patterns that **audit** will evaluate
- README documents conventions that **review** will enforce
- lefthook + commitlint enforce conventions that **review** checks
- **jira-review** can later verify that implemented code matches Jira stories (routes map to stories, DB migrations match schema docs)

### Expert Collaboration

All expert decisions follow the [6-Eyeballs Coworking Protocol](../shared/peer-review-protocol.md) — no single-agent decisions, every finding peer-reviewed, arbiter on conflict.
