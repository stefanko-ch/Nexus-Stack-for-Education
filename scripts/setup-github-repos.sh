#!/bin/bash
# =============================================================================
# Nexus-Stack for Education - Setup GitHub Repos for All Students
# =============================================================================
# Creates a GitHub repository for each user with all secrets configured
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/github.sh"

# =============================================================================
# Main
# =============================================================================

log_header "Nexus-Stack for Education - Setup GitHub Repos"

# Load configuration
load_config

# Check prerequisites
check_prerequisites
if ! check_gh_cli; then
    exit 1
fi

# Count users
STUDENT_COUNT=$(count_users)

if [ "$STUDENT_COUNT" -eq 0 ]; then
    log_error "No users found in users.yaml"
    exit 1
fi

log_info "Found $STUDENT_COUNT users"
log_info "Repos will be created as: $(get_repos_owner)/${GITHUB_REPO_PREFIX}-<user-id>"
log_info "Visibility: $([ "$GITHUB_REPOS_PRIVATE" = "true" ] && echo "Private" || echo "Public")"
echo ""

# Show users
log_step "Students to setup:"
get_user_ids | while read -r user_id; do
    name=$(get_user_info "$user_id" "name")
    repo_path=$(get_user_repo_path "$user_id")
    
    if user_repo_exists "$user_id"; then
        echo -e "  ${GREEN}✓${NC} $user_id ($name) - $repo_path [exists]"
    else
        echo -e "  ${YELLOW}○${NC} $user_id ($name) - $repo_path"
    fi
done

echo ""
log_warning "This will create GitHub repositories and set secrets!"
echo ""

if ! confirm "Create GitHub repos for all users?"; then
    log_info "Aborted"
    exit 0
fi

echo ""

# Setup each user
CREATED=0
SKIPPED=0
FAILED=0

for user_id in $(get_user_ids); do
    name=$(get_user_info "$user_id" "name")
    
    if user_repo_exists "$user_id"; then
        log_warning "Skipping $user_id - repo already exists"
        ((SKIPPED++))
        continue
    fi

    echo ""
    if setup_user_github "$user_id"; then
        ((CREATED++))
    else
        ((FAILED++))
    fi
done

echo ""
log_header "GitHub Setup Complete"
log_info "Created: $CREATED"
log_info "Skipped (already exist): $SKIPPED"
log_info "Failed: $FAILED"

if [ "$CREATED" -gt 0 ]; then
    echo ""
    log_info "Next steps:"
    echo "  1. Review repos at: https://github.com/$(get_repos_owner)?tab=repositories"
    echo "  2. Run initial deployment: ./scripts/deploy-github-all.sh"
    echo ""
    log_info "Or deploy individually:"
    echo "  gh workflow run initial-setup.yaml --repo <owner>/<repo>"
fi
