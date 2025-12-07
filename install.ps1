# Claude PM Framework Installer for Windows
# Run: irm https://raw.githubusercontent.com/USER/claude-framework/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

$REPO_URL = "https://github.com/USER/claude-framework"
$TEMP_DIR = "$env:TEMP\claude-pm-framework-$(Get-Random)"

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                        CLAUDE PM FRAMEWORK INSTALLER                          ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if git is installed
try {
    git --version | Out-Null
} catch {
    Write-Host "Error: git is not installed. Please install git first." -ForegroundColor Red
    exit 1
}

# Initialize git if needed
if (-not (Test-Path ".git")) {
    Write-Host "📁 Initializing git repository..." -ForegroundColor Yellow
    git init
}

# Clone the framework to temp directory
Write-Host "📥 Downloading Claude PM Framework..." -ForegroundColor Yellow
if (Test-Path $TEMP_DIR) {
    Remove-Item -Recurse -Force $TEMP_DIR
}

try {
    git clone --depth 1 $REPO_URL $TEMP_DIR 2>$null
} catch {
    Write-Host "Error: Failed to clone repository. Check the URL and your network connection." -ForegroundColor Red
    exit 1
}

# Create directories if they don't exist
Write-Host "📂 Setting up directory structure..." -ForegroundColor Yellow
$dirs = @(
    ".claude",
    ".claude\commands",
    ".claude\agents",
    ".claude\hooks",
    ".claude\pm-state",
    ".github",
    ".github\workflows"
)

foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# Copy framework files
Write-Host "📋 Copying framework files..." -ForegroundColor Yellow

# Copy .claude directory
if (Test-Path "$TEMP_DIR\.claude") {
    Copy-Item -Path "$TEMP_DIR\.claude\*" -Destination ".claude\" -Recurse -Force
    Write-Host "   ✓ Copied .claude/ files" -ForegroundColor Green
}

# Copy .github directory
if (Test-Path "$TEMP_DIR\.github") {
    Copy-Item -Path "$TEMP_DIR\.github\*" -Destination ".github\" -Recurse -Force
    Write-Host "   ✓ Copied .github/ files" -ForegroundColor Green
}

# Cleanup
Remove-Item -Recurse -Force $TEMP_DIR -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                              SETUP COMPLETE!                                  ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "The Claude PM Framework has been installed in your project."
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "───────────"
Write-Host "1. Start Claude Code:  " -NoNewline; Write-Host "claude" -ForegroundColor Cyan
Write-Host "2. Invoke the PM:      " -NoNewline; Write-Host "/pm your-project-name" -ForegroundColor Cyan
Write-Host "3. Describe what to build"
Write-Host ""
Write-Host "EXAMPLE:" -ForegroundColor Yellow
Write-Host "────────"
Write-Host '  $ claude'
Write-Host '  > /pm my-app'
Write-Host '  > Build a REST API with authentication and PostgreSQL'
Write-Host ""
Write-Host "The PM will handle: Plan → Design → Implement → Test → Review → Deploy"
Write-Host ""
