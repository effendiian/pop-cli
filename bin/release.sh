#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: ./bin/release.sh <major|minor|patch>"
    exit 1
fi

BUMP_TYPE=$1

CURRENT_VERSION=$(git describe --tags --abbrev=0)
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

case $BUMP_TYPE in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
    *)
        echo "Invalid bump type: $BUMP_TYPE. Use major, minor, or patch."
        exit 1
        ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"

echo "Releasing v$NEW_VERSION"

towncrier build --yes

git add CHANGELOG.md
git commit -m "chore(release): $NEW_VERSION"

git tag "$NEW_VERSION"

git push origin main
git push origin "$NEW_VERSION"

echo "Release v$NEW_VERSION created and pushed to origin."
