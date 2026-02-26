#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: ./bin/release.sh <major|minor|patch>"
    exit 1
fi

BUMP_TYPE=$1

# ----------------------------------------
# Determine current version (if any)
# ----------------------------------------

# This returns:
# - Latest tag if it exists
# - Commit SHA if no tag exists (because of --always)
CURRENT_REF=$(git describe --tags --abbrev=0 --always 2>/dev/null || true)

# Check if CURRENT_REF is a valid semver tag (X.Y.Z)
if [[ "$CURRENT_REF" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  CURRENT_VERSION="$CURRENT_REF"
  FIRST_RELEASE=false
else
  CURRENT_VERSION=""
  FIRST_RELEASE=true
fi

# ----------------------------------------
# Compute new version
# ----------------------------------------

if [ "$FIRST_RELEASE" = true ]; then
  NEW_VERSION="0.1.0"
  echo "No existing tags found. Initial release will be $NEW_VERSION"
else
  IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

  case "$BUMP_TYPE" in
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
      echo "Invalid bump type: $BUMP_TYPE"
      exit 1
      ;;
  esac

  NEW_VERSION="$MAJOR.$MINOR.$PATCH"
fi

# ----------------------------------------
# Prevent double-tagging.
# ----------------------------------------

if git rev-parse "$NEW_VERSION" >/dev/null 2>&1; then
  echo "Tag $NEW_VERSION already exists."
  exit 1
fi

echo "Releasing $NEW_VERSION"

# ----------------------------------------
# Build changelog
# ----------------------------------------

towncrier build --yes --version "$NEW_VERSION"

# ----------------------------------------
# Commit + tag
# ----------------------------------------

git add -A

git commit -m "chore(release): $NEW_VERSION"

git tag "$NEW_VERSION"

git push origin main
git push origin "$NEW_VERSION"

echo "Release v$NEW_VERSION created and pushed to origin."
