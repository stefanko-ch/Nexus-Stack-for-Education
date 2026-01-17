#!/bin/bash
# =============================================================================
# Nexus-Stack for Education - Deploy All Students
# =============================================================================
# Deploys Nexus-Stack for all initialized users
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# =============================================================================
# Functions
# =============================================================================

deploy_user() {
    local user_id="$1"
    local name=$(get_user_info "$user_id" "name")
    local domain=$(get_user_domain "$user_id")
    local nexus_dir="$INSTANCES_DIR/$user_id/Nexus-Stack"

    log_step "Deploying: $user_id ($name)"

    if ! is_user_initialized "$user_id"; then
        log_error "  Not initialized. Run init-all.sh first."
        return 1
    fi

    if is_user_deployed "$user_id"; then
        log_warning "  Already deployed. Use spin-up to update."
        return 0
    fi

    # Run make init + make up
    log_info "  Running initialization..."
    cd "$nexus_dir"
    
    # Source .env and run init
    if ! (source .env && make init 2>&1 | sed 's/^/    /'); then
        log_error "  Initialization failed"
        return 1
    fi

    log_info "  Deploying infrastructure..."
    if ! (source .env && make up 2>&1 | sed 's/^/    /'); then
        log_error "  Deployment failed"
        return 1
    fi

    log_success "  Deployed successfully!"
    log_info "  Control Plane: https://control.$domain"
    log_info "  Info Page: https://info.$domain"
    
    return 0
}

# =============================================================================
# Main
# =============================================================================

log_header "Nexus-Stack for Education - Deploy All Students"

# Load configuration
load_config
check_prerequisites

# Get initialized users
STUDENTS=($(get_user_ids))
INITIALIZED_COUNT=0
TO_DEPLOY=()

for user_id in "${STUDENTS[@]}"; do
    if is_user_initialized "$user_id"; then
        ((INITIALIZED_COUNT++))
        if ! is_user_deployed "$user_id"; then
            TO_DEPLOY+=("$user_id")
        fi
    fi
done

if [ "$INITIALIZED_COUNT" -eq 0 ]; then
    log_error "No initialized users found"
    log_info "Run ./scripts/init-all.sh first"
    exit 1
fi

log_info "Total users: ${#STUDENTS[@]}"
log_info "Initialized: $INITIALIZED_COUNT"
log_info "To deploy: ${#TO_DEPLOY[@]}"

if [ ${#TO_DEPLOY[@]} -eq 0 ]; then
    log_success "All users are already deployed!"
    log_info "Use teardown-all.sh + deploy-all.sh to redeploy"
    exit 0
fi

echo ""
log_step "Students to deploy:"
for user_id in "${TO_DEPLOY[@]}"; do
    name=$(get_user_info "$user_id" "name")
    domain=$(get_user_domain "$user_id")
    echo "  ○ $user_id ($name) - $domain"
done

echo ""
log_warning "This will create Hetzner servers and incur costs!"
log_info "Estimated cost: ~€${#TO_DEPLOY[@]} × €4.50/month = €$((${#TO_DEPLOY[@]} * 5))/month"
echo ""

if ! confirm "Deploy ${#TO_DEPLOY[@]} users?"; then
    log_info "Aborted"
    exit 0
fi

echo ""

# Deploy each user
DEPLOYED=0
FAILED=0

for user_id in "${TO_DEPLOY[@]}"; do
    if deploy_user "$user_id"; then
        ((DEPLOYED++))
    else
        ((FAILED++))
    fi
    echo ""
done

# Summary
log_header "Deployment Complete"
log_info "Deployed: $DEPLOYED"
log_info "Failed: $FAILED"

if [ "$DEPLOYED" -gt 0 ]; then
    echo ""
    log_info "Student URLs:"
    for user_id in "${TO_DEPLOY[@]}"; do
        if is_user_deployed "$user_id"; then
            domain=$(get_user_domain "$user_id")
            name=$(get_user_info "$user_id" "name")
            echo "  $name:"
            echo "    Control: https://control.$domain"
            echo "    Info: https://info.$domain"
        fi
    done
fi

if [ "$FAILED" -gt 0 ]; then
    echo ""
    log_warning "Some deployments failed. Check the logs above."
fi
