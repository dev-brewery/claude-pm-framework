# Claude PM Framework

A complete **Project Manager framework** for Claude Code that orchestrates the full Software Development Life Cycle (SDLC) with unyielding quality gates and GitHub workflow integration.

## Features

- **Full SDLC Orchestration**: Plan → Design → Implement → Test → Review → Deploy
- **Unyielding Code Critic**: Blocks ALL subpar commits with a 3-phase Paranoia Protocol
- **GitHub Integration**: Monitors workflows, auto-remediates failures
- **Context Management**: Survives context compaction with mission checkpoints
- **Mission Persistence**: Cannot stop until all phases complete

## Quick Start

### Option 1: Clone and Copy

```bash
# In your new empty project folder
git init

# Clone the framework
git clone <this-repo-url> /tmp/claude-framework

# Copy the framework files
cp -r /tmp/claude-framework/.claude .
cp -r /tmp/claude-framework/.github .

# Start Claude Code
claude

# Invoke the PM with your project name and instructions
/pm my-project
```

### Option 2: Manual Setup

```bash
# Create directory structure
mkdir -p .claude/{commands,agents,hooks,pm-state}
mkdir -p .github/workflows

# Copy files from this repo to your project
# Then start Claude Code and run /pm
```

## Usage

### Starting a New Project

```bash
# Start Claude Code in your project directory
claude

# Invoke the Project Manager
/pm my-awesome-app
```

Then describe what you want to build:

```
Build a REST API with user authentication, rate limiting,
and PostgreSQL database. Use Express.js and TypeScript.
```

### The PM Will Execute

1. **PLAN Phase** (architect agent)
   - Gather requirements
   - Define project scope
   - Identify technical constraints

2. **DESIGN Phase** (architect agent)
   - System architecture
   - Database schema
   - API specifications
   - Component design

3. **IMPLEMENT Phase** (developer agent)
   - Write production code
   - Every commit blocked by code-critic
   - Paranoia Protocol for 10+ file changes

4. **TEST Phase** (tester agent)
   - Unit tests
   - Integration tests
   - Coverage requirements

5. **REVIEW Phase** (reviewer agent)
   - Code review pass
   - Security review
   - Performance review

6. **DEPLOY Phase** (devops agent)
   - CI/CD setup
   - Deployment configuration
   - Production readiness

## The Code Critic

The code-critic agent is an **unyielding gatekeeper** that blocks every commit until code meets quality standards.

### What It Checks

- **Code Style**: Formatting, naming, no debug statements
- **TypeScript**: Proper types, no `any` without justification
- **Security**: No hardcoded secrets, SQL injection, XSS
- **Testing**: New code must have tests
- **Architecture**: Single responsibility, no circular deps

### Paranoia Protocol

When reviewing **10+ files** with no issues found:

1. **Phase 1**: Standard review (linting, tests, security scan)
2. **Phase 2**: Deep inspection (15 micro-checks including whitespace, import order, etc.)
3. **Phase 3**: Spawns `standards-researcher` agent to search current best practices

Only after passing all three phases will a large changeset be approved.

## Two-Stage Quality Gate

The framework implements a **two-stage quality gate** before code reaches GitHub:

```
┌─────────────────────────────────────────────────────────────────────┐
│  STAGE 1: git commit                                                │
│  ─────────────────────                                              │
│  git-commit-gate.js invokes code-critic agent                       │
│                                                                     │
│  ✓ Code style check                                                 │
│  ✓ TypeScript types                                                 │
│  ✓ Security scan                                                    │
│  ✓ Test existence                                                   │
│  ✓ Architecture review                                              │
│  ✓ Paranoia Protocol (10+ files)                                    │
│                                                                     │
│  ❌ BLOCKED until all checks pass                                   │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STAGE 2: git push                                                  │
│  ─────────────────                                                  │
│  git-push-gate.js runs LOCAL versions of GitHub CI                  │
│                                                                     │
│  ✓ Branch naming convention                                         │
│  ✓ Commit message lint                                              │
│  ✓ ESLint / Prettier                                                │
│  ✓ TypeScript compilation                                           │
│  ✓ Test suite                                                       │
│  ✓ npm audit (security)                                             │
│                                                                     │
│  ❌ BLOCKED until all checks pass                                   │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│  GitHub Actions (should pass - we pre-validated!)                   │
└─────────────────────────────────────────────────────────────────────┘
```

This ensures GitHub Actions have the **best chance of passing** on the first try.

## File Structure

```
your-project/
├── .claude/
│   ├── settings.json           # Hook configurations
│   ├── commands/
│   │   └── pm.md              # Main /pm command
│   ├── agents/
│   │   ├── architect.md       # Plan & Design phases
│   │   ├── developer.md       # Implementation
│   │   ├── tester.md          # Testing
│   │   ├── reviewer.md        # Code review
│   │   ├── devops.md          # Deployment
│   │   ├── code-critic.md     # Quality gatekeeper
│   │   └── standards-researcher.md  # Paranoia Protocol backup
│   ├── hooks/
│   │   ├── git-commit-gate.js     # STAGE 1: Blocks commits until code-critic approves
│   │   ├── git-push-gate.js       # STAGE 2: Runs local CI before push
│   │   ├── pr-workflow-monitor.js # Monitors GitHub Actions
│   │   ├── session-start.js       # Loads mission state
│   │   ├── stop-check.js          # Prevents premature stopping
│   │   ├── pre-compact.js         # Checkpoints before compact
│   │   ├── pre-tool-use.js        # Protects critical files
│   │   ├── post-tool-use.js       # Tracks file changes
│   │   └── subagent-stop.js       # Validates agent completion
│   └── pm-state/
│       ├── project-state.json     # Current phase, mission status
│       ├── task-tracker.json      # All tasks with status
│       ├── decisions.json         # Architectural decisions
│       ├── audit-log.json         # All operations performed
│       └── technical-debt.json    # Blocked features
├── .github/
│   ├── workflows/
│   │   ├── branch-naming.yml      # Branch name validation
│   │   ├── pr-naming.yml          # PR title validation
│   │   ├── commit-lint.yml        # Commit message linting
│   │   ├── lint.yml               # Code linting
│   │   ├── test.yml               # Test runner
│   │   ├── security.yml           # Security scanning
│   │   └── ci.yml                 # Main CI pipeline
│   └── pull_request_template.md   # PR template
```

## Hooks Reference

| Hook | Trigger | Purpose |
|------|---------|---------|
| `git-commit-gate.js` | PreToolUse | **STAGE 1**: Blocks commits until code-critic approves |
| `git-push-gate.js` | PreToolUse | **STAGE 2**: Runs local CI checks before push |
| `pr-workflow-monitor.js` | PostToolUse | Monitors GitHub Actions, handles failures |
| `session-start.js` | SessionStart | Loads PM mission state on startup |
| `stop-check.js` | Stop | Prevents stopping before mission completion |
| `pre-compact.js` | PreCompact | Saves checkpoint before context compaction |
| `pre-tool-use.js` | PreToolUse | Protects critical files from modification |
| `post-tool-use.js` | PostToolUse | Tracks all file changes in audit log |
| `subagent-stop.js` | SubagentStop | Validates agents complete their tasks |

## GitHub Workflows

| Workflow | Purpose |
|----------|---------|
| `branch-naming.yml` | Enforces `<type>/<description>` branch names |
| `pr-naming.yml` | Validates Conventional Commits PR titles |
| `commit-lint.yml` | Lints commit messages |
| `lint.yml` | ESLint, Prettier, TypeScript checks |
| `test.yml` | Runs tests across Node 18/20/22 |
| `security.yml` | npm audit, secrets scan, CodeQL |
| `ci.yml` | Main pipeline: lint → test → build |

## Resuming a Mission

If Claude Code context is compacted or you start a new session:

```
/pm my-project --resume
```

The PM will reload state from the last checkpoint and continue from where it left off.

## Configuration

### Customizing the Code Critic

Edit `.claude/agents/code-critic.md` to adjust quality standards:

- Modify rejection criteria
- Add project-specific rules
- Adjust Paranoia Protocol thresholds

### Customizing Workflows

Edit files in `.github/workflows/` to:

- Change Node.js versions
- Add custom linting rules
- Modify coverage thresholds
- Add deployment steps

## Example Projects

### SaaS Application

```
/pm my-saas

Build a SaaS application with:
- User authentication (OAuth + email/password)
- Subscription billing via Stripe
- Team workspaces with role-based access
- Usage metrics dashboard
- REST API with rate limiting

Tech stack: Next.js 14, TypeScript, Prisma, PostgreSQL, Tailwind CSS
```

### CLI Tool

```
/pm my-cli

Build a CLI tool that:
- Parses markdown files and extracts code blocks
- Validates code syntax for multiple languages
- Outputs formatted reports
- Supports config file for rules

Tech stack: Node.js, TypeScript, Commander.js
```

### API Backend

```
/pm my-api

Build a REST API with:
- JWT authentication
- CRUD operations for users, posts, comments
- File upload to S3
- Webhook integrations
- OpenAPI documentation

Tech stack: Express.js, TypeScript, Prisma, PostgreSQL
```

## License

MIT
