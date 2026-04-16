# Skill: git-diff-review

## Purpose

Provide the git-diff-reviewer agent with the procedural knowledge to extract,
split, and prepare a diff between two branches for analysis.

---

## Step 1 — Validate branches

```bash
# Ensure both branches exist
git rev-parse --verify "$BRANCH_A" > /dev/null 2>&1 || { echo "Branch $BRANCH_A not found"; exit 1; }
git rev-parse --verify "$BRANCH_B" > /dev/null 2>&1 || { echo "Branch $BRANCH_B not found"; exit 1; }

# Show divergence point
echo "=== Merge base ==="
git merge-base "$BRANCH_A" "$BRANCH_B"
```

---

## Step 2 — Detect dominant language

```bash
echo "=== Language breakdown ==="
git diff --name-only "${BRANCH_A}...${BRANCH_B}" \
  | grep -v '^$' \
  | sed 's/.*\.//' \
  | sort \
  | uniq -c \
  | sort -rn

# Map extension → lang label
# ts / tsx        → typescript_angular
# php             → php_symfony
# py              → python
# go              → golang
# java            → java
# (no extension)  → shell or config
```

Export for RAG loading:
```bash
DOMINANT_EXT=$(git diff --name-only "${BRANCH_A}...${BRANCH_B}" \
  | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')

case "$DOMINANT_EXT" in
  ts|tsx)  export DIFF_LANG="typescript_angular" ;;
  php)     export DIFF_LANG="php_symfony" ;;
  py)      export DIFF_LANG="python" ;;
  go)      export DIFF_LANG="golang" ;;
  java)    export DIFF_LANG="java" ;;
  *)       export DIFF_LANG="global" ;;
esac

echo "Detected language: $DIFF_LANG"
```

---

## Step 3 — Extract diff metadata

```bash
echo "=== Changed files ==="
git diff --name-status "${BRANCH_A}...${BRANCH_B}"

echo ""
echo "=== Commit list ==="
git log --oneline "${BRANCH_A}...${BRANCH_B}"

echo ""
echo "=== Diffstat ==="
git diff --stat "${BRANCH_A}...${BRANCH_B}"
```

---

## Step 4 — Split diff by file

For large diffs (>300 lines), analyze file by file to avoid context overflow:

```bash
# Get list of changed files
CHANGED_FILES=$(git diff --name-only "${BRANCH_A}...${BRANCH_B}")
TOTAL=$(echo "$CHANGED_FILES" | wc -l)

echo "Total files changed: $TOTAL"

# For each file, extract its individual diff
for FILE in $CHANGED_FILES; do
  echo ""
  echo "=============================="
  echo "FILE: $FILE"
  echo "=============================="
  git diff "${BRANCH_A}...${BRANCH_B}" -- "$FILE"
done
```

For small diffs (<300 lines), use the full diff at once:

```bash
git diff "${BRANCH_A}...${BRANCH_B}"
```

---

## Step 5 — Edge case detection

Before reviewing, flag potential issues:

```bash
DIFF_LINES=$(git diff "${BRANCH_A}...${BRANCH_B}" | wc -l)

# Large diff warning
if [ "$DIFF_LINES" -gt 1000 ]; then
  echo "[WARN] Large diff: $DIFF_LINES lines. Will review file by file."
fi

# Binary files
git diff --name-only "${BRANCH_A}...${BRANCH_B}" \
  | xargs -I{} git diff "${BRANCH_A}...${BRANCH_B}" --numstat -- {} \
  | grep '^-' \
  && echo "[INFO] Binary files detected — skipping content review for those."

# Renamed files
git diff --name-status "${BRANCH_A}...${BRANCH_B}" | grep '^R' \
  && echo "[INFO] Renamed files detected — tracking original context."

# Deleted files
git diff --name-status "${BRANCH_A}...${BRANCH_B}" | grep '^D' \
  && echo "[INFO] Deleted files — check for orphaned references."
```

### Version & changelog regression check

**Always run this check** when `package.json` or `CHANGELOG.md` appear in the diff:

```bash
# Check for version regression in package.json
VERSION_A=$(git show "${BRANCH_A}:package.json" 2>/dev/null | grep '"version"' | head -1)
VERSION_B=$(git show "${BRANCH_B}:package.json" 2>/dev/null | grep '"version"' | head -1)
echo "Version on ${BRANCH_A}: $VERSION_A"
echo "Version on ${BRANCH_B}: $VERSION_B"

# Check CHANGELOG.md line count delta
LINES_A=$(git show "${BRANCH_A}:CHANGELOG.md" 2>/dev/null | wc -l)
LINES_B=$(git show "${BRANCH_B}:CHANGELOG.md" 2>/dev/null | wc -l)
echo "CHANGELOG lines — ${BRANCH_A}: $LINES_A  /  ${BRANCH_B}: $LINES_B"
DELTA=$((LINES_A - LINES_B))
if [ "$DELTA" -gt 0 ]; then
  echo "[BLOCKER] CHANGELOG regression: ${BRANCH_B} is missing $DELTA lines present on ${BRANCH_A}"
fi
```

If `BRANCH_B` has a **lower semver** than `BRANCH_A`, or if `CHANGELOG.md` **loses lines**, flag it as ⛔ BLOCKER in the report with the action: *rebase on `BRANCH_A` or manually restore the version/CHANGELOG before merge*.

---

## Step 6 — Output format

The review report must follow this structure:

```markdown
# Code Review — `<branchA>` → `<branchB>`

## Summary
> Bullet list (3-5 points): axes couverts, qualité générale, points d'attention principaux.
> - **Axe N — Titre** : description courte
> - **Qualité générale** : appréciation
> - **Points d'attention** : problèmes clés avant merge

## Score: X/10 — <label>
> Labels: Excellent (9-10) / Good (7-8) / Average (5-6) / Needs Work (3-4) / Critical (1-2)

---

## ⛔ Bloquants — À corriger avant merge

> This section is MANDATORY if any blocker exists. Omit it entirely if there are none.
> Typical blockers: version regression, CHANGELOG loss, breaking API change, security flaw, data loss risk.

### `file` — Short title

Description + required action.

---

## Files

### `path/to/file.ts` — [Added|Modified|Deleted]

**Issues:**
- ⛔ `CRITICAL` — line XX — Description + suggestion
- ⚠️ `WARNING`  — line XX — Description + suggestion
- ℹ️ `INFO`     — line XX — Description + suggestion

**Positives:**
- ✅ What's done well

---

## Cross-cutting concerns

- ⛔ / ⚠️ / ℹ️ Architectural or systemic issues

---

## Top Recommendations

1. ...
2. ...
3. ...

---

*Review done with the git-diff-reviewer skill*
```

---

## Severity guide

| Severity | Use when |
|----------|----------|
| ⛔ CRITICAL | Security flaw, data loss risk, breaking change, crash risk |
| ⚠️ WARNING  | Bug potential, bad pattern, missing test on critical path |
| ℹ️ INFO     | Style, readability, minor optimization, suggestion |