#!/usr/bin/env node

/**
 * Claude PM Framework Setup Script
 *
 * Run this in any empty folder to scaffold the full PM framework:
 *   npx github:user/claude-framework setup-pm
 *
 * Or copy this file and run:
 *   node setup-pm.js
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const REPO_URL = 'https://raw.githubusercontent.com/USER/claude-framework/main';

// Files to download from the framework repo
const FRAMEWORK_FILES = {
  '.claude/settings.json': 'settings.json',
  '.claude/commands/pm.md': 'commands/pm.md',
  '.claude/agents/architect.md': 'agents/architect.md',
  '.claude/agents/developer.md': 'agents/developer.md',
  '.claude/agents/tester.md': 'agents/tester.md',
  '.claude/agents/reviewer.md': 'agents/reviewer.md',
  '.claude/agents/devops.md': 'agents/devops.md',
  '.claude/agents/code-critic.md': 'agents/code-critic.md',
  '.claude/agents/standards-researcher.md': 'agents/standards-researcher.md',
  '.claude/hooks/git-commit-gate.js': 'hooks/git-commit-gate.js',
  '.claude/hooks/pr-workflow-monitor.js': 'hooks/pr-workflow-monitor.js',
  '.claude/hooks/session-start.js': 'hooks/session-start.js',
  '.claude/hooks/stop-check.js': 'hooks/stop-check.js',
  '.claude/hooks/pre-compact.js': 'hooks/pre-compact.js',
  '.claude/hooks/pre-tool-use.js': 'hooks/pre-tool-use.js',
  '.claude/hooks/post-tool-use.js': 'hooks/post-tool-use.js',
  '.claude/hooks/subagent-stop.js': 'hooks/subagent-stop.js',
  '.github/workflows/branch-naming.yml': 'workflows/branch-naming.yml',
  '.github/workflows/pr-naming.yml': 'workflows/pr-naming.yml',
  '.github/workflows/lint.yml': 'workflows/lint.yml',
  '.github/workflows/test.yml': 'workflows/test.yml',
  '.github/workflows/security.yml': 'workflows/security.yml',
  '.github/workflows/ci.yml': 'workflows/ci.yml',
  '.github/workflows/commit-lint.yml': 'workflows/commit-lint.yml',
  '.github/pull_request_template.md': 'pull_request_template.md'
};

const DIRECTORIES = [
  '.claude',
  '.claude/commands',
  '.claude/agents',
  '.claude/hooks',
  '.claude/pm-state',
  '.github',
  '.github/workflows'
];

console.log(`
╔═══════════════════════════════════════════════════════════════════════════════╗
║                        CLAUDE PM FRAMEWORK SETUP                              ║
╚═══════════════════════════════════════════════════════════════════════════════╝
`);

// Check if we're in a git repo
const isGitRepo = fs.existsSync('.git');

if (!isGitRepo) {
  console.log('📁 Initializing git repository...');
  try {
    execSync('git init', { stdio: 'inherit' });
  } catch (e) {
    console.error('Failed to initialize git repo. Please run: git init');
  }
}

// Create directories
console.log('\n📂 Creating directory structure...');
for (const dir of DIRECTORIES) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
    console.log(`   ✓ Created ${dir}/`);
  } else {
    console.log(`   - ${dir}/ already exists`);
  }
}

console.log(`
╔═══════════════════════════════════════════════════════════════════════════════╗
║                              SETUP COMPLETE                                   ║
╚═══════════════════════════════════════════════════════════════════════════════╝

Directory structure created. Now you need to copy the framework files.

OPTION 1: Clone the framework repo and copy files
─────────────────────────────────────────────────
  git clone https://github.com/USER/claude-framework /tmp/cf
  cp -r /tmp/cf/.claude/* .claude/
  cp -r /tmp/cf/.github/* .github/

OPTION 2: If you have the framework locally
───────────────────────────────────────────
  cp -r /path/to/claude-framework/.claude/* .claude/
  cp -r /path/to/claude-framework/.github/* .github/

NEXT STEPS
──────────
1. Copy framework files (see above)
2. Start Claude Code in this directory
3. Run: /pm <project-name>
4. Describe what you want to build

EXAMPLE
───────
  $ claude
  > /pm my-saas-app
  > Build a SaaS application with user authentication,
  > subscription billing via Stripe, and a dashboard
  > showing usage metrics. Use Next.js 14, TypeScript,
  > Prisma with PostgreSQL, and Tailwind CSS.

The PM will then:
  1. PLAN - Gather requirements, create project scope
  2. DESIGN - Architecture, database schema, API design
  3. IMPLEMENT - Write all the code (with code-critic blocking bad commits)
  4. TEST - Write and run tests
  5. REVIEW - Code review pass
  6. DEPLOY - Setup deployment pipeline

`);
