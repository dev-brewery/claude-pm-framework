#!/bin/bash

# Claude PM Framework Installer
# Run: curl -fsSL https://raw.githubusercontent.com/USER/claude-framework/main/install.sh | bash

set -e

REPO_URL="https://github.com/USER/claude-framework"
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

# Initialize git if needed
if [ ! -d ".git" ]; then
    echo "📁 Initializing git repository..."
    git init
fi

# Clone the framework to temp directory
echo "📥 Downloading Claude PM Framework..."
rm -rf "$TEMP_DIR"
git clone --depth 1 "$REPO_URL" "$TEMP_DIR" 2>/dev/null || {
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

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
echo "║                              SETUP COMPLETE!                                  ║"
echo "╚═══════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "The Claude PM Framework has been installed in your project."
echo ""
echo "NEXT STEPS:"
echo "───────────"
echo "1. Start Claude Code:  claude"
echo "2. Invoke the PM:      /pm your-project-name"
echo "3. Describe what to build"
echo ""
echo "EXAMPLE:"
echo "────────"
echo "  $ claude"
echo "  > /pm my-app"
echo "  > Build a REST API with authentication and PostgreSQL"
echo ""
echo "The PM will handle: Plan → Design → Implement → Test → Review → Deploy"
echo ""
