---
name: module-discovery
description: Enforces Claranet module discovery policy using Context7 MCP for terraform-aws-modules and terraform-google-modules. Use when creating AWS/GCP resources or working with Terraform modules
allowed-tools:
  - mcp__context7__resolve-library-id
  - mcp__context7__get-library-docs
  - Read
  - Grep
  - Glob
  - AskUserQuestion
---

# Module Discovery & Version Management (Claranet)

**MANDATORY**: Before writing ANY custom AWS/GCP resources, you MUST search for existing modules.

## Module Search Process (MANDATORY)

### Step 1: Search via Context7 MCP (PRIORITY)

**Before implementing ANY AWS/GCP resource, search for modules:**

```bash
# Example: Looking for AWS ALB module
mcp__context7__resolve-library-id --libraryName "terraform-aws-modules/alb/aws"

# Get documentation and latest version
mcp__context7__get-library-docs --context7CompatibleLibraryID "/terraform-aws-modules/terraform-aws-alb" --topic "latest version requirements"

# Example: Looking for GCP VPC module
mcp__context7__resolve-library-id --libraryName "terraform-google-modules/network/google"

# Get documentation and latest version
mcp__context7__get-library-docs --context7CompatibleLibraryID "/terraform-google-modules/terraform-google-network" --topic "latest version requirements"
```

**Context7 provides:**
- Real-time access to latest module versions
- Comprehensive code examples
- Best practices and usage patterns
- Automated discovery of terraform-aws-modules and terraform-google-modules

### Step 2: Module Priority Order

1. **terraform-aws-modules** (PRIORITY for AWS)
   - Official AWS community modules
   - Use ALWAYS when available for AWS resources
   - Access via Context7 for latest versions
   - Source: `https://github.com/terraform-aws-modules`
   - Registry: `https://registry.terraform.io/namespaces/terraform-aws-modules`

2. **terraform-google-modules** (PRIORITY for GCP)
   - Official GCP community modules
   - Use ALWAYS when available for GCP resources
   - Access via Context7 for latest versions
   - Source: `https://github.com/terraform-google-modules`
   - Registry: `https://registry.terraform.io/namespaces/terraform-google-modules`

3. **Claranet Modules**
   - Internal Claranet-developed modules
   - Source: `git::https://git.fr.clara.net/claranet/...`

4. **Authorized Third-Party**
   - `aws-lambda-scheduler-stop-start` (EC2/RDS/ASG scheduling)

5. **Custom Resources**
   - ONLY when no suitable module exists
   - Requires justification

### Step 3: Module Selection Criteria

**Use a module when:**
- Covers 70%+ of requirements
- Simplifies 5+ resource configurations
- Follows AWS best practices
- Well-maintained and documented

**Write custom resources when:**
- No module covers the use case
- Module is overcomplicated for simple needs
- Specific requirements not supported

## Version Pinning (MANDATORY)

**ALWAYS use exact version pinning:**

```hcl
# CORRECT - Exact version
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"
}

# INCORRECT - Version ranges
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1"  # ❌ NEVER use ~>
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 5.0"  # ❌ NEVER use >=
}
```

**Why exact pinning:**
- Ensures reproducible infrastructure
- Prevents unexpected breaking changes
- Aligns with Claranet stability requirements

## Module Discovery Workflow

### When Creating New Resources

1. **Identify the AWS service** (e.g., VPC, ALB, RDS, EC2)
2. **Search via Context7**:
   ```bash
   mcp__context7__resolve-library-id --libraryName "terraform-aws-modules/<service>/aws"
   ```
3. **Get latest version and docs**:
   ```bash
   mcp__context7__get-library-docs --context7CompatibleLibraryID "/terraform-aws-modules/terraform-aws-<service>" --topic "latest version"
   ```
4. **Review examples** from Context7 documentation
5. **Implement with exact version** from Context7
6. **Test with** `mise exec -- tofu init -upgrade`

### When Updating Existing Modules

1. **Check current version** in your .tf files
2. **Query Context7** for latest stable version
3. **Review changelog** for breaking changes
4. **Update to exact latest version**
5. **Test thoroughly** with `tofu plan`

## Approved Module Sources

### terraform-aws-modules (Priority)

**Common modules to use:**
- `terraform-aws-modules/vpc/aws` - VPC and networking
- `terraform-aws-modules/ec2-instance/aws` - EC2 instances
- `terraform-aws-modules/rds/aws` - RDS databases
- `terraform-aws-modules/alb/aws` - Application Load Balancers
- `terraform-aws-modules/security-group/aws` - Security groups
- `terraform-aws-modules/s3-bucket/aws` - S3 buckets
- `terraform-aws-modules/iam/aws` - IAM roles and policies
- `terraform-aws-modules/eks/aws` - EKS clusters

**Always check Context7 for:**
- Latest versions
- Breaking changes
- New features
- Usage examples

### terraform-google-modules (Priority for GCP)

**Common modules to use:**
- `terraform-google-modules/network/google` - VPC and networking
- `terraform-google-modules/vm/google` - Compute Engine instances
- `terraform-google-modules/sql-db/google` - Cloud SQL databases
- `terraform-google-modules/lb-http/google` - HTTP(S) Load Balancers
- `terraform-google-modules/cloud-storage/google` - Cloud Storage buckets
- `terraform-google-modules/iam/google` - IAM roles and policies
- `terraform-google-modules/kubernetes-engine/google` - GKE clusters
- `terraform-google-modules/project-factory/google` - Project creation and setup

**Always check Context7 for:**
- Latest versions
- Breaking changes
- New features
- Usage examples

**Registry:** `https://registry.terraform.io/namespaces/terraform-google-modules`

### Claranet Modules

**Source pattern:**
```hcl
module "example" {
  source = "git::ssh://git@git.fr.clara.net/claranet/ops4ops/terraform/modules/<module-name>.git?ref=v1.0.0"
}
```

**Common Claranet modules:**
- Tagging module (automatically integrated)
- Custom networking patterns
- Client-specific modules

### Claranet IPs Module (Security)

**MANDATORY for ALB/Security Groups:**
```hcl
module "claranet_ips" {
  source = "git::ssh://git@git.fr.clara.net/claranet/ops4ops/ops4ops/projects/terraform-claranet-ip-module.git?ref=v1.3.0"
}

# Use in security groups
resource "aws_security_group_rule" "vpn_access" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = module.claranet_ips.vpn
  security_group_id = aws_security_group.alb.id
}
```

## Module Approval Process

**Modules NOT in approved list require:**
1. Architectural review
2. Lead tech approval
3. Documentation of justification
4. Security assessment

**NEVER use unapproved modules without explicit approval.**

## Context7 Integration Examples

### Example 1: Finding VPC Module

```bash
# Step 1: Resolve library ID
mcp__context7__resolve-library-id --libraryName "terraform-aws-modules/vpc/aws"

# Step 2: Get latest version and docs
mcp__context7__get-library-docs --context7CompatibleLibraryID "/terraform-aws-modules/terraform-aws-vpc" --topic "version and basic usage"

# Step 3: Implement with exact version from Context7
```

### Example 2: Updating Existing Module

```bash
# Query for updates
mcp__context7__get-library-docs --context7CompatibleLibraryID "/terraform-aws-modules/terraform-aws-alb" --topic "latest version and changelog"

# Review changes and update version in .tf file
```

### Example 3: Finding GCP Network Module

```bash
# Step 1: Resolve library ID for GCP
mcp__context7__resolve-library-id --libraryName "terraform-google-modules/network/google"

# Step 2: Get latest version and docs
mcp__context7__get-library-docs --context7CompatibleLibraryID "/terraform-google-modules/terraform-google-network" --topic "version and basic usage"

# Step 3: Implement with exact version from Context7
```

### Example 4: GCP Cloud SQL Module

```bash
# Search for GCP Cloud SQL module
mcp__context7__resolve-library-id --libraryName "terraform-google-modules/sql-db/google"

# Get implementation examples
mcp__context7__get-library-docs --context7CompatibleLibraryID "/terraform-google-modules/terraform-google-sql-db" --topic "mysql postgresql examples"
```

## Best Practices

1. **Always search Context7 first** before writing custom resources (AWS and GCP)
2. **Use exact version pinning** (never ranges)
3. **Prioritize official community modules** (terraform-aws-modules or terraform-google-modules)
4. **Test module compatibility** with `tofu init -upgrade`
5. **Document module choices** in comments when custom code is needed
6. **Keep modules updated** but test thoroughly
7. **Follow module examples** from Context7 documentation
8. **Use Claranet IPs module** for security groups (AWS)
9. **Check both AWS and GCP registries** depending on cloud provider

## Common Mistakes to Avoid

- Writing custom AWS/GCP resources without checking for modules
- Using version ranges (`~>`, `>=`)
- Not using Context7 to find latest versions
- Using unapproved third-party modules
- Skipping the Claranet IPs module for security groups (AWS)
- Not testing after module version updates
- Forgetting to check terraform-google-modules for GCP resources
- Mixing SSH and HTTPS sources (prefer HTTPS: `git::https://`)
