# Nexus-Stack for Education

> 🎓 Deploy individual [Nexus-Stack](https://github.com/stefanko-ch/Nexus-Stack) instances for multiple users with a single command.

## Overview

This tool automates the deployment of Nexus-Stack instances for educational environments. Each user gets:

- 🖥️ **Own Hetzner server** - Isolated compute resources
- 🌐 **Own subdomain** - `user-id.yourdomain.com`
- 🔐 **Own Cloudflare Access** - Login with their email
- 📊 **Own Control Plane** - Manage their services

## Prerequisites

- Bash shell
- `git`, `yq`, `jq` installed (`brew install yq jq`)
- `gh` CLI for GitHub method (`brew install gh`)
- `tofu` or `terraform` for local method

### Hetzner Cloud Setup

1. Create a project at [console.hetzner.cloud](https://console.hetzner.cloud)
2. Go to **Security** → **API Tokens**
3. Generate a token with **Read & Write** permissions
4. Save the token for `.env`

### Cloudflare Setup

1. Domain added to [Cloudflare](https://dash.cloudflare.com)
2. Create API Token at **Profile** → **API Tokens** with permissions:
   - Zone:DNS:Edit
   - Zone:Zone:Read  
   - Account:Cloudflare Tunnel:Edit
   - Account:Access: Apps and Policies:Edit
3. Note your **Account ID** and **Zone ID** (found in domain overview)

## Quick Start

```bash
# 1. Clone this repository
git clone https://github.com/stefanko-ch/Nexus-Stack-for-Education.git
cd Nexus-Stack-for-Education

# 2. Copy and configure secrets
cp .env.example .env
nano .env

# 3. Configure your class settings
cp config.example.sh config.sh
nano config.sh

# 4. Add your users
cp users.example.yaml users.yaml && nano users.yaml

# 5. Choose your deployment method (see below)
```

## Configuration

### `.env` - Shared Secrets

```bash
export TF_VAR_hcloud_token="your-hetzner-token"
export TF_VAR_cloudflare_api_token="your-cloudflare-token"
export TF_VAR_cloudflare_account_id="your-account-id"
```

### `config.sh` - Class Settings

```bash
# Base domain (users get subdomains)
BASE_DOMAIN="edu.example.com"

# Cloudflare Zone ID for base domain
CLOUDFLARE_ZONE_ID="your-zone-id"

# Server configuration
SERVER_TYPE="cax11"      # Hetzner server type
SERVER_LOCATION="fsn1"   # Hetzner datacenter

# GitHub (for Control Plane)
GITHUB_OWNER="your-username"
GITHUB_REPO="Nexus-Stack"
```

### `users.yaml` - Users & Admins

```yaml
users:
  - id: max-muster
    email: max.muster@example.ch
    name: Max Muster
    admins:
      - trainer@example.ch

  - id: anna-schmidt
    email: anna.schmidt@example.ch
    name: Anna Schmidt
```

## Deployment Methods

### Method 1: GitHub Repos (Recommended) ⭐

Each user gets their own GitHub repository with full GitHub Actions support. This is the recommended approach for production use.

**Setup:**
```bash
# 1. Authenticate GitHub CLI
gh auth login

# 2. Create repos for all users
./scripts/setup-github-repos.sh

# 3. Trigger initial deployment
./scripts/deploy-github-all.sh

# 4. Monitor status
./scripts/status-github.sh
```

**Commands:**
| Command | Description |
|---------|-------------|
| `./scripts/setup-github-repos.sh` | Create GitHub repos for all users |
| `./scripts/deploy-github-all.sh` | Trigger initial-setup workflow in all repos |
| `./scripts/teardown-github-all.sh` | Trigger teardown workflow in all repos |
| `./scripts/status-github.sh` | Show GitHub Actions status for all repos |
| `./scripts/delete-github-repos.sh` | Destroy infrastructure and delete all repos |

**Benefits:**
- ✅ Full GitHub Actions support (scheduled teardown/spin-up)
- ✅ Students can access their Control Plane to view workflows
- ✅ Easier debugging via GitHub Actions UI
- ✅ Infrastructure as Code versioned per user

---

### Method 2: Local Clones (Simple)

Clone Nexus-Stack locally and run deployments from your machine. Simpler setup but no GitHub Actions.

**Setup:**
```bash
# 1. Initialize all user environments
./scripts/init-all.sh

# 2. Deploy all users
./scripts/deploy-all.sh
```

**Commands:**
| Command | Description |
|---------|-------------|
| `./scripts/init-all.sh` | Initialize all user environments |
| `./scripts/deploy-all.sh` | Deploy all users |
| `./scripts/teardown-all.sh` | Teardown all user infrastructure |
| `./scripts/destroy-all.sh` | Destroy everything (requires confirmation) |
| `./scripts/status.sh` | Show status of all deployments |
| `./scripts/deploy-user.sh <id>` | Deploy single user |
| `./scripts/teardown-user.sh <id>` | Teardown single user |

---

## How It Works

1. **Initialization**: Clones Nexus-Stack into `instances/<user-id>/`
2. **Configuration**: Generates `.env` and `config.tfvars` for each user
3. **Deployment**: Runs `make up` in each user directory
4. **Access**: Users receive email with their credentials

## Folder Structure

```
Nexus-Stack-for-Education/
├── .env                    # Shared secrets (gitignored)
├── config.sh               # Class configuration
├── users.yaml            # Student list
├── scripts/
│   ├── init-all.sh         # Initialize all
│   ├── deploy-all.sh       # Deploy all
│   ├── teardown-all.sh     # Teardown all
│   ├── destroy-all.sh      # Destroy all
│   ├── status.sh           # Status overview
│   ├── deploy-user.sh   # Single user deploy
│   └── lib/                # Shared functions
└── instances/              # Generated (gitignored)
    ├── max-muster/
    │   └── Nexus-Stack/
    ├── anna-schmidt/
    │   └── Nexus-Stack/
    └── ...
```

## Cost Estimation

Per user (monthly, ~24/7 operation):
- **Hetzner cax11**: ~€4.50/month
- **Cloudflare**: Free (included in your account)

For a class of 20 users: **~€90/month**

💡 **Tip**: Use scheduled teardown to automatically shut down outside class hours!

## Scheduled Teardown

Each user's Control Plane supports scheduled teardown. Configure via:
- Control Plane UI at `https://control.user-id.yourdomain.com`
- Or set defaults in `config.sh`

## Related

- [Nexus-Stack](https://github.com/stefanko-ch/Nexus-Stack) - The underlying infrastructure

## License

MIT
