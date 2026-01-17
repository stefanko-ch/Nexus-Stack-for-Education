#!/bin/bash
# =============================================================================
# Nexus-Stack for Education - Initialize All Students
# =============================================================================
# Clones Nexus-Stack for each user and configures their environment
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# =============================================================================
# Main
# =============================================================================

log_header "Nexus-Stack for Education - Initialize All Students"

# Load configuration
load_config
check_prerequisites

# Count users
STUDENT_COUNT=$(count_users)

if [ "$STUDENT_COUNT" -eq 0 ]; then
    log_error "No users found in users.yaml"
    exit 1
fi

log_info "Found $STUDENT_COUNT users to initialize"
echo ""

# Show users
log_step "Students to initialize:"
get_user_ids | while read -r user_id; do
    email=$(get_user_info "$user_id" "email")
    name=$(get_user_info "$user_id" "name")
    domain=$(get_user_domain "$user_id")
    
    if is_user_initialized "$user_id"; then
        echo -e "  ${GREEN}✓${NC} $user_id ($name) - $domain [already initialized]"
    else
        echo -e "  ${YELLOW}○${NC} $user_id ($name) - $domain"
    fi
done

echo ""

# Confirm
if ! confirm "Initialize all users?"; then
    log_info "Aborted"
    exit 0
fi

echo ""

# Create instances directory
mkdir -p "$INSTANCES_DIR"

# Initialize each user
INITIALIZED=0
SKIPPED=0
FAILED=0

get_user_ids | while read -r user_id; do
    email=$(get_user_info "$user_id" "email")
    name=$(get_user_info "$user_id" "name")
    admins=$(get_user_info "$user_id" "admins")
    domain=$(get_user_domain "$user_id")
    user_dir="$INSTANCES_DIR/$user_id"
    nexus_dir="$user_dir/Nexus-Stack"

    log_step "Initializing: $user_id ($name)"

    # Skip if already initialized
    if is_user_initialized "$user_id"; then
        log_warning "  Already initialized, skipping"
        ((SKIPPED++)) || true
        continue
    fi

    # Create user directory
    mkdir -p "$user_dir"

    # Clone Nexus-Stack
    log_info "  Cloning Nexus-Stack..."
    if ! git clone --depth 1 --branch "$NEXUS_STACK_BRANCH" \
        "https://github.com/$GITHUB_OWNER/$GITHUB_REPO.git" \
        "$nexus_dir" 2>/dev/null; then
        log_error "  Failed to clone Nexus-Stack"
        ((FAILED++)) || true
        continue
    fi

    # Generate .env (secrets - same for all users)
    log_info "  Generating .env..."
    cat > "$nexus_dir/.env" << EOF
# Auto-generated for: $name ($user_id)
# Generated: $(date -u '+%Y-%m-%d %H:%M UTC')

export TF_VAR_hcloud_token="$TF_VAR_hcloud_token"
export TF_VAR_cloudflare_api_token="$TF_VAR_cloudflare_api_token"
export TF_VAR_cloudflare_account_id="$TF_VAR_cloudflare_account_id"
EOF

    # Add optional Docker Hub credentials
    if [ -n "$TF_VAR_dockerhub_username" ] && [ -n "$TF_VAR_dockerhub_token" ]; then
        cat >> "$nexus_dir/.env" << EOF
export TF_VAR_dockerhub_username="$TF_VAR_dockerhub_username"
export TF_VAR_dockerhub_token="$TF_VAR_dockerhub_token"
EOF
    fi

    # Add optional Resend API key
    if [ -n "$TF_VAR_resend_api_key" ]; then
        cat >> "$nexus_dir/.env" << EOF
export TF_VAR_resend_api_key="$TF_VAR_resend_api_key"
EOF
    fi

    # Generate config.tfvars
    log_info "  Generating config.tfvars..."
    cat > "$nexus_dir/tofu/stack/config.tfvars" << EOF
# =============================================================================
# Nexus-Stack Configuration for: $name
# =============================================================================
# User ID: $user_id
# Generated: $(date -u '+%Y-%m-%d %H:%M UTC')
# =============================================================================

# Cloudflare Zone ID
cloudflare_zone_id = "$CLOUDFLARE_ZONE_ID"

# User's domain
domain = "$domain"

# Admin emails for Cloudflare Access (comma-separated list)
admin_email = "$admins"

# Server configuration
server_name     = "nexus-$user_id"
server_type     = "$SERVER_TYPE"
server_location = "$SERVER_LOCATION"

# Admin username for services
admin_username = "$ADMIN_USERNAME"

# GitHub (for Control Plane)
github_owner = "$GITHUB_OWNER"
github_repo  = "$GITHUB_REPO"
EOF

    log_success "  Initialized successfully"
    ((INITIALIZED++)) || true
done

echo ""
log_header "Initialization Complete"
log_info "Initialized: $INITIALIZED"
log_info "Skipped: $SKIPPED"
log_info "Failed: $FAILED"

if [ "$INITIALIZED" -gt 0 ] || [ "$SKIPPED" -gt 0 ]; then
    echo ""
    log_info "Next steps:"
    echo "  1. Review user configurations in users/<user-id>/Nexus-Stack/"
    echo "  2. Run: ./scripts/deploy-all.sh"
fi
