#!/bin/bash

# Claude PM Framework Installer
# Run: curl -fsSL https://raw.githubusercontent.com/dev-brewery/claude-pm-framework/main/install.sh | bash

set -e

REPO_URL="https://github.com/dev-brewery/claude-pm-framework"
TEMP_DIR="/tmp/claude-pm-framework-$$"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
echo "║                        CLAUDE PM FRAMEWORK INSTALLER                          ║"
echo "╚═══════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Error: git is not installed. Please install git first."
    exit 1
fi

# Check if we're in a directory
if [ ! -d "." ]; then
    echo "Error: Cannot determine current directory."
    exit 1
fi

# ─────────────────────────────────────────────────────────────────────────────
# GitHub Token Detection
# ─────────────────────────────────────────────────────────────────────────────
echo "🔑 Checking for GitHub credentials..."

# Look for GITHUB_TOKEN in Claude's global .env file
CLAUDE_ENV="$HOME/.claude/.env"
if [ -z "$GITHUB_TOKEN" ] && [ -f "$CLAUDE_ENV" ]; then
    # Extract GITHUB_TOKEN from .env file
    TOKEN_LINE=$(grep -E '^GITHUB_TOKEN=' "$CLAUDE_ENV" 2>/dev/null || true)
    if [ -n "$TOKEN_LINE" ]; then
        # Remove quotes and extract value
        export GITHUB_TOKEN=$(echo "$TOKEN_LINE" | sed 's/^GITHUB_TOKEN=//' | sed 's/^["'"'"']//' | sed 's/["'"'"']$//')
        echo "   ✓ Found GITHUB_TOKEN in ~/.claude/.env"
    fi
fi

# Check if gh CLI is available and configure it
GH_AVAILABLE=false
if command -v gh &> /dev/null; then
    GH_AVAILABLE=true
    echo "   ✓ GitHub CLI (gh) is available"

    # If we have a token, gh will use it via GITHUB_TOKEN env var
    if [ -n "$GITHUB_TOKEN" ]; then
        echo "   ✓ GitHub CLI will use detected token"
    fi
elif [ -n "$GITHUB_TOKEN" ]; then
    echo "   ⚠ GitHub CLI not installed, but token available for git operations"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Repository Setup
# ─────────────────────────────────────────────────────────────────────────────

# Initialize git if needed
if [ ! -d ".git" ]; then
    echo "📁 Initializing git repository..."
    git init
fi

# Clone the framework to temp directory
echo "📥 Downloading Claude PM Framework..."
rm -rf "$TEMP_DIR"

# Use token for clone if available (for private repos)
if [ -n "$GITHUB_TOKEN" ]; then
    CLONE_URL="https://${GITHUB_TOKEN}@github.com/dev-brewery/claude-pm-framework.git"
else
    CLONE_URL="$REPO_URL"
fi

git clone --depth 1 "$CLONE_URL" "$TEMP_DIR" 2>/dev/null || {
    echo "Error: Failed to clone repository. Check the URL and your network connection."
    exit 1
}

# Create directories if they don't exist
echo "📂 Setting up directory structure..."
mkdir -p .claude/{commands,agents,hooks,pm-state}
mkdir -p .github/workflows

# Copy framework files
echo "📋 Copying framework files..."

# Copy .claude directory
if [ -d "$TEMP_DIR/.claude" ]; then
    cp -r "$TEMP_DIR/.claude/"* .claude/
    echo "   ✓ Copied .claude/ files"
fi

# Copy .github directory
if [ -d "$TEMP_DIR/.github" ]; then
    cp -r "$TEMP_DIR/.github/"* .github/
    echo "   ✓ Copied .github/ files"
fi

# Cleanup
rm -rf "$TEMP_DIR"

# ─────────────────────────────────────────────────────────────────────────────
# GitHub Repository Creation (Optional)
# ─────────────────────────────────────────────────────────────────────────────
REPO_CREATED=false

if [ "$GH_AVAILABLE" = true ] && [ -n "$GITHUB_TOKEN" ]; then
    echo ""
    echo "🚀 GitHub Integration Available"
    echo "───────────────────────────────"

    # Get the directory name for repo name suggestion
    SUGGESTED_NAME=$(basename "$(pwd)")

    echo "Would you like to create a GitHub repository for this project?"
    echo "  Repository name: $SUGGESTED_NAME"
    echo ""
    read -p "Create GitHub repo? [y/N]: " CREATE_REPO

    if [[ "$CREATE_REPO" =~ ^[Yy]$ ]]; then
        echo ""
        read -p "Make repository public? [y/N]: " MAKE_PUBLIC

        VISIBILITY="--private"
        if [[ "$MAKE_PUBLIC" =~ ^[Yy]$ ]]; then
            VISIBILITY="--public"
        fi

        echo "📦 Creating GitHub repository..."
        if gh repo create "$SUGGESTED_NAME" $VISIBILITY --source=. --push 2>/dev/null; then
            REPO_CREATED=true
            echo "   ✓ Repository created and code pushed!"
            REPO_URL=$(gh repo view --json url -q .url 2>/dev/null || echo "")
        else
            echo "   ⚠ Repository creation failed (may already exist)"
        fi
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Complete
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
echo "║                              SETUP COMPLETE!                                  ║"
echo "╚═══════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "The Claude PM Framework has been installed in your project."
echo ""

if [ "$REPO_CREATED" = true ] && [ -n "$REPO_URL" ]; then
    echo "GitHub Repository: $REPO_URL"
    echo ""
fi

echo "NEXT STEPS:"
echo "───────────"
echo "1. Start Claude Code:  claude"
echo "2. Invoke the PM:      /pm your-project-name"
echo "3. Describe what to build"
echo ""
echo "EXAMPLE:"
echo "────────"
echo "  \$ claude"
echo "  > /pm my-app"
echo "  > Build a REST API with authentication and PostgreSQL"
echo ""
echo "The PM will handle: Plan → Design → Implement → Test → Review → Deploy"
echo ""

if [ -z "$GITHUB_TOKEN" ]; then
    echo "TIP: Add GITHUB_TOKEN to ~/.claude/.env for GitHub integration:"
    echo "     echo 'GITHUB_TOKEN=\"ghp_your_token_here\"' >> ~/.claude/.env"
    echo ""
fi
