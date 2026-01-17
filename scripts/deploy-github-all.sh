#!/bin/bash
# =============================================================================
# Nexus-Stack for Education - Deploy All via GitHub Actions
# =============================================================================
# Triggers initial-setup workflow for all user repos
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/github.sh"

# =============================================================================
# Main
# =============================================================================

log_header "Nexus-Stack for Education - Deploy All (GitHub Actions)"

# Load configuration
load_config

# Check prerequisites
if ! check_gh_cli; then
    exit 1
fi

# Get users with repos
STUDENTS=($(get_user_ids))
TO_DEPLOY=()

for user_id in "${STUDENTS[@]}"; do
    if user_repo_exists "$user_id"; then
        TO_DEPLOY+=("$user_id")
    fi
done

if [ ${#TO_DEPLOY[@]} -eq 0 ]; then
    log_error "No user repos found"
    log_info "Run ./scripts/setup-github-repos.sh first"
    exit 1
fi

log_info "Students with GitHub repos: ${#TO_DEPLOY[@]}"
echo ""

log_step "Students to deploy:"
for user_id in "${TO_DEPLOY[@]}"; do
    name=$(get_user_info "$user_id" "name")
    repo_path=$(get_user_repo_path "$user_id")
    echo "  ○ $user_id ($name) - $repo_path"
done

echo ""
log_warning "This will trigger initial-setup.yaml in all repos!"
log_info "Each deployment creates a Hetzner server (~€4.50/month)"
echo ""

if ! confirm "Deploy all ${#TO_DEPLOY[@]} users?"; then
    log_info "Aborted"
    exit 0
fi

echo ""

# Trigger workflows
TRIGGERED=0
FAILED=0

for user_id in "${TO_DEPLOY[@]}"; do
    repo_path=$(get_user_repo_path "$user_id")
    name=$(get_user_info "$user_id" "name")
    
    log_step "Triggering: $user_id ($name)"
    
    if gh workflow run initial-setup.yaml --repo "$repo_path" 2>/dev/null; then
        log_success "  Workflow triggered"
        ((TRIGGERED++))
    else
        log_error "  Failed to trigger workflow"
        ((FAILED++))
    fi
    
    # Small delay to avoid rate limiting
    sleep 1
done

echo ""
log_header "Deployment Triggered"
log_info "Triggered: $TRIGGERED"
log_info "Failed: $FAILED"

if [ "$TRIGGERED" -gt 0 ]; then
    echo ""
    log_info "Monitor progress:"
    echo "  ./scripts/status-github.sh"
    echo ""
    log_info "Or check GitHub Actions directly:"
    for user_id in "${TO_DEPLOY[@]}"; do
        repo_path=$(get_user_repo_path "$user_id")
        echo "  https://github.com/$repo_path/actions"
    done
fi
