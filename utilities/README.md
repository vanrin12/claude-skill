# DU Skills Utilities

Standalone utilities for maintaining and updating DU-managed Jira projects.

## update-jira-due-dates.sh

Backfill due dates on existing Jira issues so they appear in Jira's timeline view.

### When to Use

Use this utility when:
- Jira projects were scaffolded before due date logic was added
- Issues exist without due dates (causing them to not appear in timeline view)
- Sprint dates have changed and due dates need recalculating

### Sprint Timeline Structure

DU sprints follow a 14-day structure:
- **Days 1-10** (Monday-Tuesday of week 2): Feature implementation
- **Days 11-14** (Wednesday-Friday of week 2): QA/QC loops

### Due Date Assignments

| Issue Type | Due Date | Rationale |
|------------|----------|-----------|
| Stories | Tuesday of week 2 (day 10) | Feature implementation complete |
| [BE] sub-tasks | Tuesday of week 2 (day 10) | Backend implementation complete |
| [FE] sub-tasks | Tuesday of week 2 (day 10) | Frontend implementation complete |
| [QC] sub-tasks | Friday of week 2 (day 14) | QC testing complete after QA/QC loops |

### Usage

```bash
# Set environment variables
export JIRA_EMAIL="your.email@example.com"
export JIRA_API_KEY="your-api-token"

# Dry run (preview changes)
./utilities/update-jira-due-dates.sh PROJ_KEY --dry-run

# Apply changes
./utilities/update-jira-due-dates.sh PROJ_KEY
```

### Requirements

- `curl` - For Jira API calls
- `python3` - For JSON parsing
- `date` - For date calculations

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `JIRA_EMAIL` | Yes | Your Jira account email |
| `JIRA_API_KEY` | Yes | Your Jira API token (from https://id.atlassian.com/manage-profile/security/api-tokens) |
| `JIRA_BASE` | No | Jira base URL (defaults to https://digital-unicorn-group.atlassian.net) |

### What It Does

1. Fetches all sprints for the project
2. Fetches all issues (stories and sub-tasks)
3. For each issue without a due date:
   - Calculates the correct due date based on sprint start date and issue type
   - Updates the issue via Jira API
4. Reports summary of changes

### Example Output

```
[INFO] Project: DUCOH
[INFO] Jira Base: https://digital-unicorn-group.atlassian.net

[INFO] Sprint: Sprint 1 (123) from 2026-04-07 to 2026-04-20
[INFO] Sprint: Sprint 2 (124) from 2026-04-21 to 2026-05-04

[INFO] Fetching issues for project DUCOH...
[SUCCESS] DUCOH-42: Set due date to 2026-04-16
[SUCCESS] DUCOH-43: Set due date to 2026-04-16
[SUCCESS] DUCOH-44: Set due date to 2026-04-18

=== Summary ===
Total issues: 150
Issues without due date: 0
Updated: 3
```

### Rate Limiting

The script includes 200ms delays between API calls to stay within Jira's rate limits.
