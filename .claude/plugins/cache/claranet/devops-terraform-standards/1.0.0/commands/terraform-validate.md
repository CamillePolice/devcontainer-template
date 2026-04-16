# Terraform Validate Command

Execute the complete Terraform/OpenTofu validation sequence for the current stack.

## What This Command Does

Runs the mandatory 4-step validation workflow:
1. **Format** - `mise exec -- tofu fmt`
2. **Initialize** - `mise exec -- tofu init`
3. **Validate** - `mise exec -- tofu validate`
4. **Plan** - `mise exec -- tofu plan`

## Workflow

1. **Detect current stack**:
   - Check for `.tf` files in current directory
   - Identify if in a Terraform stack directory
   - If not in a stack, ask user which stack to validate

2. **Run validation sequence**:
   ```bash
   # Step 1: Format
   mise exec -- tofu fmt

   # Step 2: Initialize
   mise exec -- tofu init

   # Step 3: Validate
   mise exec -- tofu validate

   # Step 4: Plan
   mise exec -- tofu plan
   ```

3. **Report results**:
   - ✅ **Format**: Report if any files were modified
   - ✅ **Init**: Report if initialization succeeded
   - ✅ **Validate**: Report validation status
   - ✅ **Plan**: Report plan summary (resources to add/change/destroy)

4. **Error handling**:
   - Stop at first failure
   - Display clear error messages
   - Suggest fixes for common issues

## Success Criteria

- **Format**: No files modified (already properly formatted)
- **Init**: "Terraform has been successfully initialized"
- **Validate**: "Success! The configuration is valid"
- **Plan**: Executes without errors (may show planned changes)

## Common Use Cases

- After creating new `.tf` files
- After modifying existing infrastructure
- Before committing changes
- As part of code review process
- Testing module updates

## Example Output Format

```
🔧 Terraform Validation Report
════════════════════════════════════════════

📍 Stack: orisha-must-poc-sandbox/sandbox/eu-west-3

[1/4] Formatting...
✅ All files properly formatted (no changes)

[2/4] Initializing...
✅ Terraform initialized successfully
   - Providers: AWS 5.31.0, Vault 3.23.0
   - Modules: 5 downloaded

[3/4] Validating...
✅ Configuration is valid

[4/4] Planning...
✅ Plan succeeded
   - 3 to add
   - 2 to change
   - 0 to destroy

════════════════════════════════════════════
✅ Validation Complete - All checks passed
```

## Error Example

```
🔧 Terraform Validation Report
════════════════════════════════════════════

📍 Stack: services/eu-west-3

[1/4] Formatting...
✅ All files properly formatted

[2/4] Initializing...
✅ Terraform initialized successfully

[3/4] Validating...
❌ Validation failed

Error: Missing required variable
│
│   on variables.tf line 15:
│   15: variable "aws_region" {
│
│ The variable "aws_region" is not defined in variables.auto.tfvars

════════════════════════════════════════════
❌ Validation Failed - Fix errors above
```

## Notes

- Always run from the stack directory or specify the stack path
- Ensure `mise` is properly configured in the project
- State encryption keys must be available (check with `make check`)
- Network access required for provider and module downloads
