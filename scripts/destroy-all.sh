#!/bin/bash
# =============================================================================
# Nexus-Stack for Education - Destroy All Students
# =============================================================================
# DANGEROUS: Destroys all infrastructure AND state for all users
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# =============================================================================
# Functions
# =============================================================================

destroy_user() {
    local user_id="$1"
    local name=$(get_user_info "$user_id" "name")
    local nexus_dir="$INSTANCES_DIR/$user_id/Nexus-Stack"

    log_step "Destroying: $user_id ($name)"

    if ! is_user_initialized "$user_id"; then
        log_warning "  Not initialized, skipping"
        return 0
    fi

    cd "$nexus_dir"
    
    # Check if deployed
    if is_user_deployed "$user_id"; then
        log_info "  Destroying infrastructure..."
        if ! (source .env && make destroy-all 2>&1 | sed 's/^/    /'); then
            log_error "  Destroy failed"
            return 1
        fi
    fi

    log_success "  Destroyed successfully"
    return 0
}

# =============================================================================
# Main
# =============================================================================

log_header "Nexus-Stack for Education - DESTROY ALL"

echo -e "${RED}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                         ⚠️  WARNING ⚠️                          ║"
echo "║                                                                ║"
echo "║  This will PERMANENTLY DELETE all user infrastructure      ║"
echo "║  including R2 state buckets. This action is IRREVERSIBLE!     ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Load configuration
load_config

# Get all users
STUDENTS=($(get_user_ids))
INITIALIZED_COUNT=0

for user_id in "${STUDENTS[@]}"; do
    if is_user_initialized "$user_id"; then
        ((INITIALIZED_COUNT++))
    fi
done

if [ "$INITIALIZED_COUNT" -eq 0 ]; then
    log_info "No initialized users found"
    exit 0
fi

log_warning "Students to destroy: $INITIALIZED_COUNT"
echo ""

log_step "Students:"
for user_id in "${STUDENTS[@]}"; do
    if is_user_initialized "$user_id"; then
        name=$(get_user_info "$user_id" "name")
        echo -e "  ${RED}✗${NC} $user_id ($name)"
    fi
done

echo ""

# Require explicit confirmation
log_warning "Type 'DESTROY ALL' to confirm:"
read -p "> " confirmation

if [ "$confirmation" != "DESTROY ALL" ]; then
    log_info "Aborted - confirmation text did not match"
    exit 0
fi

echo ""

# Destroy each user
DESTROYED=0
FAILED=0

for user_id in "${STUDENTS[@]}"; do
    if is_user_initialized "$user_id"; then
        if destroy_user "$user_id"; then
            ((DESTROYED++))
        else
            ((FAILED++))
        fi
        echo ""
    fi
done

# Optional: Remove user directories
echo ""
if confirm "Also remove user directories?"; then
    for user_id in "${STUDENTS[@]}"; do
        user_dir="$INSTANCES_DIR/$user_id"
        if [ -d "$user_dir" ]; then
            rm -rf "$user_dir"
            log_info "Removed: $user_dir"
        fi
    done
fi

# Summary
log_header "Destruction Complete"
log_info "Destroyed: $DESTROYED"
log_info "Failed: $FAILED"

if [ "$DESTROYED" -gt 0 ]; then
    echo ""
    log_success "All infrastructure has been destroyed"
    log_info "To start fresh: ./scripts/init-all.sh"
fi
