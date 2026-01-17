#!/bin/bash
# =============================================================================
# Nexus-Stack for Education - Teardown All Students
# =============================================================================
# Tears down infrastructure for all deployed users (keeps state for re-deploy)
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# =============================================================================
# Functions
# =============================================================================

teardown_user() {
    local user_id="$1"
    local name=$(get_user_info "$user_id" "name")
    local nexus_dir="$INSTANCES_DIR/$user_id/Nexus-Stack"

    log_step "Tearing down: $user_id ($name)"

    if ! is_user_deployed "$user_id"; then
        log_warning "  Not deployed, skipping"
        return 0
    fi

    cd "$nexus_dir"
    
    if ! (source .env && make teardown 2>&1 | sed 's/^/    /'); then
        log_error "  Teardown failed"
        return 1
    fi

    log_success "  Torn down successfully"
    return 0
}

# =============================================================================
# Main
# =============================================================================

log_header "Nexus-Stack for Education - Teardown All Students"

# Load configuration
load_config

# Get deployed users
STUDENTS=($(get_user_ids))
TO_TEARDOWN=()

for user_id in "${STUDENTS[@]}"; do
    if is_user_deployed "$user_id"; then
        TO_TEARDOWN+=("$user_id")
    fi
done

if [ ${#TO_TEARDOWN[@]} -eq 0 ]; then
    log_info "No deployed users found"
    exit 0
fi

log_info "Students to tear down: ${#TO_TEARDOWN[@]}"
echo ""

log_step "Students:"
for user_id in "${TO_TEARDOWN[@]}"; do
    name=$(get_user_info "$user_id" "name")
    echo "  ○ $user_id ($name)"
done

echo ""
log_warning "This will stop all Hetzner servers (cost saving mode)"
log_info "State is preserved - use deploy-all.sh to re-deploy"
echo ""

if ! confirm "Teardown ${#TO_TEARDOWN[@]} users?"; then
    log_info "Aborted"
    exit 0
fi

echo ""

# Teardown each user
TORN_DOWN=0
FAILED=0

for user_id in "${TO_TEARDOWN[@]}"; do
    if teardown_user "$user_id"; then
        ((TORN_DOWN++))
    else
        ((FAILED++))
    fi
    echo ""
done

# Summary
log_header "Teardown Complete"
log_info "Torn down: $TORN_DOWN"
log_info "Failed: $FAILED"

if [ "$TORN_DOWN" -gt 0 ]; then
    echo ""
    log_success "Infrastructure stopped. Monthly costs reduced!"
    log_info "To re-deploy: ./scripts/deploy-all.sh"
fi
