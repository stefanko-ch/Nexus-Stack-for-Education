# AGENTS.md

> Instructions for AI coding agents working on this project.

## Project Overview

**Nexus-Stack for Education** automates deploying [Nexus-Stack](https://github.com/stefanko-ch/Nexus-Stack) instances for multiple users (training participants, students, etc.).

Each user gets:
- Own Hetzner Cloud server
- Own subdomain (`<id>.BASE_DOMAIN`)
- Own Cloudflare Access (login with email)
- Own GitHub repo (optional, for GitHub Actions)

## Architecture

```
Nexus-Stack-for-Education/
├── users.yaml              # User configuration (YAML, not CSV)
├── config.sh               # Class/training settings (gitignored)
├── .env                    # Secrets (gitignored)
├── scripts/
│   ├── lib/
│   │   ├── common.sh       # Shared functions (logging, user management)
│   │   └── github.sh       # GitHub repo automation functions
│   ├── init-all.sh         # Initialize local clones
│   ├── deploy-all.sh       # Deploy all users (local method)
│   ├── setup-github-repos.sh   # Create GitHub repos (GitHub method)
│   └── ...
└── instances/              # Generated user instances (gitignored)
```

## Key Files

### `users.yaml`
```yaml
users:
  - id: max-muster          # Unique ID (lowercase, hyphens)
    email: max@example.ch   # Primary email for Cloudflare Access
    name: Max Muster        # Display name (optional)
    admins:                 # Additional admin emails (optional)
      - trainer@example.ch
```

### `scripts/lib/common.sh`
Core functions:
- `get_user_ids` - Returns all user IDs from users.yaml
- `get_user_info <id> <field>` - Get user field (email, name, admins)
- `get_user_domain <id>` - Returns `<id>.BASE_DOMAIN`
- `is_user_initialized <id>` - Check if local clone exists
- `is_user_deployed <id>` - Check if infrastructure is deployed

### `scripts/lib/github.sh`
GitHub automation:
- `create_user_repo <id>` - Create GitHub repo from template
- `set_user_repo_secrets <id>` - Configure GitHub secrets
- `setup_user_github <id>` - Full setup (create, secrets, config)

## Coding Conventions

### Bash Scripts
- Use `set -e` for error handling
- Source `lib/common.sh` for shared functions
- Use logging functions: `log_info`, `log_success`, `log_warning`, `log_error`, `log_step`
- Variable naming: `UPPER_CASE` for constants/env, `lower_case` for locals
- Always quote variables: `"$var"` not `$var`

### YAML Parsing
- Requires `yq` CLI tool
- Use `yq -r` for raw output (no quotes)
- Example: `yq -r '.users[].id' users.yaml`

### Naming
- User ID: `id` (not `user_id`, not `student_id`)
- Display name: `name` (not `display_name`)
- Functions: `get_user_*`, `is_user_*`, `setup_user_*`

## Important Notes

1. **No "student" terminology** - Use "user" everywhere (supports trainings, workshops, demos)

2. **Two deployment methods**:
   - Local clones (`instances/` folder) - simple, no GitHub Actions
   - GitHub repos (one per user) - full GitHub Actions support

3. **Admins field** - The `admins` array in users.yaml adds additional Cloudflare Access emails. The primary `email` is always included.

4. **Dependencies**:
   - `yq` - YAML parsing (required)
   - `gh` - GitHub CLI (for GitHub method)
   - `tofu` or `terraform` - Infrastructure
   - `git`, `jq` - Utilities

5. **Secrets** are stored in:
   - `.env` - Local deployment
   - GitHub Secrets - GitHub deployment

## Testing

Before committing changes to scripts:
```bash
# Check syntax
bash -n scripts/*.sh scripts/lib/*.sh

# Test user parsing
source scripts/lib/common.sh
get_user_ids
get_user_info "max-muster" "admins"
```

## Related Projects

- [Nexus-Stack](https://github.com/stefanko-ch/Nexus-Stack) - The underlying infrastructure being deployed
