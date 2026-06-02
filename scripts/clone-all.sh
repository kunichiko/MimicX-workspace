#!/bin/bash
# ===================================================================================
# clone-all.sh
# ===================================================================================
# 新環境で MimicX-workspace を clone した直後に sub-repo を一括取得する。
# 既にあるリポジトリはスキップする (= 冪等)。
#
# 使い方:
#   cd <workspace dir> && ./scripts/clone-all.sh
# ===================================================================================
set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

REPOS=(
    MimicX-firmware
    MimicX-protocol
    MimicX-app
    MimicX-hardware
)

for repo in "${REPOS[@]}"; do
    if [ -d "$repo/.git" ]; then
        echo "✓ $repo (existing git repo, skipped)"
        continue
    fi
    if [ -e "$repo" ]; then
        echo "ERROR: $repo exists but is not a git repository" >&2
        exit 1
    fi
    echo "Cloning $repo..."
    git clone "https://github.com/kunichiko/$repo.git" "$repo"
done

echo ""
echo "Done. All sub-repositories are present under $REPO_ROOT/"
