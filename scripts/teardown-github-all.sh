#!/bin/bash
# =============================================================================
# Nexus-Stack for Education - Teardown All via GitHub Actions
# =============================================================================
# Triggers teardown workflow for all user repos
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/github.sh"

# =============================================================================
# Main
# =============================================================================

log_header "Nexus-Stack for Education - Teardown All (GitHub Actions)"

# Load configuration
load_config

# Check prerequisites
if ! check_gh_cli; then
    exit 1
fi

# Get users with repos
STUDENTS=($(get_user_ids))
TO_TEARDOWN=()

for user_id in "${STUDENTS[@]}"; do
    if user_repo_exists "$user_id"; then
        TO_TEARDOWN+=("$user_id")
    fi
done

if [ ${#TO_TEARDOWN[@]} -eq 0 ]; then
    log_info "No user repos found"
    exit 0
fi

log_info "Students with GitHub repos: ${#TO_TEARDOWN[@]}"
echo ""

log_step "Students to teardown:"
for user_id in "${TO_TEARDOWN[@]}"; do
    name=$(get_user_info "$user_id" "name")
    repo_path=$(get_user_repo_path "$user_id")
    echo "  ○ $user_id ($name) - $repo_path"
done

echo ""
log_warning "This will stop all Hetzner servers (cost saving mode)"
log_info "State is preserved - use deploy-github-all.sh to re-deploy"
echo ""

if ! confirm "Teardown all ${#TO_TEARDOWN[@]} users?"; then
    log_info "Aborted"
    exit 0
fi

echo ""

# Trigger workflows
TRIGGERED=0
FAILED=0

for user_id in "${TO_TEARDOWN[@]}"; do
    repo_path=$(get_user_repo_path "$user_id")
    name=$(get_user_info "$user_id" "name")
    
    log_step "Triggering teardown: $user_id ($name)"
    
    if gh workflow run teardown.yml --repo "$repo_path" 2>/dev/null; then
        log_success "  Workflow triggered"
        ((TRIGGERED++))
    else
        log_error "  Failed to trigger workflow"
        ((FAILED++))
    fi
    
    sleep 1
done

echo ""
log_header "Teardown Triggered"
log_info "Triggered: $TRIGGERED"
log_info "Failed: $FAILED"

if [ "$TRIGGERED" -gt 0 ]; then
    echo ""
    log_success "Infrastructure will be stopped shortly"
    log_info "Monthly costs reduced!"
fi
