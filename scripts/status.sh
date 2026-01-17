#!/bin/bash
# =============================================================================
# Nexus-Stack for Education - Status Overview
# =============================================================================
# Shows the status of all user deployments
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# =============================================================================
# Main
# =============================================================================

log_header "Nexus-Stack for Education - Status Overview"

# Load configuration (but don't fail if missing)
if [ -f "$PROJECT_ROOT/.env" ]; then
    source "$PROJECT_ROOT/.env"
fi

if [ -f "$PROJECT_ROOT/config.sh" ]; then
    source "$PROJECT_ROOT/config.sh"
fi

# Check users.yaml
if [ ! -f "$PROJECT_ROOT/users.yaml" ]; then
    log_error "users.yaml not found"
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
INITIALIZED=0
DEPLOYED=0
NOT_INITIALIZED=0

echo ""
printf "%-20s %-30s %-15s %-40s\n" "STUDENT ID" "NAME" "STATUS" "DOMAIN"
printf "%-20s %-30s %-15s %-40s\n" "──────────" "────" "──────" "──────"

for user_id in "${STUDENTS[@]}"; do
    name=$(get_user_info "$user_id" "name")
    domain=$(get_user_domain "$user_id")
    
    if is_user_deployed "$user_id"; then
        status="${GREEN}DEPLOYED${NC}"
        ((DEPLOYED++))
        ((INITIALIZED++))
    elif is_user_initialized "$user_id"; then
        status="${YELLOW}INITIALIZED${NC}"
        ((INITIALIZED++))
    else
        status="${RED}NOT INIT${NC}"
        ((NOT_INITIALIZED++))
    fi
    
    printf "%-20s %-30s $(echo -e $status)%-8s %-40s\n" "$user_id" "$name" "" "$domain"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_info "Total: $TOTAL"
log_info "Deployed: $DEPLOYED"
log_info "Initialized (not deployed): $((INITIALIZED - DEPLOYED))"
log_info "Not initialized: $NOT_INITIALIZED"

if [ "$DEPLOYED" -gt 0 ]; then
    echo ""
    log_info "Estimated monthly cost: ~€$((DEPLOYED * 5))/month"
fi

echo ""
log_info "Commands:"
echo "  Initialize all:  ./scripts/init-all.sh"
echo "  Deploy all:      ./scripts/deploy-all.sh"
echo "  Teardown all:    ./scripts/teardown-all.sh"
echo "  Single user:  ./scripts/deploy-user.sh <user-id>"
