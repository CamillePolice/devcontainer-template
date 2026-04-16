---
name: adding-rds-prefix-list-access
description: Adds DBA bastion prefix list access to ALL RDS and Aurora security groups using environment-specific AWS managed prefix lists (lzm-glb-bastion-dba-npd-euw3-ipv4 for non-prod, lzm-glb-bastion-dba-prd-euw3-ipv4 for prod). Searches entire codebase for databases, handles both terraform-aws-modules and native resources, ensures module version 5.3.1+. Creates Git branch, modifies ALL database security groups, and generates commit. Use when enabling DBA access to databases in any Terraform project structure.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion, Skill, Task
---

# Adding RDS Prefix List Access

Automates the addition of DBA bastion access to RDS and Aurora databases via AWS Managed Prefix List.

## When to Use

- DBA access to RDS/Aurora databases needed
- Secure bastion access via centralized prefix list required
- Any Terraform project with RDS or Aurora (any structure: stack/, flat, modules/)
- Projects using terraform-aws-modules/security-group/aws OR native aws_security_group resources
- Need to add prefix list access to ALL database security groups in project

**Workflow behavior:**
- Fully automated: Detection and modifications are applied automatically
- Single confirmation point: User validates commit message before committing

## Architecture Overview

DBA bastions access databases via environment-specific AWS Managed Prefix Lists:
- Non-prod: `lzm-glb-bastion-dba-npd-euw3-ipv4`
- Prod: `lzm-glb-bastion-dba-prd-euw3-ipv4`

These prefix lists are referenced by database security groups (RDS/Aurora) to authorize TCP connections on ports 5432 (PostgreSQL) or 3306 (MySQL).

**Key benefits:**
- **Centralized management**: Single resource maintained for all environments
- **Enhanced security**: Access restricted to authorized bastions only
- **Simplicity**: No need to modify security groups when IPs change

## Core Workflow

### Step 1: Prepare Git Repository

**Ask user for project location:**

Determine if this is a local Terraform project or should be cloned from GitLab.

**If GitLab URL provided:**
```bash
git clone <url> <destination>
cd <destination>
```

**For local or cloned project:**

**CRITICAL: Always pull latest changes from main:**
```bash
# Verify we're on main
git checkout main

# MANDATORY: Pull latest changes before creating branch
git pull origin main

# Only after successful pull, create feature branch
git checkout -b feat/add-rds-dba-prefix-list-access
```

**Important:**
- The `git pull origin main` is NOT optional - always execute it
- Wait for pull to complete successfully before creating branch
- If pull fails (conflicts, network issues), resolve before continuing

**Validate Terraform project structure:**
- Verify it's a valid Terraform project (presence of .tf files)
- Identify where data sources are defined (commonly `datas.tf`, `data.tf`, or inline)

### Step 2: Detect Database Configuration

**Automatic adaptive detection - Search entire codebase:**

1. **Search for ALL database resources:**
   - RDS: Find `module.*rds`, `aws_db_instance`, `aws_db_subnet_group`
   - Aurora: Find `module.*aurora`, `aws_rds_cluster`, `aws_rds_cluster_instance`
   - Identify ALL security groups (modules or native resources)
   - Note file paths and resource names

2. **For EACH security group found, analyze:**
   - **If using terraform-aws-modules/security-group/aws:**
     - Check module version (must be >= 5.3.1)
     - Detect port variable pattern (`local.rds_port`, `local.aurora_port`, hardcoded)
     - Check for existing `ingress_with_prefix_list_ids` rules

   - **If using native resources (aws_security_group or aws_security_group_rule):**
     - Note we'll need to research current Terraform AWS provider syntax for prefix lists
     - Identify security group ID references
     - Detect existing ingress rules pattern

3. **Build complete inventory:**
   - List ALL database security groups found
   - Classify each: module vs native resource
   - Note which need version upgrade
   - Identify which already have prefix list rules

**Display inventory and proceed:**

If databases detected:
- Display full inventory: "Detected X RDS and Y Aurora security groups"
- List each security group with its type (module/native), version, and current status
- Proceed directly to Step 3 (no user confirmation needed)

If no databases detected:
- Alert user: "No RDS or Aurora configuration found in project"
- Stop execution

### Step 3: Add or Update Data Source

**Check if data source already exists anywhere in codebase:**

Search for: `aws_ec2_managed_prefix_list.*bastions_dba_euw3`

**Three possible scenarios:**

#### Scenario A: Data source exists with OLD configuration (obsolete single prefix list)

**Detection pattern:**
```hcl
data "aws_ec2_managed_prefix_list" "bastions_dba_euw3" {
  name = "lzm-glb-bastions-dba-euw3-ipv4"
}
```

**Action: MIGRATE to environment-specific configuration**

Replace the old configuration with the new environment-specific version:

**BEFORE (obsolete):**
```hcl
# MAIN
data "aws_ec2_managed_prefix_list" "bastions_dba_euw3" {
  name = "lzm-glb-bastions-dba-euw3-ipv4"
}
```

**AFTER (environment-specific):**
```hcl
# MAIN - DBA Bastion Prefix Lists (environment-specific)
# Non-production environments (dev, tst, chk, acc, ...): lzm-glb-bastion-dba-npd-euw3-ipv4
# Production environment (prd): lzm-glb-bastion-dba-prd-euw3-ipv4
data "aws_ec2_managed_prefix_list" "bastions_dba_euw3" {
  name = local.env == "prd" ? "lzm-glb-bastion-dba-prd-euw3-ipv4" : "lzm-glb-bastion-dba-npd-euw3-ipv4"
}
```

**Migration steps:**
1. Replace entire old data source block (including comments) with new environment-specific configuration
2. Preserve formatting: Match indentation and spacing of the original file
3. Note in commit: This is a migration to environment-specific configuration

**Key changes:**
- Old: Single static name `lzm-glb-bastions-dba-euw3-ipv4` (obsolete)
- New: Conditional based on `local.env` variable
- Benefits: Automatic selection per environment

#### Scenario B: Data source exists with NEW configuration (already migrated)

**Detection pattern:**
```hcl
data "aws_ec2_managed_prefix_list" "bastions_dba_euw3" {
  name = local.env == "prd" ? "lzm-glb-bastion-dba-prd-euw3-ipv4" : "lzm-glb-bastion-dba-npd-euw3-ipv4"
}
```

**Action: SKIP - already configured correctly**
- Inform user: "Data source already uses environment-specific prefix lists"
- Proceed directly to Step 4 (security group modifications)

#### Scenario C: Data source does NOT exist

**Action: ADD new data source**

1. **Find the data sources file:**
   - Check for common patterns: `datas.tf`, `data.tf`, `datasources.tf`
   - If in organized structure (stack/, terraform/), check subdirectories
   - If none exists, create `data.tf` in root or main directory

2. **Add the data source:**
   - Find appropriate position (after other `aws_ec2_managed_prefix_list` data sources if any)
   - Add the following, respecting file formatting:

```hcl
# DBA Bastion Prefix Lists (environment-specific)
# Non-production environments (dev, tst, chk, acc, ...): lzm-glb-bastion-dba-npd-euw3-ipv4
# Production environment (prd): lzm-glb-bastion-dba-prd-euw3-ipv4
data "aws_ec2_managed_prefix_list" "bastions_dba_euw3" {
  name = local.env == "prd" ? "lzm-glb-bastion-dba-prd-euw3-ipv4" : "lzm-glb-bastion-dba-npd-euw3-ipv4"
}
```

**Important notes:**
- Environment-specific names:
  - Non-prod (dev, tst, chk, acc, ...): `lzm-glb-bastion-dba-npd-euw3-ipv4`
  - Production (prd): `lzm-glb-bastion-dba-prd-euw3-ipv4`
- Uses `local.env` variable for conditional selection
- Preserve file indentation style (2 or 4 spaces)
- **Old name `lzm-glb-bastions-dba-euw3-ipv4` is OBSOLETE** - must be replaced

### Step 4: Modify ALL Database Security Groups

**For EACH database security group detected in Step 2 (RDS and Aurora):**

#### A. If using terraform-aws-modules/security-group/aws module:

1. **Check module version:**
   - If version < 5.3.1: MUST upgrade to 5.3.1 (critical bug fixes)
   - If version >= 5.3.1: Keep existing version

2. **Identify:**
   - Port variable used (`local.rds_port`, `local.aurora_port`, or hardcoded)
   - Existing ingress rules structure
   - Presence of `ingress_with_prefix_list_ids` block

**Modification strategy:**

**CRITICAL RULE: NEVER modify existing ingress rules or ports**

**What you MUST do:**
- Add the `ingress_with_prefix_list_ids` block
- Update module version line if < 5.3.1
- Match the port format used in existing rules

**What you MUST NOT do:**
- DO NOT touch `ingress_rules`, `ingress_cidr_blocks`, `computed_ingress_with_cidr_blocks`, `computed_ingress_with_source_security_group_id`, or any existing rule configuration
- DO NOT modify ports in existing rules, even if hardcoded (keep 5432, 3306, etc. as-is)
- DO NOT convert existing rules to different format
- DO NOT "normalize" or "improve" existing rules
- DO NOT replace hardcoded port values with variables in existing rules
- ONLY add the new `ingress_with_prefix_list_ids` block
- Preserve ALL existing code exactly as is, including all port values

**Case 1: Module version < 5.3.1**
- Update ONLY the version line to `5.3.1`
- Do not modify anything else
- Then proceed with Case 2 or 3

**Case 2: `ingress_with_prefix_list_ids` doesn't exist**
- Add complete block AFTER existing ingress configuration
- Leave a blank line before the new block for readability
- Do NOT modify any existing ingress rules

**Case 3: `ingress_with_prefix_list_ids` already exists**
- Check if DBA bastion rule already present
- If not, add new rule to existing list
- Preserve all existing rules in the list

**Pattern to add (ADDITION only, not replacement):**

This block is added TO the existing module, NOT replacing it:

```hcl
  ingress_with_prefix_list_ids = [
    {
      from_port       = local.rds_port  # or local.aurora_port, or hardcoded value matching existing rules
      to_port         = local.rds_port
      protocol        = "tcp"
      description     = "DBA bastion access"
      prefix_list_ids = data.aws_ec2_managed_prefix_list.bastions_dba_euw3.id
    },
  ]
```

**Note:** Use the SAME port format already present in existing ingress rules. If existing rules use `5432` hardcoded, use `5432`. If they use `local.rds_port`, use `local.rds_port`. Match the existing pattern exactly.

**Example - CORRECT approach:**

BEFORE:
```hcl
module "rds_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name = "${var.default_naming}-rds"
  vpc_id = data.aws_vpc.private.id

  ingress_rules = ["postgresql-tcp"]
  ingress_cidr_blocks = [
    data.aws_vpc.private.cidr_block
  ]

  egress_rules = ["all-all"]
}
```

AFTER (CORRECT):
```hcl
module "rds_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name = "${var.default_naming}-rds"
  vpc_id = data.aws_vpc.private.id

  ingress_rules = ["postgresql-tcp"]
  ingress_cidr_blocks = [
    data.aws_vpc.private.cidr_block
  ]

  ingress_with_prefix_list_ids = [
    {
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      description     = "DBA bastion access"
      prefix_list_ids = data.aws_ec2_managed_prefix_list.bastions_dba_euw3.id
    },
  ]

  egress_rules = ["all-all"]
}
```

**Validation before proceeding:**
- Check HCL syntax is valid
- Verify all variables referenced exist
- Ensure indentation is correct
- Confirm module versions
- **Verify existing rules were NOT modified**
- **Verify port values in existing rules were NOT changed**

#### B. If using native resources (aws_security_group or aws_security_group_rule):

1. **Research current Terraform AWS provider syntax:**
   - Use web search or documentation lookup to get current syntax for `aws_security_group_rule` with `prefix_list_ids` parameter
   - Look for how to reference a managed prefix list ID from `data.aws_ec2_managed_prefix_list.bastions_dba_euw3.id`

2. **Apply the documented syntax:**
   - Create aws_security_group_rule resource (or add inline rule depending on pattern found)
   - Reference the security group correctly
   - Use the prefix list data source ID
   - Match the port from database configuration

**Critical: This must be done for ALL database security groups found, not just one.**

### Step 5: Validate and Format Terraform Code

**Before proposing the commit, ensure code quality:**

1. **Format the Terraform code** in the stack directory
2. **Validate the Terraform configuration** to ensure syntax is correct
3. **Stage any files modified** by the formatter
4. **If validation fails**, fix errors before proceeding

**Critical:** Always perform these validation steps before proposing the commit to ensure the code meets quality standards.

### Step 6: Commit Changes

**Use the commit skill:**

MANDATORY : Invoke the commit skill to create a conventional commit message.

**If no commit skill is available:**
- Analyze git status and git diff
- Draft commit message: `feat(security): add DBA prefix list access to RDS/Aurora`
- Include in commit message: "Migrate DBA prefix list to environment-specific configuration" (if migration occurred)

**Note:** This is the ONLY user confirmation required in the entire workflow. All previous steps (detection, data source modification, security group updates, validation) are executed automatically.

**IMPORTANT: Wait for user validation before executing commit.**

Display the generated commit message and ask:
- "Proceed with this commit? (yes/no)"
- If yes: execute `git commit`
- If no: ask user for preferred message or cancel

### Step 7: Summary and Next Steps

**Display structured summary:**

```
========================================
   RDS PREFIX LIST ACCESS - SUMMARY
========================================

Branch: feat/add-rds-dba-prefix-list-access
Project: {project_name}

--- Modifications Applied ---

Data source: {data_source_file}
   - aws_ec2_managed_prefix_list.bastions_dba_euw3
   - {added | migrated | already present}

{for each database security group modified}
Security group: {file_path}
   - Type: {module | native resource}
   - Database: {RDS | Aurora}
   - Module version: {version} (if module)
   - Rule added: ingress_with_prefix_list_ids
   - Port: {port} (via {variable_name or hardcoded})
   - Resource: {module_name or resource_id}
{endfor}

Total security groups modified: {count}

--- Prefix List Details ---

Names (environment-specific):
  - Non-prod (dev, tst, chk, acc, ...): lzm-glb-bastion-dba-npd-euw3-ipv4
  - Production (prd): lzm-glb-bastion-dba-prd-euw3-ipv4
Region: eu-west-3 (Paris)
Management: Centralized by Hermes infrastructure team
Purpose: DBA bastion access to databases

--- Next Steps ---

1. Review changes: git diff
2. Validate compliance: /lz2-review (recommended)
3. Commit approved? -> Execute commit
4. Push: git push origin feat/add-rds-dba-prefix-list-access
5. Create merge request on GitLab

========================================
```

**Offer options to user:**
- Review changes with git diff
- Run /lz2-review for LZV2 compliance check
- Proceed with commit
- Push to remote
- Cancel and rollback

## Adaptive Implementation Guidelines

**CRITICAL: This skill must adapt to existing code, not force a rigid template.**

### Detection Principles

**Always search entire codebase before modifying:**
- Find ALL database security groups in the project
- Don't assume specific file structure (stack/, flat, modules/, etc.)
- Identify patterns used across all found resources
- Build complete inventory before starting modifications

**What to detect:**
- ALL RDS and Aurora security groups (not just first found)
- Type: terraform-aws-modules vs native resources
- Module versions currently used (MUST be >= 5.3.1 for modules)
- Port variable patterns (`local.*_port`, `var.*_port`, hardcoded)
- Indentation style (2 spaces, 4 spaces)
- Naming conventions for resources
- File organization pattern (where to add data sources)

### Adaptation Strategies

**Module vs Native Resources:**
- **For terraform-aws-modules/security-group/aws**: Follow module-based workflow
- **For native resources**: Research current documentation for syntax
- Never assume syntax - always verify for native resources
- Adapt to project's existing pattern (don't convert modules to native or vice versa)

**Module versions:**
- If < 5.3.1: MUST upgrade to 5.3.1 (critical bug fixes for prefix lists)
- If = 5.3.1: Keep as is
- If > 5.3.1: Keep existing (newer is fine)

**Port references:**
- Prefer variables over hardcoded values
- Search for: `local.rds_port`, `local.aurora_port`
- If not found, search: `var.rds_config.port`, `var.aurora_config.port`
- Last resort: use hardcoded 5432 (PostgreSQL) or 3306 (MySQL)
- **Most important:** Match the format used in existing rules

**Indentation and formatting:**
- Detect style from existing files
- Match exact indentation in modifications
- Preserve blank lines and spacing

## Technical Details

### Database Ports

| Database Engine | Default Port | Variable Pattern |
|-----------------|--------------|------------------|
| PostgreSQL | 5432 | `local.rds_port` |
| Aurora PostgreSQL | 5432 | `local.aurora_port` |
| MySQL | 3306 | `local.rds_port` |
| Aurora MySQL | 3306 | `local.aurora_port` |

## Validation Checklist

Before finalizing, verify:
- [ ] ALL database security groups detected and processed (none skipped)
- [ ] Module versions 5.3.1+ OR native syntax researched
- [ ] **CRITICAL: Existing ingress rules and ports preserved unchanged**
- [ ] New `ingress_with_prefix_list_ids` block added with port format matching existing rules
- [ ] Terraform format and validate executed successfully

## Common Issues and Solutions

**Issue: Existing ingress rules were modified instead of preserved**
- WRONG: Converting `ingress_rules` to `computed_ingress_with_cidr_blocks` or changing port values
- CORRECT: Leave ALL existing rules and ports untouched, only ADD `ingress_with_prefix_list_ids` block

**Issue: Determining which port format to use in new prefix list rule**
- Solution: Inspect existing ingress rules in the same security group and match their format (hardcoded vs variable)

**Issue: Module version < 5.3.1**
- Solution: MUST upgrade to 5.3.1 (critical bug fixes for prefix lists), document in commit

**Issue: Native resources (aws_security_group or aws_security_group_rule)**
- Solution: Research current Terraform AWS provider syntax for `prefix_list_ids`, never assume
