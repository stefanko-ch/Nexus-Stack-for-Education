#!/bin/bash
# =============================================================================
# Nexus-Stack for Education - Delete All GitHub Repos
# =============================================================================
# DANGEROUS: Deletes all user GitHub repositories
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/github.sh"

# =============================================================================
# Main
# =============================================================================

log_header "Nexus-Stack for Education - DELETE ALL REPOS"

echo -e "${RED}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                         ⚠️  WARNING ⚠️                          ║"
echo "║                                                                ║"
echo "║  This will PERMANENTLY DELETE all user GitHub repos!       ║"
echo "║  Including all infrastructure and state!                      ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Load configuration
load_config

# Check prerequisites
if ! check_gh_cli; then
    exit 1
fi

# Get users with repos
STUDENTS=($(get_user_ids))
TO_DELETE=()

for user_id in "${STUDENTS[@]}"; do
    if user_repo_exists "$user_id"; then
        TO_DELETE+=("$user_id")
    fi
done

if [ ${#TO_DELETE[@]} -eq 0 ]; then
    log_info "No user repos found"
    exit 0
fi

log_warning "Repos to delete: ${#TO_DELETE[@]}"
echo ""

log_step "Repos:"
for user_id in "${TO_DELETE[@]}"; do
    name=$(get_user_info "$user_id" "name")
    repo_path=$(get_user_repo_path "$user_id")
    echo -e "  ${RED}✗${NC} $repo_path ($name)"
done

echo ""

# First: Trigger destroy-all in each repo to clean up infrastructure
log_warning "Step 1: Destroy infrastructure in each repo"
if confirm "Trigger destroy-all workflow first? (recommended)"; then
    for user_id in "${TO_DELETE[@]}"; do
        repo_path=$(get_user_repo_path "$user_id")
        log_step "Destroying infrastructure: $repo_path"
        gh workflow run destroy-all.yml --repo "$repo_path" -f confirm=DESTROY 2>/dev/null || true
        sleep 1
    done
    
    echo ""
    log_warning "Waiting 60 seconds for destroy workflows to start..."
    log_info "You can monitor at: https://github.com/$(get_repos_owner)?tab=repositories"
    sleep 60
fi

echo ""

# Require explicit confirmation
log_warning "Step 2: Delete GitHub repositories"
log_warning "Type 'DELETE ALL REPOS' to confirm:"
read -p "> " confirmation

if [ "$confirmation" != "DELETE ALL REPOS" ]; then
    log_info "Aborted - confirmation text did not match"
    exit 0
fi

echo ""

# Delete repos
DELETED=0
FAILED=0

for user_id in "${TO_DELETE[@]}"; do
    if delete_user_repo "$user_id"; then
        ((DELETED++))
    else
        ((FAILED++))
    fi
done

echo ""
log_header "Deletion Complete"
log_info "Deleted: $DELETED"
log_info "Failed: $FAILED"

if [ "$DELETED" -gt 0 ]; then
    echo ""
    log_success "All repos have been deleted"
    log_info "To start fresh: ./scripts/setup-github-repos.sh"
fi
