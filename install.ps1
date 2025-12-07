# Claude PM Framework Installer for Windows
#
# Run in PowerShell (one-liner):
#   Invoke-WebRequest -Uri https://raw.githubusercontent.com/dev-brewery/claude-pm-framework/main/install.ps1 -OutFile install.ps1; .\install.ps1; Remove-Item install.ps1
#
# Or in Command Prompt (cmd.exe) with curl.exe:
#   curl.exe -fsSL https://raw.githubusercontent.com/dev-brewery/claude-pm-framework/main/install.ps1 -o install.ps1 && powershell -ExecutionPolicy Bypass -File install.ps1 && del install.ps1

$ErrorActionPreference = "Stop"

$REPO_URL = "https://github.com/dev-brewery/claude-pm-framework"
$TEMP_DIR = "$env:TEMP\claude-pm-framework-$(Get-Random)"

Write-Host ""
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "         CLAUDE PM FRAMEWORK INSTALLER                 " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

# Check if git is installed
try {
    $null = git --version
} catch {
    Write-Host "Error: git is not installed. Please install git first." -ForegroundColor Red
    exit 1
}

# ─────────────────────────────────────────────────────────────────────────────
# GitHub Token Detection
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "[*] Checking for GitHub credentials..." -ForegroundColor Yellow

# Look for GITHUB_TOKEN in Claude's global .env file
$ClaudeEnvPath = Join-Path $env:USERPROFILE ".claude\.env"
$GitHubToken = $env:GITHUB_TOKEN

if (-not $GitHubToken -and (Test-Path $ClaudeEnvPath)) {
    $EnvContent = Get-Content $ClaudeEnvPath -ErrorAction SilentlyContinue
    foreach ($line in $EnvContent) {
        if ($line -match '^GITHUB_TOKEN\s*=\s*[''"]?([^''"]+)[''"]?$') {
            $GitHubToken = $Matches[1]
            $env:GITHUB_TOKEN = $GitHubToken
            Write-Host "    [+] Found GITHUB_TOKEN in ~/.claude/.env" -ForegroundColor Green
            break
        }
    }
}

# Check if gh CLI is available
$GhAvailable = $false
try {
    $null = gh --version
    $GhAvailable = $true
    Write-Host "    [+] GitHub CLI (gh) is available" -ForegroundColor Green

    if ($GitHubToken) {
        Write-Host "    [+] GitHub CLI will use detected token" -ForegroundColor Green
    }
} catch {
    if ($GitHubToken) {
        Write-Host "    [!] GitHub CLI not installed, but token available for git operations" -ForegroundColor Yellow
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Repository Setup
# ─────────────────────────────────────────────────────────────────────────────

# Initialize git if needed
if (-not (Test-Path ".git")) {
    Write-Host "[*] Initializing git repository..." -ForegroundColor Yellow
    git init
}

# Clone the framework to temp directory
Write-Host "[*] Downloading Claude PM Framework..." -ForegroundColor Yellow
if (Test-Path $TEMP_DIR) {
    Remove-Item -Recurse -Force $TEMP_DIR
}

# Use token for clone if available (for private repos)
$CloneUrl = $REPO_URL
if ($GitHubToken) {
    $CloneUrl = "https://$GitHubToken@github.com/dev-brewery/claude-pm-framework.git"
}

# Clone - git outputs to stderr even on success, so we temporarily allow errors
$ErrorActionPreference = "Continue"
git clone --depth 1 $CloneUrl $TEMP_DIR 2>$null
$ErrorActionPreference = "Stop"

# Check if clone succeeded
if (-not (Test-Path "$TEMP_DIR\.claude")) {
    Write-Host "Error: Failed to clone repository. Check the URL and your network connection." -ForegroundColor Red
    exit 1
}

# Create directories if they don't exist
Write-Host "[*] Setting up directory structure..." -ForegroundColor Yellow
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
        $null = New-Item -ItemType Directory -Path $dir -Force
    }
}

# Copy framework files
Write-Host "[*] Copying framework files..." -ForegroundColor Yellow

# Copy .claude directory
if (Test-Path "$TEMP_DIR\.claude") {
    Copy-Item -Path "$TEMP_DIR\.claude\*" -Destination ".claude\" -Recurse -Force
    Write-Host "    [+] Copied .claude/ files" -ForegroundColor Green
}

# Copy .github directory
if (Test-Path "$TEMP_DIR\.github") {
    Copy-Item -Path "$TEMP_DIR\.github\*" -Destination ".github\" -Recurse -Force
    Write-Host "    [+] Copied .github/ files" -ForegroundColor Green
}

# Cleanup
Remove-Item -Recurse -Force $TEMP_DIR -ErrorAction SilentlyContinue

# ─────────────────────────────────────────────────────────────────────────────
# GitHub Repository Creation (Optional)
# ─────────────────────────────────────────────────────────────────────────────
$RepoCreated = $false
$NewRepoUrl = ""

if ($GhAvailable -and $GitHubToken) {
    Write-Host ""
    Write-Host "[*] GitHub Integration Available" -ForegroundColor Cyan
    Write-Host "-----------------------------------"

    # Get the directory name for repo name suggestion
    $SuggestedName = Split-Path -Leaf (Get-Location)

    Write-Host "Would you like to create a GitHub repository for this project?"
    Write-Host "  Repository name: $SuggestedName"
    Write-Host ""
    $CreateRepo = Read-Host "Create GitHub repo? [y/N]"

    if ($CreateRepo -match '^[Yy]$') {
        Write-Host ""
        $MakePublic = Read-Host "Make repository public? [y/N]"

        $Visibility = "--private"
        if ($MakePublic -match '^[Yy]$') {
            $Visibility = "--public"
        }

        Write-Host "[*] Creating GitHub repository..." -ForegroundColor Yellow
        try {
            $result = gh repo create $SuggestedName $Visibility --source=. --push 2>&1
            if ($LASTEXITCODE -eq 0) {
                $RepoCreated = $true
                Write-Host "    [+] Repository created and code pushed!" -ForegroundColor Green
                $NewRepoUrl = gh repo view --json url -q .url 2>&1
            } else {
                Write-Host "    [!] Repository creation failed (may already exist)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "    [!] Repository creation failed: $_" -ForegroundColor Yellow
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Complete
# ─────────────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=======================================================" -ForegroundColor Green
Write-Host "                   SETUP COMPLETE!                     " -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
Write-Host ""
Write-Host "The Claude PM Framework has been installed in your project."
Write-Host ""

if ($RepoCreated -and $NewRepoUrl) {
    Write-Host "GitHub Repository: $NewRepoUrl" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "-----------"
Write-Host "1. Start Claude Code:  claude"
Write-Host "2. Invoke the PM:      /pm your-project-name"
Write-Host "3. Describe what to build"
Write-Host ""
Write-Host "EXAMPLE:" -ForegroundColor Yellow
Write-Host "--------"
Write-Host "  PS> claude"
Write-Host "  claude> /pm my-app"
Write-Host "  claude> Build a REST API with authentication and PostgreSQL"
Write-Host ""
Write-Host "The PM will handle: Plan -> Design -> Implement -> Test -> Review -> Deploy"
Write-Host ""

if (-not $GitHubToken) {
    Write-Host "TIP: Add GITHUB_TOKEN to ~/.claude/.env for GitHub integration:" -ForegroundColor Yellow
    Write-Host "     Add this line: GITHUB_TOKEN=ghp_your_token_here" -ForegroundColor Gray
    Write-Host ""
}
