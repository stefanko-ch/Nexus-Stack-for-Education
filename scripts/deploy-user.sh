#!/bin/bash
# =============================================================================
# Nexus-Stack for Education - Deploy Single Student
# =============================================================================
# Deploys or re-deploys a single user
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
    echo "Available users:"
    get_user_ids | while read -r id; do
        name=$(get_user_info "$id" "name")
        echo "  - $id ($name)"
    done
    exit 1
fi

USER_ID="$1"

log_header "Nexus-Stack for Education - Deploy User"

# Load configuration
load_config
check_prerequisites

# Validate user
if ! validate_user_id "$USER_ID"; then
    exit 1
fi

name=$(get_user_info "$USER_ID" "name")
email=$(get_user_info "$USER_ID" "email")
admins=$(get_user_info "$USER_ID" "admins")
domain=$(get_user_domain "$USER_ID")
nexus_dir="$INSTANCES_DIR/$USER_ID/Nexus-Stack"

log_info "User: $name ($USER_ID)"
log_info "Email: $email"
log_info "Domain: $domain"
echo ""

# Check if initialized
if ! is_user_initialized "$USER_ID"; then
    log_warning "User not initialized. Initializing now..."
    
    user_dir="$INSTANCES_DIR/$USER_ID"
    mkdir -p "$user_dir"
    
    # Clone Nexus-Stack
    log_step "Cloning Nexus-Stack..."
    git clone --depth 1 --branch "$NEXUS_STACK_BRANCH" \
        "https://github.com/$GITHUB_OWNER/$GITHUB_REPO.git" \
        "$nexus_dir"
    
    # Generate .env
    log_step "Generating .env..."
    cat > "$nexus_dir/.env" << EOF
# Auto-generated for: $name ($USER_ID)
export TF_VAR_hcloud_token="$TF_VAR_hcloud_token"
export TF_VAR_cloudflare_api_token="$TF_VAR_cloudflare_api_token"
export TF_VAR_cloudflare_account_id="$TF_VAR_cloudflare_account_id"
EOF

    # Generate config.tfvars
    log_step "Generating config.tfvars..."
    cat > "$nexus_dir/tofu/stack/config.tfvars" << EOF
cloudflare_zone_id = "$CLOUDFLARE_ZONE_ID"
domain = "$domain"
admin_email = "$admins"
server_name = "nexus-$USER_ID"
server_type = "$SERVER_TYPE"
server_location = "$SERVER_LOCATION"
admin_username = "$ADMIN_USERNAME"
github_owner = "$GITHUB_OWNER"
github_repo = "$GITHUB_REPO"
EOF

    log_success "Initialized successfully"
    echo ""
fi

# Check if already deployed
if is_user_deployed "$USER_ID"; then
    log_warning "Student is already deployed"
    if ! confirm "Re-deploy (spin-up)?"; then
        exit 0
    fi
    
    cd "$nexus_dir"
    log_step "Running spin-up..."
    source .env && make up
else
    # Fresh deploy
    cd "$nexus_dir"
    
    log_step "Running initialization..."
    source .env && make init
    
    log_step "Deploying infrastructure..."
    source .env && make up
fi

echo ""
log_header "Deployment Complete"
log_success "Student deployed successfully!"
echo ""
log_info "URLs:"
echo "  Control Plane: https://control.$domain"
echo "  Info Page: https://info.$domain"
echo ""
log_info "The user can log in with: $email"
