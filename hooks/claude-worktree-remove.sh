#!/usr/bin/env bash
# Claude Code WorktreeRemove hook: removes the worktree only if it has no uncommitted work.
set -euo pipefail
export PATH="$HOME/bin:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
input=$(cat)
path=$(printf '%s' "$input" | sed -n 's/.*"worktree_path" *: *"\([^"]*\)".*/\1/p')
[[ -n $path && -d $path ]] || exit 0

branch=$(git -C "$path" rev-parse --abbrev-ref HEAD)
git -C "$path" worktree remove "$path"
# -d (not -D): a branch with unmerged commits stays.
git branch -d "$branch" >/dev/null 2>&1 || true
