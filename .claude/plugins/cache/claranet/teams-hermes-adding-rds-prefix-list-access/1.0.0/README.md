# Adding RDS Prefix List Access

Plugin for automating DBA bastion access to RDS and Aurora databases via AWS Managed Prefix Lists.

## Overview

This plugin provides a skill that automates the addition of DBA bastion access to RDS and Aurora security groups in Terraform projects. It uses environment-specific AWS Managed Prefix Lists to authorize database connections from DBA bastions.

## Features

- Automatic detection of all RDS and Aurora security groups in a project
- Support for both `terraform-aws-modules/security-group/aws` and native AWS resources
- Environment-specific prefix list selection (prod vs non-prod)
- Module version validation and upgrade (requires >= 5.3.1)
- Preserves existing ingress rules while adding new prefix list access

## Prefix Lists

| Environment | Prefix List Name |
|-------------|------------------|
| Non-prod (dev, tst, chk, acc, ...) | `lzm-glb-bastion-dba-npd-euw3-ipv4` |
| Production (prd) | `lzm-glb-bastion-dba-prd-euw3-ipv4` |

## Usage

The skill is automatically triggered when you need to:
- Add DBA access to RDS/Aurora databases
- Configure secure bastion access via centralized prefix list
- Add prefix list access to database security groups

## Workflow

1. Prepare Git repository (clone or use local project)
2. Detect all database configurations in the codebase
3. Add or update the prefix list data source
4. Modify all database security groups
5. Validate and format Terraform code
6. Commit changes with conventional commit message

## Requirements

- Terraform project with RDS or Aurora databases
- `local.env` variable for environment detection
- Module version >= 5.3.1 for terraform-aws-modules/security-group/aws
