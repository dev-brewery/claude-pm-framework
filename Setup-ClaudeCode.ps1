# PowerShell Setup Script for Claude Code Workspace
param(
    [string]$TargetDir = "claude-code-workspace"
)

Write-Host "Setting up Claude Code workspace in: $TargetDir" -ForegroundColor Blue

# Create main directory structure
New-Item -ItemType Directory -Force -Path "$TargetDir"
Set-Location "$TargetDir"

# Create root structure
Write-Host "Creating folder structure..." -ForegroundColor Green
$folders = @(
    ".claude-code\agents",
    ".claude-code\templates",
    "new-projects\.claude-code\agents",
    "new-projects\.claude-code\planning-templates",
    "new-projects\projects",
    "feature-development\.claude-code\agents",
    "feature-development\.claude-code\safeguards",
    "feature-development\.claude-code\templates",
    "feature-development\features",
    ".vscode"
)

foreach ($folder in $folders) {
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
}

Write-Host "Creating configuration files..." -ForegroundColor Green

# Create global config (using here-strings for multi-line content)
@'
# Global Claude Code Configuration
version: 1.0

defaults:
  thinking_mode: "think"
  auto_commit: false
  test_before_commit: true
  
safeguards:
  require_analysis_before_modification: true
  protect_core_files: true
  max_files_per_operation: 10
  require_test_pass: true

planning:
  always_create_plan: true
  require_approval: true
  document_decisions: true

git:
  branch_naming: "feature/[agent-name]/[task-description]"
  commit_format: "[agent-name]: [change-description]"
  always_use_feature_branches: true
'@ | Out-File -FilePath ".claude-code\config.yml" -Encoding UTF8

Write-Host "Creating agent definitions..." -ForegroundColor Green

# Create each agent file (showing one example, repeat for all)
@'
---
name: feature-analyzer
description: Use FIRST to analyze existing code and plan safe feature implementation
tools: Read, Bash, Git
---
You are a code analyst specializing in understanding existing systems before modifications.

Your workflow:
1. Map the existing codebase structure
2. Identify all files that might be affected
3. Document current behavior and test coverage
4. Identify potential regression risks
5. Create a detailed impact analysis
6. Plan the safest implementation approach

Analysis outputs:
- Dependency graph of affected components
- Risk assessment matrix
- List of files that MUST NOT be modified
- List of files safe to modify
- Existing test coverage report
- Integration points documentation

CRITICAL: You are READ-ONLY. Never modify any files. Your job is analysis and planning only.
'@ | Out-File -FilePath "feature-development\.claude-code\agents\feature-analyzer.yml" -Encoding UTF8

# ... Continue creating all other files ...

Write-Host "Setup complete!" -ForegroundColor Green
Write-Host "Next: Open this folder in VS Code" -ForegroundColor Yellow