#!/bin/bash

# Cleanup script for GitHub repository
# Deletes all releases, tags, artifacts, and workflow runs

set -e

echo "🧹 Starting repository cleanup..."

# Get repository info
REPO=$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/')
echo "Repository: $REPO"

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed. Please install it first:"
    echo "   https://cli.github.com/"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub CLI. Run: gh auth login"
    exit 1
fi

# Check for required scopes
echo "Checking GitHub CLI permissions..."
if ! gh api /user &> /dev/null; then
    echo "⚠️  Warning: May need additional permissions for package deletion"
    echo "   Run: gh auth refresh -s read:packages,delete:packages"
    echo ""
fi

echo ""
echo "⚠️  WARNING: This will delete:"
echo "   - All releases"
echo "   - All tags (local and remote)"
echo "   - All artifacts"
echo "   - All workflow run history"
echo "   - All packages (container images)"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "🗑️  Deleting releases..."
gh release list --limit 1000 | awk '{print $1}' | while read -r release; do
    if [ -n "$release" ]; then
        echo "  Deleting release: $release"
        gh release delete "$release" --yes 2>/dev/null || true
    fi
done

echo ""
echo "🗑️  Deleting remote tags..."
git tag -l | while read -r tag; do
    if [ -n "$tag" ]; then
        echo "  Deleting tag: $tag"
        git push --delete origin "$tag" 2>/dev/null || true
    fi
done

echo ""
echo "🗑️  Deleting local tags..."
git tag -l | xargs -r git tag -d

echo ""
echo "🗑️  Deleting artifacts..."
gh api "/repos/$REPO/actions/artifacts?per_page=100" --paginate | \
    jq -r '.artifacts[].id' | while read -r artifact_id; do
    if [ -n "$artifact_id" ]; then
        echo "  Deleting artifact: $artifact_id"
        gh api --method DELETE "/repos/$REPO/actions/artifacts/$artifact_id" 2>/dev/null || true
    fi
done

echo ""
echo "🗑️  Deleting workflow runs..."
gh api "/repos/$REPO/actions/runs?per_page=100" --paginate | \
    jq -r '.workflow_runs[].id' | while read -r run_id; do
    if [ -n "$run_id" ]; then
        echo "  Deleting workflow run: $run_id"
        gh api --method DELETE "/repos/$REPO/actions/runs/$run_id" 2>/dev/null || true
    fi
done

echo ""
echo "🗑️  Deleting packages for repository: $REPO_NAME..."
OWNER=$(echo $REPO | cut -d'/' -f1)
REPO_NAME=$(echo $REPO | cut -d'/' -f2)

echo "  Note: Package deletion requires read:packages and delete:packages scopes"
echo "  If you see permission errors, run: gh auth refresh -s read:packages,delete:packages"
echo ""

# List and delete only packages matching the repository name
gh api -X GET "/users/$OWNER/packages?package_type=container" --paginate 2>/dev/null | \
    jq -r 'if type == "array" then .[] | select(.repository.name == "'$REPO_NAME'") | .name else empty end' 2>/dev/null | while read -r package_name; do
    if [ -n "$package_name" ]; then
        echo "  Found package: $package_name (linked to $REPO_NAME)"
        # Delete all versions of the package
        gh api "/users/$OWNER/packages/container/$package_name/versions" --paginate 2>/dev/null | \
            jq -r 'if type == "array" then .[].id else empty end' 2>/dev/null | while read -r version_id; do
            if [ -n "$version_id" ]; then
                echo "    Deleting version: $version_id"
                gh api --method DELETE "/users/$OWNER/packages/container/$package_name/versions/$version_id" 2>/dev/null || true
            fi
        done
    fi
done

# Try org packages if user is part of an org
gh api -X GET "/orgs/$OWNER/packages?package_type=container" --paginate 2>/dev/null | \
    jq -r 'if type == "array" then .[] | select(.repository.name == "'$REPO_NAME'") | .name else empty end' 2>/dev/null | while read -r package_name; do
    if [ -n "$package_name" ]; then
        echo "  Found org package: $package_name (linked to $REPO_NAME)"
        gh api "/orgs/$OWNER/packages/container/$package_name/versions" --paginate 2>/dev/null | \
            jq -r 'if type == "array" then .[].id else empty end' 2>/dev/null | while read -r version_id; do
            if [ -n "$version_id" ]; then
                echo "    Deleting version: $version_id"
                gh api --method DELETE "/orgs/$OWNER/packages/container/$package_name/versions/$version_id" 2>/dev/null || true
            fi
        done
    fi
done

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "📝 Summary:"
echo "   - All releases deleted"
echo "   - All tags deleted (local and remote)"
echo "   - All artifacts deleted"
echo "   - All workflow run history deleted"
echo "   - All packages deleted"
