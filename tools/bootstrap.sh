#!/usr/bin/env bash
# One-time setup for a repo started from agent-project-template.
# Usage: bash tools/bootstrap.sh [owner/repo]
set -euo pipefail

REPO="${1:-$(git remote get-url origin | sed -E 's#.*github.com[:/]##; s/\.git$//')}"

echo "Repo: $REPO"

# 1. Labels the loop depends on.
echo "Creating labels..."
if ! labels="$(gh label list --repo "$REPO" --limit 1000 --json name --jq '.[].name')"; then
  echo "ERROR: could not list labels in $REPO; setup is incomplete." >&2
  exit 1
fi
while IFS='|' read -r name color desc; do
  label_exists=false
  while IFS= read -r existing_label; do
    if [[ "$existing_label" == "$name" ]]; then
      label_exists=true
      break
    fi
  done <<< "$labels"

  if [[ "$label_exists" == true ]]; then
    if ! gh label edit "$name" --repo "$REPO" --color "$color" --description "$desc"; then
      echo "ERROR: could not update label '$name' in $REPO." >&2
      exit 1
    fi
    echo "  updated: $name"
  else
    if ! gh label create "$name" --repo "$REPO" --color "$color" --description "$desc"; then
      echo "ERROR: could not create label '$name' in $REPO." >&2
      exit 1
    fi
    echo "  created: $name"
  fi
done <<'EOF'
bug|d73a4a|Playtest or user-reported problem; fixed before any story
story|0052cc|A unit of planned work from the current phase in PLAN.md
in-progress|fbca04|A session has claimed this issue; other sessions skip it
blocked-answer|d876e3|Waiting on someone outside the repo to answer
spike|1d7673|Timeboxed investigation to pick between approaches
EOF

# 2. Protect master: require pull requests, no force pushes, linear history.
echo "Setting branch protection on master..."
if ! gh api -X PUT "repos/$REPO/branches/master/protection" --input - <<'EOF'
{
  "required_status_checks": null,
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 0
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
then
  echo "ERROR: could not configure branch protection for $REPO/master; setup is incomplete." >&2
  exit 1
fi

if ! protection="$(gh api "repos/$REPO/branches/master/protection" \
  --jq '.required_pull_request_reviews != null and .enforce_admins.enabled == true')"; then
  echo "ERROR: could not verify branch protection for $REPO/master; setup is incomplete." >&2
  exit 1
fi
if [[ "$protection" != "true" ]]; then
  echo "ERROR: master is not protected by a pull request requirement enforced for administrators." >&2
  exit 1
fi
echo "Verified: master requires pull requests and applies protection to administrators."

# 3. The three standing audit stories every project starts with.
# They wait for the human's go-ahead; agents never auto-take them.
mkdir -p docs/specs
echo "Filing standing audit stories..."
file_story() { # gh issue create unless a same-title issue already exists
  local existing_titles existing_title title_exists=false
  if ! existing_titles="$(gh issue list -R "$REPO" --search "\"$1\" in:title" --state all --limit 100 --json title -q '.[].title')"; then
    echo "ERROR: could not check for the standing story '$1' in $REPO." >&2
    return 1
  fi

  while IFS= read -r existing_title; do
    if [[ "$existing_title" == "$1" ]]; then
      title_exists=true
      break
    fi
  done <<< "$existing_titles"

  if [[ "$title_exists" == true ]]; then
    echo "  (exists) $1"
    return 0
  fi
  gh issue create -R "$REPO" --title "$1" --body-file "$3" --label story \
    && echo "  filed: $1"
}

cat > /tmp/audit-1.md <<'EOF'
<!-- standing audit story: on-request only -->
The human must give the go-ahead before this is worked. Agents: never auto-take it as "the next story".

## What are we missing?

Act as a veteran product lead, technical director, and executive producer
reviewing this project so far.

The goal is to uncover blind spots, edge cases, and critical questions we
haven't asked yet. Combine these three lenses into one review:

1. **Blind spots and overlooked issues** — design conflicts, technical
   bottlenecks, user experience gaps, or edge cases we are completely
   ignoring.
2. **Pre-mortem** — imagine this product shipped and failed or got bad
   reviews because of development oversights. Write a brief post-mortem on
   what went wrong with the mechanics, systems integration, and production
   scope.
3. **360° hard questions** — break the project into its core loop,
   retention/progression (adapt to the domain), edge-case UX, technical
   constraints, and scope creep. Under each area, list the 3 hardest
   questions we must answer right now.

Be direct, critical, and brutally honest. Focus on what is missing or
risky. Then create grouped git issues for what the findings say to do.
EOF

cat > /tmp/audit-2.md <<'EOF'
<!-- standing audit story: on-request only -->
The human must give the go-ahead before this is worked. Agents: never auto-take it as "the next story".

## Code review audit: static findings as issues

Perform a comprehensive static analysis and code review of the project's
source code, generate structured findings, and submit them as git issues.

### Review focus areas

Scan the code for:
1. Bugs and logic errors (edge cases, memory leaks, null references,
   unhandled exceptions)
2. Security vulnerabilities (injection, hardcoded secrets, unsafe
   deserialization, unvalidated inputs)
3. Performance bottlenecks (unoptimized loops, N+1 queries, inefficient
   data structures)
4. Maintainability and code smells (anti-patterns, duplication, low
   readability, poor error handling)
5. Architectural and API best practices (broken design principles,
   improper async handling)
6. Any other flaw that applies to this project. Skip the ones that don't,
   and say so in the audit summary.

### Output format — every finding, exactly this shape, one issue each

```
## [ISSUE] <short, descriptive title>

**Severity:** <Critical|High|Medium|Low>
**Category:** <Bug|Security|Performance|Maintainability|Architecture>
**File:** `<path/to/file>`
**Line(s):** <range>

### Description
<why it is a problem and its impact>

### Problematic code
<exact snippet>

### Suggested fix
<smallest sound change>
```

Create one individual GitHub issue per finding, then a checklist in this
parent issue linking each one.
EOF

cat > /tmp/audit-3.md <<'EOF'
<!-- standing audit story: on-request only -->
The human must give the go-ahead before this is worked. Agents: never auto-take it as "the next story".

## Architecture audit: project-tailored deep review

A deeper, tailored pass than the static audit: derive this project's own
critical-risk focus areas from its architecture, then audit each one.

### Deriving the focus areas

Start from what this project actually is — its money paths, state and
integrity surfaces, persistence and sync behavior, external integrations,
compliance requirements. Audit areas include (take only the ones that
apply, and add any this project uniquely needs):

- State integrity and race conditions (concurrent updates, double-apply,
  optimistic locking, drift across partial failures)
- Data lifecycle (retention, migration, historical identity, stale
  writers)
- External integration and device edge cases (dropouts, re-entrancy,
  timeouts, retries)
- Security and compliance (authorization at every boundary, injection,
  audit-tamper resistance)
- Performance under real load (N+1, main-thread blocking, listener leaks)
- Maintainability, error handling, and reliability (swallowed errors,
  missing fallback states, unhandled transitions)

### Deliverables

- One individual GitHub issue per finding, with consistent fields:
  severity (P0–P2), evidence, failure scenario, verification, remediation,
  and acceptance criteria.
- The full structured audit written to `docs/audits/issue-N/REPORT.md`.
- A findings checklist (linked issues) in this parent issue.
- A few isolated, non-destructive diagnostics run to validate the
  source-to-issue mappings.

Completing this issue completes the audit only. The remediation findings
stay open and go through the normal loop.
EOF

file_story "Standing story: What are we missing? (on-request)" "Standing story: What are we missing?" /tmp/audit-1.md
file_story "Standing story: Code review audit (on-request)" "Standing story: Code review audit" /tmp/audit-2.md
file_story "Standing story: Architecture audit (on-request)" "Standing story: Architecture audit" /tmp/audit-3.md
rm -f /tmp/audit-1.md /tmp/audit-2.md /tmp/audit-3.md

echo "Done. Optional: run 'engram-alpha serve' here for shared memory
(.engram/). Next: fill in AGENTS.md's <PROJECT_SUMMARY>, Verification, and
Code style sections; write PLAN.md phases; file the first issues:
gh issue create --label story"
