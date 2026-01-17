#!/bin/bash
# =============================================================================
# Nexus-Stack for Education - Class Configuration
# =============================================================================
# Copy this file to config.sh and fill in your values:
#   cp config.example.sh config.sh
#   nano config.sh
# =============================================================================

# =============================================================================
# Domain Configuration
# =============================================================================
# Base domain for all users
# Each user gets: <user-id>.BASE_DOMAIN
# Example: max-muster.edu.example.com
BASE_DOMAIN="edu.example.com"

# Cloudflare Zone ID for the base domain
# Find in: Cloudflare Dashboard → Your Domain → Overview (right sidebar)
CLOUDFLARE_ZONE_ID=""

# =============================================================================
# Server Configuration
# =============================================================================
# Hetzner server type (default: cax11 = 2 vCPU, 4GB RAM, ARM, ~€4.50/month)
# Options: cax11, cax21, cax31, cpx11, cpx21, cpx31
SERVER_TYPE="cax11"

# Hetzner datacenter location
# Options: fsn1 (Falkenstein), nbg1 (Nuremberg), hel1 (Helsinki)
SERVER_LOCATION="fsn1"

# =============================================================================
# GitHub Configuration (for Control Plane)
# =============================================================================
# Your GitHub username
GITHUB_OWNER="stefanko-ch"

# Nexus-Stack repository name (used as template for user repos)
GITHUB_REPO="Nexus-Stack"

# Branch to clone (default: main)
NEXUS_STACK_BRANCH="main"

# =============================================================================
# GitHub Repos Configuration (Method 1: GitHub-based deployment)
# =============================================================================
# Prefix for user repository names (e.g., "edu-" → "edu-max-muster")
GITHUB_REPO_PREFIX="nexus-"

# Make user repos private (true/false)
GITHUB_REPOS_PRIVATE="true"

# Organization to create repos in (leave empty for personal account)
# GITHUB_ORG="my-organization"

# =============================================================================
# Admin Configuration
# =============================================================================
# Default admin username for services (Portainer, Grafana, etc.)
ADMIN_USERNAME="user"

# =============================================================================
# Optional: Default Services
# =============================================================================
# Comma-separated list of services to enable by default
# If empty, uses Nexus-Stack defaults from services.tfvars
# DEFAULT_SERVICES="info,portainer,grafana,it-tools"

# =============================================================================
# Optional: Scheduled Teardown
# =============================================================================
# Enable scheduled teardown by default (cost saving)
# ENABLE_SCHEDULED_TEARDOWN="true"
# TEARDOWN_TIME="22:00"
# TEARDOWN_TIMEZONE="Europe/Zurich"
