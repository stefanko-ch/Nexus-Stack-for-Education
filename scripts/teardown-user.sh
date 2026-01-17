#!/bin/bash
# =============================================================================
# Nexus-Stack for Education - Teardown Single Student
# =============================================================================
# Tears down a single user's infrastructure
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# =============================================================================
# Main
# =============================================================================

if [ -z "$1" ]; then
    echo "Usage: $0 <user-id>"
    echo ""
    echo "Deployed users:"
    get_user_ids | while read -r id; do
        if is_user_deployed "$id"; then
            name=$(get_user_info "$id" "name")
            echo "  - $id ($name)"
        fi
    done
    exit 1
fi

USER_ID="$1"

log_header "Nexus-Stack for Education - Teardown Student"

# Load configuration
load_config

# Validate user
if ! validate_user_id "$USER_ID"; then
    exit 1
fi

name=$(get_user_info "$USER_ID" "name")
nexus_dir="$INSTANCES_DIR/$USER_ID/Nexus-Stack"

log_info "Student: $name ($USER_ID)"
echo ""

if ! is_user_deployed "$USER_ID"; then
    log_warning "Student is not deployed"
    exit 0
fi

if ! confirm "Teardown infrastructure for $name?"; then
    log_info "Aborted"
    exit 0
fi

cd "$nexus_dir"

log_step "Tearing down infrastructure..."
source .env && make teardown

echo ""
log_header "Teardown Complete"
log_success "Infrastructure stopped"
log_info "To re-deploy: ./scripts/deploy-user.sh $USER_ID"
