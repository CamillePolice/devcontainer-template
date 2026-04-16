---
name: terraform-coding
description: Applies Claranet Terraform/OpenTofu coding standards when working with .tf files or infrastructure code
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
---

# Terraform Coding Standards (Claranet)

Apply Claranet's Terraform/OpenTofu coding standards for all infrastructure code.

## File Naming Conventions

**MANDATORY file prefixes:**
- `d-xxx.tf` - Data sources (e.g., `d-vpc.tf`, `d-ami.tf`)
- `r-xxx.tf` - Resources (e.g., `r-ec2.tf`, `r-rds.tf`)
- `l-xxx.tf` - Locals (e.g., `l-common.tf`, `l-network.tf`)

**Alternative grouping files (acceptable):**
- `data-sources.tf` - All data sources grouped
- `locals.tf` - All locals grouped

## Variable Management

**Declaration and Definition:**
- Declare variables in `variables.tf`
- Define values in `variables.auto.tfvars` (automatically loaded)
- Support file splitting: `variables-xxx.tf` + `variables-xxx.auto.tfvars`

**Required Base Variables (every stack):**
```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "aws_account" {
  description = "Account name in SynApps"
  type        = string
}

variable "client_name" {
  description = "Client identifier"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "synapps_client_id" {
  description = "SynApps client identifier"
  type        = string
}

variable "synapps_project_id" {
  description = "SynApps project identifier"
  type        = string
}

variable "synapps_tooling_project_id" {
  description = "SynApps tooling project identifier"
  type        = string
}
```

## Resource Naming Standards

**Pattern:**
```
<client>-<project>-<region-short>-<env>-<resource-type>[-suffix]
```

**Example:**
```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "acme-platform-euw3-prod-vpc-main"
  }
}
```

## Tool Management

**CRITICAL**: This project uses `mise` for tool management. All OpenTofu/Terraform commands MUST use `mise exec --`:

```bash
mise exec -- tofu init
mise exec -- tofu plan
mise exec -- tofu apply
```

**Why mise exec is required:**
- Tools are NOT installed globally
- `tofu` command is not in PATH
- `mise exec --` activates project environment
- Ensures version consistency

## MANDATORY Testing Workflow

**CRITICAL**: After creating/modifying ANY .tf file, you MUST run this sequence:

```bash
# 0. Format code (must not modify files if already formatted)
mise exec -- tofu fmt

# 1. Initialize (downloads providers, modules)
mise exec -- tofu init

# 2. Validate syntax
mise exec -- tofu validate

# 3. Plan changes
mise exec -- tofu plan
```

**Success Criteria:**
- `tofu fmt` - No files modified (code already formatted)
- `tofu init` - Completes without errors
- `tofu validate` - Returns "Success! The configuration is valid"
- `tofu plan` - Executes successfully (even if shows planned changes)

**NEVER consider code complete until all 4 steps pass.**

## Remote State Access

**Standard remote states:**
```hcl
# Access network infrastructure
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "terraform-state-bucket"
    key    = "network/terraform.tfstate"
    region = var.aws_region
  }
}

# Access shared services
data "terraform_remote_state" "services" {
  backend = "s3"
  config = {
    bucket = "terraform-state-bucket"
    key    = "services/terraform.tfstate"
    region = var.aws_region
  }
}
```

## Secrets Management

**CRITICAL**: Use HashiCorp Vault for sensitive data:

```hcl
# CORRECT - Vault secret
data "vault_generic_secret" "ssh_key" {
  path = "internal_shared_secret/client/project/ssh-keys"
}

resource "aws_instance" "example" {
  key_name = data.vault_generic_secret.ssh_key.data["key_name"]
}
```

**NEVER:**
- Commit private keys
- Hardcode secrets in .tf files
- Commit sensitive files (credentials, .pem, .key)

## Architecture Patterns

**Multi-stack structure:**
```
common/                           # Shared configuration
network/<region>/                 # Network infrastructure
services/<region>/                # Shared services
<client>-<project>-{env}/{env}/<region>/  # Environment-specific
```

**State management:**
- Backend: AWS S3
- Encryption: Vault-managed keys
- Endpoint: `https://vault.fr.clara.net`

## Tagging

**MANDATORY**: Use Claranet Cloud Tagging Policy via Claranet tagging module (automatically integrated in templates).

## Workflow

1. **Before writing code**: Check existing patterns in the codebase
2. **While writing**: Follow file naming, variable, and resource naming standards
3. **After writing**: Run mandatory test sequence (fmt → init → validate → plan)
4. **Before committing**: Ensure all tests pass and pre-commit hooks succeed

## Common Mistakes to Avoid

- Creating files without proper prefix (d-, r-, l-)
- Missing required base variables
- Not using mise exec for tofu commands
- Hardcoding secrets instead of using Vault
- Skipping the mandatory test workflow
- Using version ranges for modules (use exact pinning)
- Not following resource naming pattern
