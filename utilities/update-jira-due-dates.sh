#!/usr/bin/env bash
#
# update-jira-due-dates.sh
#
# Utility to backfill due dates on existing Jira issues.
# This ensures issues appear in Jira's timeline view.
#
# Usage: ./update-jira-due-dates.sh <PROJECT_KEY>
#
# Environment variables required:
#   JIRA_EMAIL - Your Jira account email
#   JIRA_API_KEY - Your Jira API token
#
# Sprint timeline (14 days):
#   Days 1-10 (Mon-Tue week 2): Feature implementation
#   Days 11-14 (Wed-Fri week 2): QA/QC loops
#
# Due date assignments:
#   Stories and [BE]/[FE] sub-tasks: Tuesday of week 2 (day 10)
#   [QC] sub-tasks: Friday of week 2 (day 14)
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Jira configuration
JIRA_BASE="${JIRA_BASE:-https://digital-unicorn-group.atlassian.net}"

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate environment
validate_env() {
    if [[ -z "${JIRA_EMAIL:-}" ]]; then
        log_error "JIRA_EMAIL environment variable not set"
        exit 1
    fi

    if [[ -z "${JIRA_API_KEY:-}" ]]; then
        log_error "JIRA_API_KEY environment variable not set"
        exit 1
    fi
}

# Parse ISO date and add days
add_days() {
    local date="$1"
    local days="$2"

    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        date -j -v "+${days}d" -f "%Y-%m-%d" "$date" "+%Y-%m-%d"
    else
        # Linux
        date -d "$date +$days days" "+%Y-%m-%d"
    fi
}

# Get sprint information
get_sprints() {
    local project_key="$1"

    log_info "Fetching sprints for project $project_key..."

    # First get the board ID
    local board_id
    board_id=$(curl -s -u "$JIRA_EMAIL:$JIRA_API_KEY" \
        "$JIRA_BASE/rest/agile/1.0/board?projectKeyOrId=$project_key" | \
        python3 -c "import json,sys; data=json.load(sys.stdin); print(data['values'][0]['id'] if data.get('values') else '')")

    if [[ -z "$board_id" ]]; then
        log_error "No board found for project $project_key"
        exit 1
    fi

    log_info "Board ID: $board_id"

    # Get all sprints
    curl -s -u "$JIRA_EMAIL:$JIRA_API_KEY" \
        "$JIRA_BASE/rest/agile/1.0/board/$board_id/sprint?state=future,active,closed" | \
        python3 -c "
import json, sys
data = json.load(sys.stdin)
for sprint in data.get('values', []):
    start = sprint.get('startDate', '')[:10] if sprint.get('startDate') else ''
    end = sprint.get('endDate', '')[:10] if sprint.get('endDate') else ''
    print(f\"{sprint['id']}|{sprint['name']}|{start}|{end}\")
"
}

# Calculate due date based on sprint start date and issue type
calculate_due_date() {
    local sprint_start="$1"
    local issue_type="$2"
    local subtask_prefix=""

    # Extract sub-task prefix if present
    if [[ "$issue_type" == "Sub-task" && $# -eq 3 ]]; then
        subtask_prefix="$3"
    fi

    if [[ -z "$sprint_start" ]]; then
        echo ""
        return
    fi

    # Day 10 = Tuesday of week 2 (implementation deadline)
    # Day 14 = Friday of week 2 (QC deadline)
    if [[ "$subtask_prefix" == "[QC]" ]]; then
        # QC sub-tasks due Friday (day 14)
        add_days "$sprint_start" 13
    elif [[ -n "$subtask_prefix" ]]; then
        # [BE]/[FE] sub-tasks due Tuesday (day 10)
        add_days "$sprint_start" 9
    else
        # Stories due Tuesday (day 10)
        add_days "$sprint_start" 9
    fi
}

# Get sub-task prefix from summary
get_subtask_prefix() {
    local summary="$1"

    if [[ "$summary" =~ \[BE\] ]]; then
        echo "[BE]"
    elif [[ "$summary" =~ \[FE\] ]]; then
        echo "[FE]"
    elif [[ "$summary" =~ \[QC\] ]]; then
        echo "[QC]"
    else
        echo ""
    fi
}

# Update issue due date
update_due_date() {
    local issue_key="$1"
    local due_date="$2"
    local dry_run="${3:-false}"

    local due_date_json=""
    if [[ -n "$due_date" ]]; then
        due_date_json="\"duedate\": \"$due_date\","
    fi

    if [[ "$dry_run" == "true" ]]; then
        echo "  Would update $issue_key: due_date=$due_date"
        return 0
    fi

    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" -u "$JIRA_EMAIL:$JIRA_API_KEY" \
        -X PUT "$JIRA_BASE/rest/api/3/issue/$issue_key" \
        -H "Content-Type: application/json" \
        -d "{\"fields\": {$due_date_json \"customfield_10004\": null}}")

    if [[ "$response" == "204" ]] || [[ "$response" == "200" ]]; then
        return 0
    else
        log_error "Failed to update $issue_key (HTTP $response)"
        return 1
    fi
}

# Main execution
main() {
    local project_key="${1:-}"
    local dry_run="${2:-false}"

    if [[ -z "$project_key" ]]; then
        log_error "Usage: $0 <PROJECT_KEY> [--dry-run]"
        exit 1
    fi

    if [[ "$project_key" == "--dry-run" ]]; then
        log_error "Please specify project key first"
        exit 1
    fi

    if [[ "$2" == "--dry-run" ]]; then
        dry_run=true
        log_warning "DRY RUN MODE - No changes will be made"
    fi

    validate_env

    log_info "Project: $project_key"
    log_info "Jira Base: $JIRA_BASE"
    echo ""

    # Get all sprints
    local sprints
    sprints=$(get_sprints "$project_key")

    if [[ -z "$sprints" ]]; then
        log_error "No sprints found for project $project_key"
        exit 1
    fi

    # Build sprint map
    declare -A sprint_start_dates
    declare -A sprint_end_dates

    while IFS='|' read -r sprint_id sprint_name start_date end_date; do
        if [[ -n "$start_date" ]]; then
            sprint_start_dates[$sprint_id]="$start_date"
            sprint_end_dates[$sprint_id]="$end_date"
            log_info "Sprint: $sprint_name ($sprint_id) from $start_date to $end_date"
        fi
    done <<< "$sprints"

    echo ""

    # Fetch all issues in project
    log_info "Fetching issues for project $project_key..."

    local start_at=0
    local max_results=100
    local total_issues=0
    local updated_count=0
    local error_count=0

    while true; do
        local issues
        issues=$(curl -s -u "$JIRA_EMAIL:$JIRA_API_KEY" \
            -X POST "$JIRA_BASE/rest/api/3/search/jql" \
            -H "Content-Type: application/json" \
            -d "{\"jql\":\"project=$project_key ORDER BY created\",\"startAt\":$start_at,\"maxResults\":$max_results,\"fields\":[\"key\",\"issuetype\",\"summary\",\"status\",\"sprint\",\"duedate\",\"subtasks\"]}")

        local is_last
        is_last=$(echo "$issues" | python3 -c "import json,sys; print(json.load(sys.stdin).get('isLast', True))")

        # Process issues
        echo "$issues" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for issue in data.get('issues', []):
    key = issue['key']
    issuetype = issue['fields']['issuetype']['name']
    summary = issue['fields']['summary']
    duedate = issue['fields'].get('duedate', '')
    sprints = issue['fields'].get('sprint', [])
    if sprints:
        if isinstance(sprints, list):
            sprint_id = sprints[0]['id'] if sprints else ''
        else:
            sprint_id = sprints.get('id', '') if sprints else ''
    else:
        sprint_id = ''
    print(f\"{key}|{issuetype}|{summary}|{duedate}|{sprint_id}\")
" | while IFS='|' read -r key issuetype summary duedate sprint_id; do
            ((total_issues++))

            # Skip if already has due date
            if [[ -n "$duedate" ]]; then
                continue
            fi

            # Get sprint start date
            local sprint_start="${sprint_start_dates[$sprint_id]:-}"

            if [[ -z "$sprint_start" ]]; then
                log_warning "$key: No sprint start date, skipping"
                continue
            fi

            # Calculate due date
            local subtask_prefix=""
            if [[ "$issuetype" == "Sub-task" ]]; then
                subtask_prefix=$(get_subtask_prefix "$summary")
            fi

            local calculated_due
            calculated_due=$(calculate_due_date "$sprint_start" "$issuetype" "$subtask_prefix")

            if [[ -z "$calculated_due" ]]; then
                log_warning "$key: Could not calculate due date"
                continue
            fi

            # Update issue
            if update_due_date "$key" "$calculated_due" "$dry_run"; then
                if [[ "$dry_run" == "true" ]]; then
                    ((updated_count++))
                else
                    log_success "$key: Set due date to $calculated_due"
                    ((updated_count++))
                fi
            else
                ((error_count++))
            fi

            # Rate limiting
            if [[ "$dry_run" != "true" ]]; then
                sleep 0.2
            fi
        done

        if [[ "$is_last" == "True" ]]; then
            break
        fi

        start_at=$((start_at + max_results))
    done

    echo ""
    log_info "=== Summary ==="
    log_info "Total issues: $total_issues"
    log_info "Issues without due date: $((total_issues - updated_count))"
    log_success "Updated: $updated_count"

    if [[ $error_count -gt 0 ]]; then
        log_error "Errors: $error_count"
    fi
}

main "$@"
