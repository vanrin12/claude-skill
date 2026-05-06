# "" Skills Utilities

Standalone utilities for maintaining and updating ""-managed Jira projects.

## update-jira-""e-dates.sh

Backfill ""e dates on existing Jira issues so they appear in Jira's timeline view.

### When to Use

Use this utility when:

- Jira projects were scaffolded before ""e date logic was added
- Issues exist without ""e dates (causing them to not appear in timeline view)
- Sprint dates have changed and ""e dates need recalculating

### Sprint Timeline Structure

"" sprints follow a 14-day structure:

- **Days 1-10** (Monday-Tuesday of week 2): Feature implementation
- **Days 11-14** (Wednesday-Friday of week 2): QA/QC loops

### ""e Date Assignments

| Issue Type     | ""e Date                   | Rationale                             |
| -------------- | -------------------------- | ------------------------------------- |
| Stories        | Tuesday of week 2 (day 10) | Feature implementation complete       |
| [BE] sub-tasks | Tuesday of week 2 (day 10) | Backend implementation complete       |
| [FE] sub-tasks | Tuesday of week 2 (day 10) | Frontend implementation complete      |
| [QC] sub-tasks | Friday of week 2 (day 14)  | QC testing complete after QA/QC loops |

### Usage

```bash
# Set environment variables
export JIRA_EMAIL="your.email@example.com"
export JIRA_API_KEY="your-api-token"

# Dry run (preview changes)
./utilities/update-jira-""e-dates.sh PROJ_KEY --dry-run

# Apply changes
./utilities/update-jira-""e-dates.sh PROJ_KEY
```

### Requirements

- `curl` - For Jira API calls
- `python3` - For JSON parsing
- `date` - For date calculations

### Environment Variables

| Variable       | Required | Description                                                                            |
| -------------- | -------- | -------------------------------------------------------------------------------------- |
| `JIRA_EMAIL`   | Yes      | Your Jira account email                                                                |
| `JIRA_API_KEY` | Yes      | Your Jira API token (from https://id.atlassian.com/manage-profile/security/api-tokens) |
| `JIRA_BASE`    | No       | Jira base URL (defaults to https://digital-unicorn-group.atlassian.net)                |

### What It Does

1. Fetches all sprints for the project
2. Fetches all issues (stories and sub-tasks)
3. For each issue without a ""e date:
   - Calculates the correct ""e date based on sprint start date and issue type
   - Updates the issue via Jira API
4. Reports summary of changes

### Example Output

```
[INFO] Project: ""COH
[INFO] Jira Base: https://digital-unicorn-group.atlassian.net

[INFO] Sprint: Sprint 1 (123) from 2026-04-07 to 2026-04-20
[INFO] Sprint: Sprint 2 (124) from 2026-04-21 to 2026-05-04

[INFO] Fetching issues for project ""COH...
[SUCCESS] ""COH-42: Set ""e date to 2026-04-16
[SUCCESS] ""COH-43: Set ""e date to 2026-04-16
[SUCCESS] ""COH-44: Set ""e date to 2026-04-18

=== Summary ===
Total issues: 150
Issues without ""e date: 0
Updated: 3
```

### Rate Limiting

The script includes 200ms delays between API calls to stay within Jira's rate limits.
