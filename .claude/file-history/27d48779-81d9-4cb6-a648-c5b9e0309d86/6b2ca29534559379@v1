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

---

## Step 6 — Output format

The review report must follow this structure:

```markdown
# Code Review — `<branchA>` → `<branchB>`

## Summary
> One paragraph: what this diff does, overall quality assessment.

## Score: X/10 — <label>
> Labels: Excellent (9-10) / Good (7-8) / Average (5-6) / Needs Work (3-4) / Critical (1-2)

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
```

---

## Severity guide

| Severity | Use when |
|----------|----------|
| ⛔ CRITICAL | Security flaw, data loss risk, breaking change, crash risk |
| ⚠️ WARNING  | Bug potential, bad pattern, missing test on critical path |
| ℹ️ INFO     | Style, readability, minor optimization, suggestion |