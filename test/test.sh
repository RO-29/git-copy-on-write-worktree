#!/usr/bin/env bash
# Builds a throwaway repo in a temp folder and checks that git-cow-worktree gives a correct, clean worktree.
set -euo pipefail

here=$(cd "$(dirname "$0")/.." && pwd)
tool=${COW_TOOL:-"$here/git-cow-worktree"}
base=${TMPDIR:-/tmp}
work=$(mktemp -d "${base%/}/cowtest.XXXXXX")
trap 'rm -rf "$work"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }

cd "$work"
git init -q -b main repo && cd repo
git config user.email test@example.com && git config user.name test
printf 'node_modules/\n' > .gitignore
echo v1 > app.txt
git add . && git commit -qm one
first=$(git rev-parse HEAD)
echo v2 > app.txt && git commit -qam two

mkdir -p node_modules/pkg
dd if=/dev/zero of=node_modules/pkg/blob bs=1048576 count=200 2>/dev/null
echo dirty > app.txt
echo scratch > untracked.txt

free_kb() { df -Pk "$work" | awk 'NR==2 {print $4}'; }
sync; before=$(free_kb); start=$(date +%s)
"$tool" "$work/wt" -b feature "$first" >/dev/null
sync; used_mb=$(( (before - $(free_kb)) / 1024 ))
echo "clone time: $(( $(date +%s) - start )) s, new disk space: ${used_mb} MB for a 200 MB ignored folder"

cd "$work/wt"
[[ $(git rev-parse --abbrev-ref HEAD) == feature ]] || fail "branch is not feature"
[[ $(cat app.txt) == v1 ]]                          || fail "app.txt is not at the target commit"
[[ -f node_modules/pkg/blob ]]                      || fail "ignored folder was not cloned"
[[ ! -e untracked.txt ]]                            || fail "untracked file came across"
[[ -z $(git status --porcelain) ]]                  || fail "worktree is not clean"
[[ $(cat "$work/repo/app.txt") == dirty ]]          || fail "source worktree changed"
(( used_mb < 100 ))                                 || fail "clone used ${used_mb} MB, so it is not copy-on-write"

echo "PASS: all checks"
