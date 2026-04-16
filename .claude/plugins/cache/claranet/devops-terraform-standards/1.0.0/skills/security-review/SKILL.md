---
name: security-review
description: Enforces Claranet security best practices for Terraform infrastructure. Use when creating ALBs, security groups, or handling sensitive data
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
  - AskUserQuestion
---

# Security & Best Practices (Claranet)

Apply Claranet's mandatory security requirements for all Terraform infrastructure.

## Application Load Balancer Security (CRITICAL)

**CRITICAL SECURITY REQUIREMENT**: All ALBs MUST restrict access by default.

**NEVER use `0.0.0.0/0` without explicit security team approval.**

### Mandatory ALB Security Process

1. **Default Restriction**: Always restrict to specific IP ranges
2. **Claranet IPs Module**: Use for Claranet VPN access
3. **Client IPs**: Define in variables for client access
4. **No Internet-Wide Access**: `0.0.0.0/0` requires security approval

### Required Module Integration

```hcl
# r-module-claranet-ips.tf
module "claranet_ips" {
  source = "git::ssh://git@git.fr.clara.net/claranet/ops4ops/ops4ops/projects/terraform-claranet-ip-module.git?ref=v1.3.0"
}
```

### Security Group Best Practices

```hcl
# CORRECT - Restricted access
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "ALB security group with restricted access"
  vpc_id      = var.vpc_id

  # Claranet VPN access
  ingress {
    description = "HTTPS from Claranet VPN IPs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = module.claranet_ips.vpn  # NOT ["0.0.0.0/0"]
  }

  # Client-specific access
  ingress {
    description = "HTTPS from Client IPs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.client_allowed_ips
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# INCORRECT - Open to internet
resource "aws_security_group" "bad_alb" {
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # ❌ NEVER without approval
  }
}
```

### Client Access Variables

```hcl
# variables.tf
variable "client_allowed_ips" {
  description = "List of client IP ranges allowed to access ALB"
  type        = list(string)
  default     = []
}

# variables.auto.tfvars
client_allowed_ips = [
  "203.0.113.0/24",   # Client office network
  "198.51.100.0/24"   # Client VPN network
]
```

### Access Approval Process

| Access Type | Approval Required | Implementation |
|-------------|-------------------|----------------|
| **Claranet Access** | ✅ Always allowed | `module.claranet_ips.vpn` |
| **Client Access** | ✅ Document in variables | `var.client_allowed_ips` |
| **Internet Access** | ❌ Security team approval | Contact security team |
| **Emergency Access** | ❌ Justified business case | Temporary with ticket |

## Secrets Management

**CRITICAL**: Use HashiCorp Vault for ALL sensitive data.

### Vault Integration

```hcl
# CORRECT - Vault secrets
data "vault_generic_secret" "db_password" {
  path = "internal_shared_secret/client-id/project-id/database"
}

resource "aws_db_instance" "main" {
  password = data.vault_generic_secret.db_password.data["password"]
}

data "vault_generic_secret" "ssh_keys" {
  path = "internal_shared_secret/client-id/project-id/ssh-keys"
}

resource "aws_instance" "bastion" {
  key_name = data.vault_generic_secret.ssh_keys.data["key_name"]
}
```

**Vault Configuration:**
- Endpoint: `https://vault.fr.clara.net`
- Path pattern: `internal_shared_secret/<client_id>/<project_id>/<secret_type>`
- Encryption keys: Managed via mise configuration

### What to NEVER Commit

❌ **NEVER commit:**
- Private keys (`.pem`, `.key`, `.crt`)
- Credentials files (`credentials.json`, `.env`)
- Hardcoded passwords or tokens
- AWS access keys
- SSH private keys
- TLS/SSL certificates

✅ **Use .gitignore:**
```gitignore
# Secrets and sensitive files
*.pem
*.key
*.crt
credentials.json
.env
.env.*
*_rsa
*_ed25519
terraform.tfvars  # If contains sensitive data
```

## Pre-commit Hooks

**MANDATORY**: All changes must pass these checks before commit.

### Required Hooks

1. **Terraform formatting** (`terraform fmt`)
2. **Terraform linting** (tflint - recursive, uses `.tflint.hcl`)
3. **Security scanning** (trivy - HIGH/CRITICAL severity)
4. **AWS credentials detection**
5. **Private key detection**
6. **YAML/JSON validation**
7. **Editorconfig compliance**

### Running Pre-commit Hooks

```bash
# Install hooks (one-time setup)
make install

# Run all hooks manually
make test

# Hooks run automatically on git commit
git commit -m "feat: add new resource"
```

### Security Scanning with Trivy

```bash
# Manual trivy scan
mise exec -- trivy config . --severity HIGH,CRITICAL
```

**Common trivy findings:**
- Unencrypted S3 buckets
- Open security groups
- Missing encryption keys
- Weak IAM policies
- Public access enabled

## State Encryption

**MANDATORY**: Terraform state MUST be encrypted.

### S3 Backend with Encryption

```hcl
terraform {
  backend "s3" {
    bucket = "terraform-state-bucket"
    key    = "project/terraform.tfstate"
    region = "eu-west-3"
    encrypt = true
    # Encryption key managed via Vault
  }
}
```

**Key management:**
- Keys stored in Vault
- Retrieved automatically via mise
- Path: `internal_shared_secret/<client_id>/<project_id>/terraform`

**Check encryption:**
```bash
# Verify AWS_SSE_CUSTOMER_KEY is set
make check
```

## Resource Tagging

**MANDATORY**: Use Claranet Cloud Tagging Policy.

**Implementation:**
- Tagging automatically handled via project templates
- Uses Claranet tagging module
- DO NOT manually implement tagging

**Standard tags include:**
- Client identifier
- Project name
- Environment (sandbox/preprod/prod)
- Managed by (Terraform)
- SynApps identifiers

## Network Security

### VPC Best Practices

```hcl
# Enable DNS hostnames and support
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Private subnets for sensitive resources
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = false  # ✅ Private subnet
}

# Public subnets for load balancers only
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.101.0/24"
  map_public_ip_on_launch = true
}
```

### Security Group Rules

**Principle of least privilege:**
```hcl
# CORRECT - Specific ports and sources
resource "aws_security_group_rule" "app" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id = aws_security_group.app.id
}

# INCORRECT - Overly permissive
resource "aws_security_group_rule" "bad" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535  # ❌ All ports
  protocol          = "-1"    # ❌ All protocols
  cidr_blocks       = ["0.0.0.0/0"]  # ❌ All sources
  security_group_id = aws_security_group.app.id
}
```

## Encryption Standards

### S3 Bucket Encryption

```hcl
# CORRECT - Encrypted by default
resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

### RDS Encryption

```hcl
# CORRECT - Encrypted at rest
resource "aws_db_instance" "main" {
  storage_encrypted = true
  kms_key_id        = aws_kms_key.db.arn
}
```

### EBS Encryption

```hcl
# CORRECT - Encrypted volumes
resource "aws_instance" "example" {
  root_block_device {
    encrypted = true
  }
}
```

## IAM Best Practices

### Least Privilege

```hcl
# CORRECT - Specific permissions
data "aws_iam_policy_document" "app" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.app.arn}/*"
    ]
  }
}

# INCORRECT - Wildcard permissions
data "aws_iam_policy_document" "bad" {
  statement {
    actions   = ["s3:*"]  # ❌ Too broad
    resources = ["*"]     # ❌ All resources
  }
}
```

## Security Checklist

Before deploying infrastructure, verify:

- [ ] ALB security groups restricted (no 0.0.0.0/0 without approval)
- [ ] Claranet IPs module integrated
- [ ] All secrets in Vault (no hardcoded values)
- [ ] State encryption enabled
- [ ] Pre-commit hooks configured and passing
- [ ] Trivy scan shows no HIGH/CRITICAL issues
- [ ] No sensitive files in git
- [ ] IAM policies follow least privilege
- [ ] S3 buckets encrypted
- [ ] RDS databases encrypted
- [ ] Security groups follow principle of least privilege
- [ ] Tagging module integrated

## Incident Response

**If security issue detected:**
1. **Stop deployment** immediately
2. **Document the issue** with screenshots
3. **Contact security team** via appropriate channel
4. **Do not proceed** without approval
5. **Update code** per security team guidance

## Common Security Violations

1. **Open ALB to internet** - Use Claranet IPs module
2. **Hardcoded secrets** - Use Vault
3. **Unencrypted state** - Enable S3 encryption
4. **Private keys in repo** - Add to .gitignore
5. **Overly permissive IAM** - Apply least privilege
6. **Unencrypted data stores** - Enable encryption
7. **Public S3 buckets** - Block public access
