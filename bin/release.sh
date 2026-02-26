#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------
# Configuration
# ---------------------------------------------
DEFAULT_INITIAL_VERSION="0.1.0"
DRY_RUN=false
BUMP_TYPE=""
CI_REQUIRED=true

# ---------------------------------------------
# Argument Parsing
# ---------------------------------------------
usage() {
  echo "Usage: $0 <major|minor|patch> [--dry-run]"
  exit 1
}

if [ $# -lt 1 ]; then
  usage
fi

BUMP_TYPE="$1"
shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
  shift
done

if [[ "$BUMP_TYPE" != "major" && "$BUMP_TYPE" != "minor" && "$BUMP_TYPE" != "patch" ]]; then
  echo "Invalid bump type: $BUMP_TYPE"
  exit 1
fi

# ---------------------------------------------
# Enforce CI-only execution
# ---------------------------------------------
if [[ "$CI_REQUIRED" = true ]]; then
  if [[ -z "${CI:-}" ]]; then
    echo "❌ Releases must run in CI."
    exit 1
  fi
fi

# ---------------------------------------------
# Ensure clean working tree
# ---------------------------------------------
if ! git diff-index --quiet HEAD --; then
  echo "❌ Working tree is dirty."
  exit 1
fi

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
  NEW_VERSION="$DEFAULT_INITIAL_VERSION"
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

# ---------------------------------------------
# Idempotency check: tag already exists?
# ---------------------------------------------
if git rev-parse "$NEW_VERSION" >/dev/null 2>&1; then
  echo "✔ Tag $NEW_VERSION already exists. Nothing to do."
  exit 0
fi

echo "Releasing $NEW_VERSION"

# ---------------------------------------------
# Build changelog safely
# ---------------------------------------------
if [ "$DRY_RUN" = true ]; then
  echo "[DRY RUN] Would build changelog for $NEW_VERSION"
  towncrier build --draft --version "$NEW_VERSION"
else
  towncrier build --yes --version "$NEW_VERSION"
fi

# ----------------------------------------
# Commit + tag
# ----------------------------------------
if [ "$DRY_RUN" = true ]; then
  echo "[DRY RUN] Would commit and tag $NEW_VERSION"
  exit 0
fi

git add -A

if git diff --cached --quiet; then
  echo "⚠ No changes to commit (likely no fragments)."
else
  git commit -m "chore(release): $NEW_VERSION"
fi

git tag "$NEW_VERSION"

# Release workflow will push the tag.
# git push origin main
# git push origin "$NEW_VERSION"

echo "✔ Release $NEW_VERSION prepared successfully."
