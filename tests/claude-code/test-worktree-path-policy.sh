#!/usr/bin/env bash
# Regression check: Superpowers should not route new worktrees through the old
# global worktree directory.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

USING_SKILL="$REPO_ROOT/skills/using-git-worktrees/SKILL.md"
FINISHING_SKILL="$REPO_ROOT/skills/finishing-a-development-branch/SKILL.md"
ROTOTILL_SPEC="$REPO_ROOT/docs/superpowers/specs/2026-04-06-worktree-rototill-design.md"
ROTOTILL_PLAN="$REPO_ROOT/docs/superpowers/plans/2026-04-06-worktree-rototill.md"

failures=0

# These assertions search skill documentation for literal text. The old global
# path appears in that prose as the characters `~/.config/...`, so the tilde
# must stay a literal tilde -- expanding it to $HOME would search for a
# different string and silently stop testing anything. Likewise the backticks
# below are Markdown code-span syntax in the documents being searched. Both are
# built from variables so the pattern strings are byte-for-byte unchanged while
# ShellCheck can see the literals are intentional (SC2088, SC2016).
tilde='~'
bt='`'

assert_contains() {
    local file="$1"
    local pattern="$2"
    local label="$3"

    if grep -Fq "$pattern" "$file"; then
        echo "  [PASS] $label"
    else
        echo "  [FAIL] $label"
        echo "    Expected to find: $pattern"
        echo "    In file: $file"
        failures=$((failures + 1))
    fi
}

assert_not_contains() {
    local file="$1"
    local pattern="$2"
    local label="$3"

    if grep -Fq "$pattern" "$file"; then
        echo "  [FAIL] $label"
        echo "    Did not expect to find: $pattern"
        echo "    In file: $file"
        failures=$((failures + 1))
    else
        echo "  [PASS] $label"
    fi
}

echo "=== Worktree Path Policy Test ==="
echo ""

assert_not_contains "$USING_SKILL" "${tilde}/.config/superpowers/worktrees" "using-git-worktrees does not mention old global path"
assert_not_contains "$USING_SKILL" "global legacy" "using-git-worktrees does not use unclear global legacy shorthand"
assert_not_contains "$USING_SKILL" "Global path" "using-git-worktrees has no global path quick-reference row"
assert_contains "$USING_SKILL" "default to ${bt}.worktrees/${bt} at the project root" "using-git-worktrees defaults new manual worktrees to .worktrees/"

assert_not_contains "$FINISHING_SKILL" "${tilde}/.config/superpowers/worktrees" "finishing-a-development-branch does not treat old global path as owned"
assert_contains "$FINISHING_SKILL" "${bt}.worktrees/${bt} or ${bt}worktrees/${bt}" "finishing-a-development-branch keeps project-local cleanup ownership"

assert_not_contains "$ROTOTILL_SPEC" "${tilde}/.config/superpowers/worktrees" "rototill spec does not preserve old global path policy"
assert_not_contains "$ROTOTILL_PLAN" "${tilde}/.config/superpowers/worktrees" "rototill plan does not preserve old global path policy"
assert_not_contains "$ROTOTILL_PLAN" "legacy path compat" "rototill plan does not advertise legacy path compatibility"

echo ""

if [ "$failures" -gt 0 ]; then
    echo "STATUS: FAILED ($failures failures)"
    exit 1
fi

echo "STATUS: PASSED"
