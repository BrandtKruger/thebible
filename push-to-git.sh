#!/bin/bash

# Script to push The Bible project to Git repository
# Usage: ./push-to-git.sh [your-git-repo-url]

set -e

REPO_URL="$1"

echo "=== Pushing The Bible Project to Git ==="
echo ""

# Check if repo URL provided
if [ -z "$REPO_URL" ]; then
    echo "Usage: $0 [your-git-repo-url]"
    echo ""
    echo "Examples:"
    echo "  $0 https://github.com/username/thebible.git"
    echo "  $0 git@github.com:username/thebible.git"
    echo ""
    echo "Or if remote is already configured:"
    echo "  $0"
    echo ""
    
    # Check if remote exists
    if git remote get-url origin 2>/dev/null; then
        REPO_URL=$(git remote get-url origin)
        echo "Found existing remote: $REPO_URL"
        echo ""
        read -p "Use this remote? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo "No remote configured. Please provide repository URL."
        exit 1
    fi
fi

# Check if .env exists and warn
if [ -f ".env" ]; then
    echo "⚠ Warning: .env file exists (will be excluded by .gitignore)"
    echo "Make sure .env is in .gitignore before pushing!"
    echo ""
fi

# Add all files
echo "Adding files to git..."
git add .

# Check what will be committed
echo ""
echo "Files to be committed:"
git status --short

echo ""
read -p "Continue with commit? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

# Make initial commit
echo ""
echo "Making initial commit..."
git commit -m "Initial commit: The Bible web server with HelloAO API integration

- Rust web server using Axum framework
- HelloAO Bible API integration
- Commentary support
- Modern frontend with searchable translations
- Bilingual display for German translations
- Chapter navigation with dropdown
- Deployment scripts for Linode Ubuntu
- Nginx reverse proxy configuration
- SSL/HTTPS support"

# Set remote if not exists
if ! git remote get-url origin &>/dev/null; then
    echo ""
    echo "Setting remote origin..."
    git remote add origin "$REPO_URL"
fi

# Push to repository
echo ""
echo "Pushing to repository..."
echo "Repository: $REPO_URL"
echo ""

# Check if this is the first push
if git ls-remote --heads origin master &>/dev/null || git ls-remote --heads origin main &>/dev/null; then
    # Remote has commits, try to push
    CURRENT_BRANCH=$(git branch --show-current)
    git push -u origin "$CURRENT_BRANCH"
else
    # First push, create branch
    CURRENT_BRANCH=$(git branch --show-current)
    if [ "$CURRENT_BRANCH" = "master" ]; then
        # Try main branch first (GitHub default)
        git branch -M main 2>/dev/null || true
        git push -u origin main || git push -u origin master
    else
        git push -u origin "$CURRENT_BRANCH"
    fi
fi

echo ""
echo "✓ Successfully pushed to repository!"
echo ""
echo "Your repository is now available at:"
if [[ "$REPO_URL" == *"github.com"* ]]; then
    REPO_NAME=$(echo "$REPO_URL" | sed -E 's/.*github.com[:/]([^/]+\/[^/]+)\.git/\1/')
    echo "  https://github.com/$REPO_NAME"
elif [[ "$REPO_URL" == *"gitlab.com"* ]]; then
    REPO_NAME=$(echo "$REPO_URL" | sed -E 's/.*gitlab.com[:/]([^/]+\/[^/]+)\.git/\1/')
    echo "  https://gitlab.com/$REPO_NAME"
else
    echo "  $REPO_URL"
fi

