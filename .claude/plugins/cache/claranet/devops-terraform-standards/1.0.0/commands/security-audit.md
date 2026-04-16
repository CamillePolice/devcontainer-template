# Security Audit Command

Perform a comprehensive security audit of Terraform configurations against Claranet security standards.

## What This Command Does

Scans Terraform code for security issues:
1. **Security groups** - Check for `0.0.0.0/0` exposure
2. **Hardcoded secrets** - Detect credentials in code
3. **Claranet IPs module** - Verify integration for ALBs
4. **Vault usage** - Check secret management
5. **Encryption** - Verify encryption settings
6. **IAM policies** - Check for overly permissive policies

## Workflow

1. **Scan security groups**:
   ```bash
   # Find security group rules with 0.0.0.0/0
   grep -r "0.0.0.0/0" . --include="*.tf"
   ```

2. **Check for hardcoded secrets**:
   - Search for common secret patterns
   - Verify Vault data sources for sensitive data
   - Flag suspicious hardcoded values

3. **Verify Claranet IPs module**:
   ```bash
   # Check if module is defined
   grep -r "module \"claranet_ips\"" . --include="*.tf"
   ```

4. **Audit encryption settings**:
   - S3 bucket encryption
   - RDS encryption at rest
   - EBS volume encryption
   - State file encryption

5. **Review IAM policies**:
   - Check for wildcard permissions (`*`)
   - Verify least privilege principle
   - Flag overly broad resource access

6. **Generate report** with severity levels:
   - 🔴 **CRITICAL** - Must fix immediately
   - 🟡 **WARNING** - Should fix before production
   - 🟢 **INFO** - Best practice recommendations

## Example Output

```
🔒 Security Audit Report
════════════════════════════════════════════

📍 Project: orisha-must-poc-sandbox/sandbox/eu-west-3
🕐 Scan time: 2024-01-15 14:23:45

🔴 CRITICAL ISSUES (2)
────────────────────────────────────────────

1. Open Security Group - ALB exposed to internet
   File:     r-security-groups.tf:45
   Resource: aws_security_group_rule.alb_https

   Issue:
   cidr_blocks = ["0.0.0.0/0"]  # ❌ CRITICAL

   Impact: ALB accessible from entire internet without restriction

   Required Fix:
   - Integrate module "claranet_ips"
   - Replace 0.0.0.0/0 with module.claranet_ips.vpn
   - Add client IPs via variables if needed

   Example:
   ─────────────────
   ingress {
     from_port   = 443
     to_port     = 443
     protocol    = "tcp"
     cidr_blocks = module.claranet_ips.vpn
   }
   ─────────────────

2. Hardcoded Password - Database credentials
   File:     r-rds.tf:78
   Resource: aws_db_instance.main

   Issue:
   password = "MySecretPass123!"  # ❌ CRITICAL

   Impact: Credentials exposed in code and state file

   Required Fix:
   - Move password to Vault
   - Use data.vault_generic_secret

   Example:
   ─────────────────
   data "vault_generic_secret" "db" {
     path = "internal_shared_secret/client/project/database"
   }

   resource "aws_db_instance" "main" {
     password = data.vault_generic_secret.db.data["password"]
   }
   ─────────────────

🟡 WARNINGS (3)
────────────────────────────────────────────

3. Missing S3 Bucket Encryption
   File:     r-s3.tf:12
   Resource: aws_s3_bucket.logs

   Issue: No server-side encryption configured

   Recommendation:
   Add encryption configuration:
   ─────────────────
   resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
     bucket = aws_s3_bucket.logs.id

     rule {
       apply_server_side_encryption_by_default {
         sse_algorithm = "AES256"
       }
     }
   }
   ─────────────────

4. Overly Permissive IAM Policy
   File:     r-iam.tf:25
   Resource: aws_iam_policy.app

   Issue:
   actions = ["s3:*"]  # ⚠️ Too broad

   Recommendation:
   Restrict to specific actions:
   actions = ["s3:GetObject", "s3:PutObject"]

5. RDS Not Encrypted at Rest
   File:     r-rds.tf:45
   Resource: aws_db_instance.app

   Issue: storage_encrypted not set to true

   Recommendation:
   storage_encrypted = true

🟢 INFORMATIONAL (2)
────────────────────────────────────────────

6. Claranet IPs Module - Correctly Integrated
   File:     r-module-claranet-ips.tf:1
   Status:   ✅ Module found and properly configured
   Version:  v1.2.0

7. Vault Integration - Properly Used
   Files:    r-ec2.tf:15, r-rds.tf:23
   Status:   ✅ Secrets accessed via Vault data sources

════════════════════════════════════════════

📊 SUMMARY
────────────────────────────────────────────
Total issues:         7
🔴 Critical:          2  ❌ MUST FIX
🟡 Warnings:          3  ⚠️  SHOULD FIX
🟢 Info:              2  ✅ GOOD PRACTICES

Security Score:       6/10  ⚠️  NEEDS IMPROVEMENT

🎯 TOP PRIORITY FIXES
────────────────────────────────────────────
1. Replace 0.0.0.0/0 with restricted access (r-security-groups.tf:45)
2. Move hardcoded password to Vault (r-rds.tf:78)
3. Enable S3 bucket encryption (r-s3.tf:12)

📋 CHECKLIST
────────────────────────────────────────────
[ ] Fix all CRITICAL issues
[ ] Address WARNING items
[ ] Run trivy scan: mise exec -- trivy config .
[ ] Verify pre-commit hooks pass
[ ] Get security team approval for 0.0.0.0/0 (if required)
```

## Security Checks Performed

### 1. Network Security
- [x] Security groups with `0.0.0.0/0` ingress
- [x] Missing Claranet IPs module for ALB
- [x] Overly permissive security group rules
- [x] Public subnet usage for sensitive resources

### 2. Secrets Management
- [x] Hardcoded passwords/tokens/keys
- [x] Vault integration for sensitive data
- [x] Environment variables in code
- [x] Credentials in variables.tfvars

### 3. Encryption
- [x] S3 bucket encryption
- [x] RDS encryption at rest
- [x] EBS volume encryption
- [x] State file encryption (backend config)

### 4. IAM & Permissions
- [x] Wildcard actions (`*`)
- [x] Wildcard resources (`*`)
- [x] Overly broad permissions
- [x] Missing assume role policies

### 5. Best Practices
- [x] Claranet tagging module usage
- [x] Pre-commit hooks configuration
- [x] .gitignore for sensitive files

## Integration with Other Tools

### Run Trivy After Audit
```bash
mise exec -- trivy config . --severity HIGH,CRITICAL
```

### Check Pre-commit Hooks
```bash
make test
```

### Verify State Encryption
```bash
make check
```

## Severity Levels

| Level | Symbol | Meaning | Action Required |
|-------|--------|---------|-----------------|
| CRITICAL | 🔴 | Security vulnerability | Fix immediately |
| WARNING | 🟡 | Security concern | Fix before production |
| INFO | 🟢 | Best practice | Consider implementing |

## Notes

- Audit runs locally on code, not live infrastructure
- Does not require AWS credentials
- Complements trivy and pre-commit hooks
- Should be run before every deployment
- Results guide security team review
