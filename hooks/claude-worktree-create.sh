#!/usr/bin/env bash
# Claude Code WorktreeCreate hook: makes a CoW worktree next to the repo and prints its path.
set -euo pipefail
input=$(cat)
field() { printf '%s' "$input" | sed -n "s/.*\"$1\" *: *\"\([^\"]*\)\".*/\1/p"; }
name=$(field name); cwd=$(field cwd)
[[ -n $name && -n $cwd ]] || { echo "WorktreeCreate: name or cwd missing in hook input" >&2; exit 1; }

cd "$cwd"
top=$(git rev-parse --show-toplevel)
dir="$(dirname "$top")/$(basename "$top")-worktrees/$name"
mkdir -p "$(dirname "$dir")"
git cow-worktree "$dir" -b "worktree-$name" >&2
(cd "$dir" && pwd -P)
