# Terraform Standards Plugin

Claranet's comprehensive Terraform/OpenTofu standards, module discovery, and security best practices plugin for Claude Code.

## Overview

This plugin enforces Claranet's Terraform/OpenTofu development standards across all infrastructure projects. It provides automated guidance for:

- **Coding Standards** - File naming, variables, resource naming, testing workflows
- **Module Discovery** - Context7 MCP integration for terraform-aws-modules discovery
- **Security Best Practices** - ALB restrictions, Vault integration, encryption standards

## Features

### 🎯 Skills (Automatic Activation)

#### 1. Terraform Coding Standards
**Activates when:** Working with `.tf` files or mentioning "terraform"/"opentofu"

**Provides:**
- File naming conventions (`d-*.tf`, `r-*.tf`, `l-*.tf`)
- Variable management standards
- Resource naming patterns
- Mandatory testing workflow (fmt → init → validate → plan)
- Tool management via `mise exec`

#### 2. Module Discovery & Version Management
**Activates when:** Creating AWS resources or working with modules

**Provides:**
- Automated module search via Context7 MCP
- Priority order: terraform-aws-modules → Claranet → Custom
- Exact version pinning enforcement
- Real-time access to latest module versions
- Module approval process guidance

#### 3. Security & Best Practices
**Activates when:** Creating ALBs, security groups, or handling sensitive data

**Provides:**
- ALB restriction enforcement (no `0.0.0.0/0` without approval)
- Claranet IPs module integration
- Vault-based secrets management
- Encryption standards (S3, RDS, EBS, state)
- IAM least privilege policies

### ⚡ Slash Commands

#### `/terraform-validate`
Execute complete validation sequence for current stack.

**What it does:**
1. Format code (`mise exec -- tofu fmt`)
2. Initialize (`mise exec -- tofu init`)
3. Validate (`mise exec -- tofu validate`)
4. Plan (`mise exec -- tofu plan`)

**Use when:**
- After creating/modifying `.tf` files
- Before committing changes
- As part of code review

**Example:**
```bash
/terraform-validate
```

#### `/check-modules`
Audit modules against Claranet standards and check for updates via Context7.

**What it does:**
1. Scan all modules in project
2. Verify source compliance (approved sources)
3. Check version pinning (exact vs ranges)
4. Query Context7 for latest versions
5. Flag unapproved modules

**Use when:**
- Before deploying infrastructure
- During security reviews
- Checking for module updates

**Example:**
```bash
/check-modules
```

#### `/security-audit`
Comprehensive security audit of Terraform configurations.

**What it does:**
1. Scan for `0.0.0.0/0` exposure
2. Detect hardcoded secrets
3. Verify Claranet IPs module integration
4. Check encryption settings
5. Audit IAM policies

**Use when:**
- Before production deployment
- After security-sensitive changes
- Regular security reviews

**Example:**
```bash
/security-audit
```

## Installation

### Prerequisites

- Claude Code installed
- Access to Claranet's GitLab repository
- Project with Terraform/OpenTofu code

### Add DevOps Marketplace

#### Option 1: Via Claude Code UI

1. Open Claude Code
2. Run `/plugin` command
3. Select "Add Marketplace"
4. Add URL: `git@git.fr.clara.net:claranet/projects/ai/claude-code.git:plugins/devops`

#### Option 2: Via Settings File

Add to `~/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "claranet-devops": {
      "source": {
        "source": "git",
        "url": "git@git.fr.clara.net:claranet/projects/ai/claude-code.git",
        "path": "plugins/devops"
      }
    }
  },
  "enabledPlugins": {
    "terraform-standards@claranet-devops": true
  }
}
```

#### Option 3: Local Development

For testing locally before pushing:

```json
{
  "extraKnownMarketplaces": {
    "claranet-devops-local": {
      "source": {
        "source": "directory",
        "path": "/path/to/claude-code/plugins/devops"
      }
    }
  },
  "enabledPlugins": {
    "terraform-standards@claranet-devops-local": true
  }
}
```

### Enable the Plugin

After adding the marketplace, enable the plugin:

```bash
# Via Claude Code UI
/plugin

# Then select "terraform-standards" and enable it
```

## Usage Examples

### Example 1: Creating New Infrastructure

```typescript
User: "I need to create a VPC for the sandbox environment"

Claude (with plugin):
- Automatically searches Context7 for terraform-aws-modules/vpc/aws
- Retrieves latest version (e.g., 5.5.1)
- Provides implementation with exact version pinning
- Follows Claranet naming standards
- Includes required base variables
- Runs validation workflow after creation
```

### Example 2: Security Review

```bash
# After modifying security groups
/security-audit

# Plugin scans and reports:
# ✅ Claranet IPs module properly integrated
# ⚠️  RDS encryption missing
# 🔴 CRITICAL: ALB exposed to 0.0.0.0/0
```

### Example 3: Module Updates

```bash
# Check for module updates
/check-modules

# Plugin reports:
# ✅ 5 modules up to date
# 🔄 VPC module update available: 5.1.2 → 5.5.1
# ⚠️  RDS module using version range (fix required)
```

## Standards Enforced

### File Naming
- `d-*.tf` - Data sources
- `r-*.tf` - Resources
- `l-*.tf` - Locals
- `variables.tf` + `variables.auto.tfvars`

### Resource Naming Pattern
```
<client>-<project>-<region-short>-<env>-<resource-type>[-suffix]
```

### Required Base Variables
- `aws_region`
- `aws_account`
- `client_name`
- `project_name`
- `synapps_client_id`
- `synapps_project_id`
- `synapps_tooling_project_id`

### Module Policy
1. **Search first** - Always check for existing modules via Context7
2. **Prioritize** - terraform-aws-modules → Claranet → Custom
3. **Pin exactly** - Use `version = "5.5.1"`, not `version = "~> 5.5"`
4. **Get approval** - Unapproved modules require review

### Security Requirements
- **ALB**: Restrict access, use Claranet IPs module
- **Secrets**: Via Vault only (`data.vault_generic_secret`)
- **Encryption**: S3, RDS, EBS, state files
- **IAM**: Least privilege principle

### Testing Workflow
1. `mise exec -- tofu fmt`
2. `mise exec -- tofu init`
3. `mise exec -- tofu validate`
4. `mise exec -- tofu plan`

## Context7 Integration

This plugin integrates with Context7 MCP for real-time access to terraform-aws-modules:

**Benefits:**
- Latest module versions
- Comprehensive documentation
- Code examples and best practices
- Automated module discovery

**Usage:**
The plugin automatically uses Context7 when searching for modules. No manual configuration required.

## Troubleshooting

### Plugin Not Activating

**Check enabled plugins:**
```bash
/plugin
```

Ensure `terraform-standards@claranet-devops` is enabled.

### Skills Not Triggering

**Skills activate on:**
- `.tf` file presence
- Keywords: "terraform", "opentofu", "module", "security group"
- Slash commands execution

### Context7 Unavailable

If Context7 MCP is not available:
- Module discovery still works (manual GitHub search)
- Version checking limited
- Update suggestions unavailable

### mise exec Commands Failing

**Verify mise installation:**
```bash
mise --version
```

**Check mise.toml exists:**
```bash
cat mise.toml
```

## Support

### Internal Resources
- **Documentation**: Claranet Confluence - Terraform Standards
- **GitLab**: `git@git.fr.clara.net:claranet/projects/ai/claude-code.git`
- **Issues**: Create issue in GitLab repository

### Common Questions

**Q: Do I need Context7 MCP?**
A: Highly recommended for terraform-aws-modules discovery, but plugin works without it.

**Q: Can I use this with Terraform Cloud?**
A: Yes, standards apply regardless of backend.

**Q: Does this work with existing projects?**
A: Yes, plugin provides guidance for both new and existing projects.

**Q: How do I update the plugin?**
A: Plugin auto-updates from GitLab marketplace when changes are pushed.

## Contributing

This plugin is maintained by Claranet's DevOps team.

**To contribute:**
1. Clone repository: `git@git.fr.clara.net:claranet/projects/ai/claude-code.git`
2. Create feature branch
3. Update plugin files in `plugins/devops/terraform-standards/`
4. Test locally using directory source
5. Submit merge request

## License

Internal Use - Claranet

## Changelog

### v1.0.0 (2024-01-15)
- Initial release
- 3 skills: coding standards, module discovery, security
- 3 slash commands: validate, check-modules, security-audit
- Context7 MCP integration for terraform-aws-modules
- Comprehensive security auditing
