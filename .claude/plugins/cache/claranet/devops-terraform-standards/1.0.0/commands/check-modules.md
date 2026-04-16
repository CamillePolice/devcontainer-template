# Check Modules Command

Audit Terraform modules against Claranet standards and suggest updates via Context7.

## What This Command Does

Analyzes all Terraform modules in the project and verifies:
1. **Source compliance** - Checks against approved module sources
2. **Version pinning** - Ensures exact version pinning (no `~>` or `>=`)
3. **Available updates** - Queries Context7 for latest versions
4. **Unapproved modules** - Flags modules requiring approval

## Workflow

1. **Discover modules**:
   ```bash
   # Find all module blocks in .tf files
   grep -r "module \"" . --include="*.tf"
   ```

2. **Extract module information**:
   - Module name
   - Source URL/path
   - Current version
   - Usage location (file:line)

3. **Verify against standards**:
   - Check if source is approved (terraform-aws-modules, Claranet, authorized)
   - Verify exact version pinning (not ranges)
   - Identify deprecated or outdated modules

4. **Query Context7 for updates** (terraform-aws-modules only):
   ```bash
   # For each terraform-aws-modules module
   mcp__context7__resolve-library-id --libraryName "terraform-aws-modules/<module>/aws"
   mcp__context7__get-library-docs --context7CompatibleLibraryID "<id>" --topic "latest version"
   ```

5. **Generate report**:
   - Approved modules (✅)
   - Modules with updates available (🔄)
   - Version pinning issues (⚠️)
   - Unapproved modules (❌)

## Approved Module Sources

### Priority 1: terraform-aws-modules
- Source pattern: `terraform-aws-modules/<module>/aws`
- Version: Exact pinning required
- Updates: Check via Context7

### Priority 2: Claranet Modules
- Source pattern: `git::ssh://git@git.fr.clara.net/claranet/...`
- Version: Git ref required (`?ref=v1.0.0`)

### Priority 3: Authorized Third-Party
- `aws-lambda-scheduler-stop-start`

## Example Output

```
🔍 Module Audit Report
════════════════════════════════════════════

📍 Project: orisha-must-poc-sandbox/sandbox/eu-west-3

Found 8 modules:

✅ APPROVED MODULES (6)
────────────────────────────────────────────

1. module "vpc"
   Source: terraform-aws-modules/vpc/aws
   Current: 5.1.2
   Latest:  5.5.1 (via Context7)
   Status:  🔄 UPDATE AVAILABLE
   File:    r-vpc.tf:10

2. module "alb"
   Source: terraform-aws-modules/alb/aws
   Current: 9.4.0
   Latest:  9.4.0 (via Context7)
   Status:  ✅ UP TO DATE
   File:    r-alb.tf:15

3. module "claranet_ips"
   Source: git::ssh://git@git.fr.clara.net/.../terraform-claranet-ip-module.git?ref=v1.2.0
   Status:  ✅ CLARANET MODULE
   File:    r-module-claranet-ips.tf:1

⚠️ VERSION PINNING ISSUES (1)
────────────────────────────────────────────

4. module "rds"
   Source: terraform-aws-modules/rds/aws
   Version: "~> 5.0"
   Issue:   ❌ Uses version range - must use exact version
   Fix:     Change to: version = "5.9.1"
   File:    r-rds.tf:25

❌ UNAPPROVED MODULES (1)
────────────────────────────────────────────

5. module "custom_networking"
   Source: github.com/example/terraform-custom
   Version: 1.0.0
   Issue:   ❌ Not in approved module list
   Action:  Requires architectural review and approval
   File:    r-network.tf:45

════════════════════════════════════════════

📊 SUMMARY
────────────────────────────────────────────
Total modules:           8
✅ Approved & current:   5
🔄 Updates available:    1
⚠️  Pinning issues:      1
❌ Unapproved:           1

🎯 RECOMMENDED ACTIONS
────────────────────────────────────────────
1. Update 'vpc' module to 5.5.1
2. Fix 'rds' module version pinning
3. Request approval for 'custom_networking' module
```

## Module Update Suggestions

When updates are available, provide:
```
🔄 UPDATE AVAILABLE: module "vpc"

Current version: 5.1.2
Latest version:  5.5.1

What's new (via Context7):
- Enhanced IPv6 support
- New NAT gateway options
- Bug fixes for route tables

Breaking changes: None

Suggested change:
─────────────────
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
- version = "5.1.2"
+ version = "5.5.1"
  ...
}
─────────────────

Test command:
mise exec -- tofu init -upgrade
mise exec -- tofu plan
```

## Error Cases

### No modules found
```
🔍 Module Audit Report
════════════════════════════════════════════
⚠️  No Terraform modules found in this directory

This command should be run from a Terraform stack directory.
```

### Context7 unavailable
```
⚠️  Context7 MCP not available
Cannot check for updates to terraform-aws-modules

Will check:
✅ Module source compliance
✅ Version pinning format
❌ Latest version availability (requires Context7)
```

## Notes

- Run from project root to scan all stacks
- Run from stack directory to scan specific stack
- Context7 queries may take a few seconds
- Only terraform-aws-modules checked for updates via Context7
- Claranet modules require manual version checking
