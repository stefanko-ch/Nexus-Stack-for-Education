#!/bin/bash
# =============================================================================
# Nexus-Stack for Education - GitHub Status Overview
# =============================================================================
# Shows GitHub Actions status for all user repos
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/github.sh"

# =============================================================================
# Main
# =============================================================================

log_header "Nexus-Stack for Education - GitHub Status"

# Load configuration
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
fi
if [ -f "$PROJECT_ROOT/config.sh" ]; then
    source "$PROJECT_ROOT/config.sh"
fi

# Check gh CLI
if ! check_gh_cli 2>/dev/null; then
    log_error "GitHub CLI not available"
    exit 1
fi

# Get users
STUDENTS=($(get_user_ids))

if [ ${#STUDENTS[@]} -eq 0 ]; then
    log_info "No users configured"
    exit 0
fi

# Count states
TOTAL=${#STUDENTS[@]}
HAS_REPO=0
DEPLOYED=0
TORN_DOWN=0
FAILED=0
NO_RUNS=0

echo ""
printf "%-18s %-25s %-12s %-15s %-30s\n" "STUDENT" "NAME" "REPO" "STATUS" "LAST RUN"
printf "%-18s %-25s %-12s %-15s %-30s\n" "───────" "────" "────" "──────" "────────"

for user_id in "${STUDENTS[@]}"; do
    name=$(get_user_info "$user_id" "name")
    repo_path=$(get_user_repo_path "$user_id")
    
    if ! user_repo_exists "$user_id"; then
        printf "%-18s %-25s ${RED}%-12s${NC} %-15s %-30s\n" "$user_id" "$name" "NO REPO" "-" "-"
        continue
    fi
    
    ((HAS_REPO++))
    
    # Get latest workflow run
    latest_run=$(gh run list --repo "$repo_path" --limit 1 --json name,status,conclusion,updatedAt 2>/dev/null || echo "[]")
    
    if [ "$latest_run" = "[]" ] || [ "$(echo "$latest_run" | jq 'length')" = "0" ]; then
        printf "%-18s %-25s ${GREEN}%-12s${NC} ${YELLOW}%-15s${NC} %-30s\n" "$user_id" "$name" "✓" "NO RUNS" "-"
        ((NO_RUNS++))
        continue
    fi
    
    run_name=$(echo "$latest_run" | jq -r '.[0].name // "unknown"')
    run_status=$(echo "$latest_run" | jq -r '.[0].status // "unknown"')
    run_conclusion=$(echo "$latest_run" | jq -r '.[0].conclusion // ""')
    run_time=$(echo "$latest_run" | jq -r '.[0].updatedAt // ""' | cut -d'T' -f1)
    
    # Determine status
    if [ "$run_status" = "in_progress" ] || [ "$run_status" = "queued" ]; then
        status="${YELLOW}RUNNING${NC}"
    elif [ "$run_conclusion" = "success" ]; then
        if [[ "$run_name" == *"Teardown"* ]]; then
            status="${CYAN}TORN DOWN${NC}"
            ((TORN_DOWN++))
        elif [[ "$run_name" == *"Destroy"* ]]; then
            status="${RED}DESTROYED${NC}"
        else
            status="${GREEN}DEPLOYED${NC}"
            ((DEPLOYED++))
        fi
    elif [ "$run_conclusion" = "failure" ]; then
        status="${RED}FAILED${NC}"
        ((FAILED++))
    else
        status="$run_status"
    fi
    
    # Truncate run name
    run_name_short="${run_name:0:20}"
    
    printf "%-18s %-25s ${GREEN}%-12s${NC} $(echo -e $status)%-8s %-30s\n" \
        "$user_id" "$name" "✓" "" "$run_name_short ($run_time)"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_info "Total users: $TOTAL"
log_info "With GitHub repo: $HAS_REPO"
log_info "Deployed: $DEPLOYED"
log_info "Torn down: $TORN_DOWN"
log_info "Failed: $FAILED"
log_info "No runs yet: $NO_RUNS"

if [ "$DEPLOYED" -gt 0 ]; then
    echo ""
    log_info "Estimated monthly cost: ~€$((DEPLOYED * 5))/month"
fi

echo ""
log_info "Commands:"
echo "  Setup repos:     ./scripts/setup-github-repos.sh"
echo "  Deploy all:      ./scripts/deploy-github-all.sh"
echo "  Teardown all:    ./scripts/teardown-github-all.sh"
