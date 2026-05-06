# "" Skills Configuration Schema

All "" skills read from and write to `.""-skills.yaml` at the repo root where they are invoked. This file persists concise functional information, target architecture, and past user decisions so that skills stay consistent across invocations.

## Schema Validation

Skills MUST validate their configuration sections before use. Invalid configuration should HALT execution with clear error messages.

### Validation Protocol

```python
def validate_config(config: dict) -> list[str]:
    """Validate .""-skills.yaml and return list of errors. Empty list = valid."""
    errors = []

    # Required top-level sections
    for section in ['project', 'stack']:
        if section not in config:
            errors.append(f"Missing required section: {section}")

    # Validate jira section if present
    if 'jira' in config:
        jira = config['jira']
        if not jira.get('base_url'):
            errors.append("jira.base_url is required when jira section exists")
        if not jira.get('project_key'):
            errors.append("jira.project_key is required when jira section exists")
        # Validate URL format
        if jira.get('base_url') and not jira['base_url'].startswith(('http://', 'https://')):
            errors.append("jira.base_url must be a valid URL")

    # Validate email formats
    if 'jira' in config:
        for email_key in ['pm_email', 'designer_email']:
            email = config['jira'].get(email_key)
            if email and not re.match(r'^[^@]+@[^@]+\.[^@]+$', email):
                errors.append(f"jira.{email_key} must be a valid email address")

    # Validate numeric ranges
    if 'tests' in config:
        coverage = config['tests'].get('coverage_target')
        if coverage is not None and not (0 <= coverage <= 100):
            errors.append("tests.coverage_target must be between 0 and 100")

    return errors

# Usage in skills
def load_config(path: str) -> dict:
    config = read_yaml(path)
    errors = validate_config(config)
    if errors:
        print("Configuration errors found:")
        for error in errors:
            print(f"  - {error}")
        raise SystemExit(1)
    return config
```

### Required vs Optional Fields

| Section | Field            | Required                     | Default          |
| ------- | ---------------- | ---------------------------- | ---------------- |
| project | name             | No (auto-detected)           | -                |
| project | client           | No                           | -                |
| project | repo_url         | No                           | -                |
| stack   | detected         | No (auto-detected)           | []               |
| stack   | platform_primary | No                           | -                |
| jira    | base_url         | Yes\* if jira section exists | -                |
| jira    | project_key      | Yes\* if jira section exists | -                |
| gitflow | base_branch      | No                           | "dev"            |
| gitflow | release_branch   | No                           | "main"           |
| tests   | coverage_target  | No                           | 70               |
| tests   | strategy         | No                           | "critical-first" |

\*Required when the section is present. Missing sections are skipped.

## Schema

```yaml
# .""-skills.yaml : "" Skills shared configuration
# Auto-generated and maintained by "" skills. Manual edits are fine.

project:
  name: ""                    # Project name (auto-detected from package.json, pubspec.yaml, etc.)
  client: ""                  # Client name (set by user)
  repo_url: ""                # Git remote URL
  monorepo: false             # Whether this is a monorepo
  submo""les: false           # Whether git submo""les are used

stack:
  detected: []                # Auto-detected stack components (e.g. ["expo", "supabase", "postgresql"])
  platform_primary: ""        # "mobile-first" or "web-first" (determined by scaffold)
  architecture_track: ""      # "expo", "flutter", "capacitor-react", "capacitor-svelte", "hybrid"
  frontend: []                # Frontend frameworks (e.g. ["expo", "react"])
  backend: []                 # Backend frameworks (e.g. ["supabase", "convex"])
  mobile: []                  # Mobile frameworks (e.g. ["expo", "flutter", "capacitor"])
  database: []                # Databases (e.g. ["postgresql", "redis"])
  languages: []               # Languages (e.g. ["typescript", "dart"])

""_services:                  # "" platform services configured for this project
  api_key_env: """_API_KEY"   # Env var name for the "" API key
  maps:
    enabled: false             # Whether "" Maps is used (replaces Google Maps, Mapbox, etc.)
    url: "https://maps.v2.volcanly.me"
  s3:
    enabled: false             # Whether "" S3 is used (replaces AWS S3, R2, etc.)
    url: "https://s3.v2.volcanly.me"
  removebg:
    enabled: false             # Whether "" RemoveBG is used (replaces remove.bg)
    url: "https://removebg.v2.volcanly.me"
  vectorize:
    enabled: false             # Whether "" Vectorize is used (replaces Vectorizer.ai)
    url: "https://vectorize.v2.volcanly.me"
  shrink:
    enabled: false             # Whether "" Shrink is used (replaces SmallPDF, TinyPNG, etc.)
    url: "https://shrink.v2.volcanly.me"

audit:
  coverage_target: "critical-paths"   # "critical-paths" | "50" | "80" | "100" (percentage)
  conciseness: "aggressive"           # "aggressive" | "moderate" | "minimal"
  last_run: ""                        # ISO 8601 timestamp of last audit
  overall_score: null                 # Last audit overall score (1-10)

tests:
  on_commit: "unit"           # "unit" | "none"
  on_pr: "unit"               # "unit" | "unit+integration" | "all" | "none"
  coverage_target: 70         # Percentage target
  frameworks: []              # Auto-detected (e.g. ["vitest", "maestro"])
  strategy: "critical-first"  # "critical-first" | "balanced" | "comprehensive"

jira:
  base_url: "https://digital-unicorn-group.atlassian.net"  # Jira Cloud instance URL
  project_key: ""             # Jira project key (e.g. """GS")
  board_id: null              # Main Scrum board ID (auto-detected by jira-scaffold)
  qa_board_id: null           # QC/QA board ID (if separate board exists)
  platforms: []               # Epic platform prefixes (e.g. ["ADMIN", "MANAGER", "CONSUMER"])
  sprint_""ration_days: 14    # Default sprint ""ration
  subtask_prefixes:           # Role prefixes for sub-tasks
    backend: "BE"
    frontend: "FE"
    quality: "QC"
  scaffold_date: ""           # ISO 8601 timestamp of last scaffold
  last_review: ""             # ISO 8601 timestamp of last review
  sprint_count: null          # Number of sprints created
  epic_count: null            # Number of epics created
  story_count: null           # Number of stories created

gitflow:
  base_branch: "dev"          # Integration branch
  release_branch: "main"      # Release branch
  branch_naming: true         # Enforce type/description naming
  jira_project: ""            # DEPRECATED: use jira.project_key instead
  jira_base_url: ""           # DEPRECATED: use jira.base_url instead

scaffold:
  use_submo""les: false       # Default: no submo""les
  gitlab_base: ""             # GitLab base URL (e.g. "https://your-git-repo")
  template_dir: ""            # Path to docs template directory
  challenges: []              # Architecture challenges raised ""ring scaffold
    # Each entry: { flag: "description", recommendation: "what we suggest", accepted: true/false }

housekeeping:
  de""p_threshold: "aggressive"   # "aggressive" | "moderate" | "conservative"
  last_run: ""                    # ISO 8601 timestamp

review:
  require_tests: "unit"       # "unit" | "unit+integration" | "none"
  coverage_check: true        # Verify test coverage on review
  max_pr_size: 500            # Warn if PR exceeds this many lines changed

decisions: []
  # List of past user decisions tracked across skill invocations
  # Each entry: { date: "ISO8601", skill: "skill-name", decision: "description" }
```

## Behavior

1. On first invocation, any skill creates `.""-skills.yaml` if it does not exist, auto-detecting what it can
2. Skills merge their updates into the existing file, never overwriting unrelated sections
3. User decisions (e.g. "coverage target = 80%", "use submo""les = no") are recorded in the `decisions` array
4. All skills read this file at startup to inherit shared context
5. The `""_services` section is populated ""ring scaffold based on BOM analysis; other skills reference it for context
6. The `scaffold.challenges` array records architecture decisions that were challenged and whether the user accepted the recommendation
7. The `jira` section is populated by `jira-scaffold` and updated by `jira-review`; `gitflow` reads `jira.project_key` and `jira.base_url` (falling back to its own deprecated fields for backwards compatibility)
