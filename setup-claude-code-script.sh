#!/bin/bash

# Claude Code Multi-Agent Project Structure Setup Script
# This script creates a complete folder structure for Claude Code with multi-agent support

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the target directory from user or use current directory
if [ "$1" ]; then
    TARGET_DIR="$1"
else
    TARGET_DIR="claude-code-workspace"
fi

print_info "Setting up Claude Code workspace in: $TARGET_DIR"

# Create main directory structure
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# Create root structure
print_info "Creating root folder structure..."
mkdir -p .claude-code/agents
mkdir -p .claude-code/templates
mkdir -p new-projects/.claude-code/agents
mkdir -p new-projects/.claude-code/planning-templates
mkdir -p new-projects/projects
mkdir -p feature-development/.claude-code/agents
mkdir -p feature-development/.claude-code/safeguards
mkdir -p feature-development/.claude-code/templates
mkdir -p feature-development/features

# Create global configuration
print_info "Creating global configuration..."
cat > .claude-code/config.yml << 'EOF'
# Global Claude Code Configuration
version: 1.0

defaults:
  thinking_mode: "think"  # Options: think, think hard, think harder, ultrathink
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
EOF

# Create README files
print_info "Creating documentation..."

cat > README.md << 'EOF'
# Claude Code Multi-Agent Workspace

This workspace is configured for safe, efficient multi-agent development using Claude Code.

## Structure

- `new-projects/` - For greenfield development
- `feature-development/` - For adding features to existing projects
- `.claude-code/` - Global configuration and agents

## Quick Start

### For New Projects:
```bash
cd new-projects
claude -p "ultrathink about creating a [YOUR PROJECT TYPE] application"
```

### For Feature Development:
```bash
cd feature-development
claude -p "Feature-analyzer: analyze the impact of [YOUR FEATURE] on [PROJECT PATH]"
```

## Safety Features

- Protected files that cannot be modified
- Regression testing after changes
- Mandatory analysis before modification
- Agent-specific boundaries

See individual README files in each directory for detailed usage.
EOF

cat > new-projects/README.md << 'EOF'
# New Projects

This directory is for creating new projects from scratch using multiple specialized agents.

## Workflow

1. **Planning Phase**
   ```bash
   claude -p "think harder about creating [PROJECT DESCRIPTION]. Create a detailed plan but don't code yet"
   ```

2. **Architecture Phase**
   ```bash
   claude -p "Architect agent: design the system architecture based on the plan"
   ```

3. **Implementation Phase**
   ```bash
   claude -p "Backend-developer: implement the API and data models"
   claude -p "Frontend-developer: create the UI components"
   ```

4. **Testing Phase**
   ```bash
   claude -p "Tester: create comprehensive test suite"
   ```

5. **Review Phase**
   ```bash
   claude -p "Reviewer: check the implementation for best practices"
   ```

## Available Agents

- `architect` - System design and architecture
- `backend-developer` - API and server-side logic
- `frontend-developer` - UI and client-side code
- `tester` - Test creation and validation
- `reviewer` - Code review and quality checks

## Tips

- Always start with planning mode
- Let each agent focus on their specialty
- Commit after each successful phase
- Use feature branches for parallel development
EOF

cat > feature-development/README.md << 'EOF'
# Feature Development

This directory is for safely adding features to existing projects without causing regressions.

## CRITICAL: Safety-First Workflow

### Phase 1: Analysis (MANDATORY)
```bash
claude -p "Feature-analyzer: analyze the impact of adding [FEATURE] to [PROJECT PATH]"
```

### Phase 2: Review Impact
- Review the generated impact analysis
- Approve the list of files to be modified
- Update protected-files.txt if needed

### Phase 3: Implementation
```bash
claude -p "Safe-developer: implement [FEATURE] following the impact analysis, modifying ONLY approved files"
```

### Phase 4: Verification
```bash
claude -p "Regression-guard: verify no existing functionality was broken"
```

### Phase 5: Integration Testing
```bash
claude -p "Integration-tester: test the new feature with existing functionality"
```

## Available Agents

- `feature-analyzer` - READ-ONLY analysis of impact
- `safe-developer` - Constrained implementation
- `regression-guard` - Regression testing
- `integration-tester` - Integration validation
- `pr-reviewer` - Pull request preparation

## Safety Features

- Protected files list (cannot be modified)
- Mandatory analysis before changes
- Regression testing gates
- Rollback procedures

## Emergency Procedures

If something goes wrong:
```bash
claude -p "Create a git stash of all changes and checkout main branch"
claude -p "Run all tests to verify system stability"
```
EOF

# Create New Projects Agents
print_info "Creating agents for new projects..."

cat > new-projects/.claude-code/agents/architect.yml << 'EOF'
---
name: architect
description: Use for initial project architecture, technology decisions, and high-level design
tools: Read, Write, Bash
---
You are a senior software architect. Your role is to:

1. Analyze project requirements thoroughly
2. Design scalable, maintainable architecture
3. Create detailed technical specifications
4. Define clear interfaces between components
5. Document architectural decisions (ADRs)
6. Set up project structure and boilerplate

Key practices:
- Use industry best practices and design patterns
- Consider non-functional requirements (performance, security, scalability)
- Create clear separation of concerns
- Document all major decisions with rationale
- Define clear contracts between components

Output format:
- Architecture diagrams (using mermaid or ASCII)
- Component specifications
- API contracts
- Database schemas
- Technology stack justification

IMPORTANT: Do NOT write implementation code. Focus only on design and planning.
EOF

cat > new-projects/.claude-code/agents/backend-developer.yml << 'EOF'
---
name: backend-developer
description: Use for API development, database work, and server-side logic
tools: Read, Write, Bash, Git
---
You are a backend developer specializing in clean, testable code.

Core responsibilities:
1. Implement APIs according to specifications
2. Write database migrations and models
3. Implement business logic with proper error handling
4. Create comprehensive unit tests
5. Ensure code follows project conventions

Standards:
- Write tests BEFORE implementation (TDD)
- Use dependency injection for testability
- Implement proper logging and monitoring
- Follow RESTful or GraphQL best practices
- Handle errors gracefully with meaningful messages
- Validate all inputs
- Use transactions for data consistency

CONSTRAINTS:
- Only modify files in backend/ or api/ directories
- Do not touch frontend code
- Always run tests before committing
EOF

cat > new-projects/.claude-code/agents/frontend-developer.yml << 'EOF'
---
name: frontend-developer
description: Use for UI components, state management, and user interactions
tools: Read, Write, Bash, Git
---
You are a frontend developer focused on user experience and code quality.

Responsibilities:
1. Implement UI components according to designs
2. Manage application state efficiently
3. Handle user interactions and validations
4. Ensure accessibility (WCAG compliance)
5. Optimize performance and bundle size

Standards:
- Write component tests alongside implementation
- Use semantic HTML
- Implement responsive design
- Follow project's component patterns
- Handle loading and error states
- Optimize for Core Web Vitals
- Implement proper error boundaries

CONSTRAINTS:
- Only modify files in frontend/, src/, or client/ directories
- Do not modify backend APIs
- Always test in multiple viewport sizes
EOF

cat > new-projects/.claude-code/agents/tester.yml << 'EOF'
---
name: tester
description: Use for creating comprehensive test suites and validation
tools: Read, Write, Bash, Git
---
You are a QA engineer focused on comprehensive testing.

Responsibilities:
1. Create unit tests for all functions
2. Write integration tests for APIs
3. Implement E2E tests for critical paths
4. Set up test infrastructure
5. Create test data factories

Testing strategy:
- Aim for >80% code coverage
- Test happy paths and edge cases
- Include negative test cases
- Test error handling
- Verify performance requirements
- Check security vulnerabilities

Test types to implement:
- Unit tests
- Integration tests
- E2E tests
- Performance tests
- Security tests

IMPORTANT: Focus on testing, not implementation. If you find bugs, document them but don't fix them.
EOF

cat > new-projects/.claude-code/agents/reviewer.yml << 'EOF'
---
name: reviewer
description: Use for code review and quality assurance
tools: Read, Bash, Git
---
You are a senior engineer performing code review.

Review checklist:
1. Code quality and readability
2. Design patterns and architecture
3. Performance implications
4. Security vulnerabilities
5. Test coverage
6. Documentation completeness
7. Error handling
8. Logging and monitoring

Focus areas:
- SOLID principles adherence
- DRY (Don't Repeat Yourself)
- KISS (Keep It Simple, Stupid)
- YAGNI (You Aren't Gonna Need It)
- Proper abstraction levels
- Consistent naming conventions
- Code comments where necessary

Output format:
- List of critical issues (must fix)
- List of major issues (should fix)
- List of minor issues (nice to fix)
- Positive feedback on good practices
- Suggestions for improvement

IMPORTANT: You are READ-ONLY. Document findings but do not modify code.
EOF

# Create Feature Development Agents
print_info "Creating agents for feature development..."

cat > feature-development/.claude-code/agents/feature-analyzer.yml << 'EOF'
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
EOF

cat > feature-development/.claude-code/agents/safe-developer.yml << 'EOF'
---
name: safe-developer
description: Use for implementing features with strict boundaries and safety checks
tools: Read, Write, Bash, Git
---
You are a careful developer who prioritizes system stability.

Before ANY modification:
1. Check if file is in protected list (check .claude-code/safeguards/protected-files.txt)
2. Run existing tests to ensure baseline
3. Create a backup branch
4. Document what you're about to change

Implementation rules:
- ONLY modify files explicitly listed in the feature plan
- Create feature flags for new functionality
- Write tests BEFORE implementation
- Use defensive programming patterns
- Add comprehensive error handling
- Log all important operations
- Create rollback procedures

After implementation:
- Run ALL existing tests
- Verify no regressions introduced
- Document changes made
- Create integration tests

FORBIDDEN ACTIONS:
- Modifying core configuration files
- Changing existing API contracts
- Removing existing functionality
- Modifying files outside feature scope
- Skipping tests
EOF

cat > feature-development/.claude-code/agents/regression-guard.yml << 'EOF'
---
name: regression-guard
description: Use after any changes to verify no regressions were introduced
tools: Read, Bash, Git
---
You are a quality assurance specialist focused on preventing regressions.

Your verification process:
1. Run full test suite
2. Compare test results with baseline
3. Check for performance degradation
4. Verify API backward compatibility
5. Check for security vulnerabilities
6. Validate data migrations (if any)
7. Test error handling paths

If regressions found:
- Document exactly what broke
- Identify the breaking change
- Suggest minimal fix
- DO NOT attempt to fix yourself

Report format:
- Test results summary
- Regression findings (if any)
- Performance metrics comparison
- Security scan results
- Recommendation (proceed/revert/fix)
EOF

cat > feature-development/.claude-code/agents/integration-tester.yml << 'EOF'
---
name: integration-tester
description: Use to test new features with existing functionality
tools: Read, Write, Bash, Git
---
You are an integration testing specialist.

Your focus:
1. Test new feature with existing features
2. Verify data flow between components
3. Check API contract compatibility
4. Test edge cases and boundaries
5. Verify error propagation
6. Test concurrent operations
7. Validate state management

Test creation:
- Write integration tests for new features
- Update existing tests if needed
- Create test fixtures and mocks
- Document test scenarios
- Set up test data

Coverage areas:
- Component interactions
- API integrations
- Database transactions
- Event handling
- State synchronization
- Cache invalidation

Output:
- Integration test suite
- Test results report
- Coverage metrics
- Performance impact analysis
EOF

cat > feature-development/.claude-code/agents/pr-reviewer.yml << 'EOF'
---
name: pr-reviewer
description: Use to prepare and review pull requests
tools: Read, Write, Bash, Git
---
You are a pull request specialist.

Your responsibilities:
1. Create comprehensive PR description
2. List all changes made
3. Document testing performed
4. Identify potential impacts
5. Create review checklist
6. Suggest reviewers
7. Add relevant labels

PR description template:
## Summary
Brief description of changes

## Changes Made
- List of modifications
- New files added
- Files removed

## Testing
- Tests added/modified
- Manual testing performed
- Performance impact

## Checklist
- [ ] Tests passing
- [ ] Documentation updated
- [ ] No regressions
- [ ] Security reviewed
- [ ] Performance verified

## Screenshots/Examples
(if applicable)

## Breaking Changes
(if any)

## Rollback Plan
Steps to revert if needed
EOF

# Create safeguard files
print_info "Creating safeguard configurations..."

cat > feature-development/.claude-code/safeguards/protected-files.txt << 'EOF'
# Files that should NEVER be modified by agents
# Add your project-specific protected files here

# Environment and secrets
.env
.env.production
.env.local
.env.*.local
*.key
*.pem
*.cert

# Package locks
package-lock.json
yarn.lock
pnpm-lock.yaml
Gemfile.lock
Cargo.lock
composer.lock

# Database
database/migrations/*
db/schema.rb
*/migrations/*.sql

# Configuration
config/database.yml
config/credentials.yml.enc
config/master.key
config/production.json
webpack.config.js
vite.config.js
tsconfig.json
.eslintrc.js
.prettierrc

# CI/CD
.github/workflows/*
.gitlab-ci.yml
.circleci/config.yml
Jenkinsfile
azure-pipelines.yml

# Infrastructure
Dockerfile
docker-compose.yml
docker-compose.*.yml
kubernetes/*.yaml
terraform/*
.terraform/*
ansible/*

# Build outputs
dist/*
build/*
out/*
.next/*
.nuxt/*

# IDE
.vscode/settings.json
.idea/*
EOF

cat > feature-development/.claude-code/safeguards/allowed-patterns.yml << 'EOF'
# Patterns for safe modifications
allowed_paths:
  new_files:
    - "src/features/*/.*"
    - "src/components/*/.*"
    - "tests/features/*/.*"
    - "tests/unit/*/.*"
    - "docs/features/*/.*"
  
  modifications:
    - "src/components/[component-name]/*"
    - "src/services/[service-name]/*"
    - "src/utils/*"
    - "tests/unit/*"
    - "tests/integration/*"
    - "README.md"
    - "docs/*"

forbidden_patterns:
  - "**/node_modules/**"
  - "**/.git/**"
  - "**/build/**"
  - "**/dist/**"
  - "**/*.min.js"
  - "**/*.min.css"
  - "**/*.lock"
  - "**/vendor/**"
  - "**/.env*"
EOF

cat > feature-development/.claude-code/safeguards/regression-tests.yml << 'EOF'
# Regression test configuration
regression_tests:
  pre_modification:
    - name: "Baseline Tests"
      command: "npm test"
      expected_result: "pass"
      mandatory: true
    
    - name: "Lint Check"
      command: "npm run lint"
      expected_result: "no-errors"
      mandatory: false
    
    - name: "Type Check"
      command: "npm run type-check"
      expected_result: "pass"
      mandatory: true

  post_modification:
    - name: "Full Test Suite"
      command: "npm test"
      expected_result: "pass"
      mandatory: true
    
    - name: "Integration Tests"
      command: "npm run test:integration"
      expected_result: "pass"
      mandatory: true
    
    - name: "E2E Tests"
      command: "npm run test:e2e"
      expected_result: "pass"
      mandatory: false
    
    - name: "Performance Tests"
      command: "npm run test:performance"
      expected_result: "no-degradation"
      mandatory: false

  metrics_to_track:
    - test_coverage
    - build_time
    - bundle_size
    - memory_usage
    - response_time
EOF

# Create planning templates
print_info "Creating planning templates..."

cat > new-projects/.claude-code/planning-templates/project-kickoff.md << 'EOF'
# New Project: [PROJECT_NAME]
Date: [DATE]
Claude Code Session ID: [SESSION_ID]

## Project Overview
**Description**: [Brief description]
**Type**: [Web App / API / CLI / Library / etc.]
**Primary Goal**: [What problem does this solve?]

## Phase 1: Planning (Use 'think harder' mode)
- [ ] Define requirements
- [ ] Identify constraints
- [ ] Choose technology stack
- [ ] Create architecture design
- [ ] Define success metrics

## Phase 2: Foundation
- [ ] Set up project structure
- [ ] Configure development environment
- [ ] Set up version control
- [ ] Create CI/CD pipeline
- [ ] Set up testing framework

## Phase 3: Core Implementation
- [ ] Implement data models
- [ ] Create API endpoints
- [ ] Build UI components
- [ ] Implement business logic
- [ ] Add authentication/authorization

## Phase 4: Testing & Quality
- [ ] Write unit tests
- [ ] Create integration tests
- [ ] Perform security audit
- [ ] Optimize performance
- [ ] Add monitoring/logging

## Phase 5: Documentation & Deployment
- [ ] Write API documentation
- [ ] Create user guide
- [ ] Set up deployment pipeline
- [ ] Deploy to staging
- [ ] Deploy to production

## Agent Assignment
- Architect: Phase 1
- Backend-developer: Phase 2-3 (backend)
- Frontend-developer: Phase 2-3 (frontend)
- Tester: Phase 4
- Reviewer: Phase 4-5

## Success Criteria
- [ ] All tests passing
- [ ] >80% code coverage
- [ ] Performance benchmarks met
- [ ] Security scan passed
- [ ] Documentation complete
EOF

cat > new-projects/.claude-code/planning-templates/architecture-plan.md << 'EOF'
# Architecture Plan: [PROJECT_NAME]

## System Overview
[High-level description of the system]

## Technology Stack
### Frontend
- Framework: [React/Vue/Angular/etc.]
- State Management: [Redux/MobX/Vuex/etc.]
- Styling: [CSS/SASS/Tailwind/etc.]
- Build Tool: [Webpack/Vite/etc.]

### Backend
- Runtime: [Node.js/Python/Java/etc.]
- Framework: [Express/FastAPI/Spring/etc.]
- Database: [PostgreSQL/MongoDB/etc.]
- Cache: [Redis/Memcached/etc.]

### Infrastructure
- Hosting: [AWS/GCP/Azure/etc.]
- Container: [Docker/Kubernetes/etc.]
- CI/CD: [GitHub Actions/Jenkins/etc.]
- Monitoring: [Datadog/New Relic/etc.]

## Architecture Diagram
```
[ASCII or Mermaid diagram]
```

## Component Design

### Frontend Components
1. **Component Name**
   - Purpose:
   - Props:
   - State:
   - Dependencies:

### Backend Services
1. **Service Name**
   - Purpose:
   - Endpoints:
   - Dependencies:
   - Data Models:

## API Design
### Endpoints
- `GET /api/resource` - Description
- `POST /api/resource` - Description
- `PUT /api/resource/:id` - Description
- `DELETE /api/resource/:id` - Description

## Database Schema
```sql
-- Table definitions
```

## Security Considerations
- Authentication method:
- Authorization strategy:
- Data encryption:
- Input validation:
- Rate limiting:

## Performance Requirements
- Response time: <X ms
- Throughput: X requests/second
- Concurrent users: X
- Data volume: X GB

## Scalability Plan
- Horizontal scaling strategy:
- Caching strategy:
- Database sharding:
- Load balancing:

## Monitoring & Logging
- Metrics to track:
- Log aggregation:
- Alert thresholds:
- Dashboard requirements:
EOF

cat > feature-development/.claude-code/templates/feature-analysis.md << 'EOF'
# Feature Analysis: [FEATURE_NAME]
Date: [DATE]
Target Project: [PROJECT_PATH]
Analyst: feature-analyzer agent

## Feature Description
[What is being added/changed]

## Impact Analysis

### Affected Components
| Component | File Path | Impact Level | Risk |
|-----------|-----------|--------------|------|
| [name] | [path] | High/Medium/Low | [description] |

### Dependencies Map
```
[ASCII or Mermaid diagram showing dependencies]
```

### Files to Modify
**Safe to Modify:**
- [ ] file1.js - Reason
- [ ] file2.py - Reason

**Requires Careful Review:**
- [ ] file3.tsx - Reason
- [ ] file4.go - Reason

**DO NOT MODIFY:**
- ❌ critical-file1.js - Reason
- ❌ critical-file2.yml - Reason

## Risk Assessment

### Regression Risks
1. **Risk**: [Description]
   **Mitigation**: [Strategy]
   **Test**: [How to verify]

### Performance Impact
- Expected impact: [None/Minor/Major]
- Metrics affected: [List]
- Mitigation needed: [Yes/No]

### Security Implications
- New attack vectors: [None/List]
- Data exposure risks: [None/List]
- Required validations: [List]

## Implementation Plan

### Step 1: Preparation
- [ ] Create feature branch
- [ ] Run baseline tests
- [ ] Document current behavior

### Step 2: Implementation
- [ ] Modify allowed files only
- [ ] Add feature flag (if needed)
- [ ] Write tests first (TDD)

### Step 3: Testing
- [ ] Unit tests
- [ ] Integration tests
- [ ] Regression tests
- [ ] Performance tests

### Step 4: Validation
- [ ] Code review
- [ ] Security scan
- [ ] Performance benchmark

## Rollback Plan
1. Revert commits: `git revert [commits]`
2. Disable feature flag: [if applicable]
3. Restore database: [if needed]
4. Clear cache: [if needed]

## Test Coverage
Current coverage: X%
Required coverage: Y%
New tests needed: [List]

## Approval Checklist
- [ ] Impact analysis reviewed
- [ ] Risks acceptable
- [ ] Rollback plan ready
- [ ] Tests identified
- [ ] Team notified

## Notes
[Any additional considerations]
EOF

cat > feature-development/.claude-code/templates/integration-plan.md << 'EOF'
# Integration Plan: [FEATURE_NAME]

## Integration Points
1. **Component A ↔ Component B**
   - Interface: [API/Event/Direct]
   - Data flow: [Description]
   - Error handling: [Strategy]

## Test Scenarios

### Happy Path
1. Scenario: [Description]
   - Input: [Data]
   - Expected: [Result]
   - Validation: [How to verify]

### Edge Cases
1. Scenario: [Description]
   - Input: [Data]
   - Expected: [Result]
   - Validation: [How to verify]

### Error Cases
1. Scenario: [Description]
   - Input: [Data]
   - Expected: [Error handling]
   - Validation: [How to verify]

## Performance Criteria
- Response time: <X ms
- Memory usage: <X MB
- CPU usage: <X%

## Monitoring
- Metrics to track:
- Alerts to set up:
- Dashboard updates:

## Deployment Strategy
1. Deploy to development
2. Run integration tests
3. Deploy to staging
4. Run E2E tests
5. Gradual rollout to production

## Rollback Triggers
- [ ] Test failures >X%
- [ ] Response time >X ms
- [ ] Error rate >X%
- [ ] Memory usage >X GB
EOF

# Create example VS Code tasks
print_info "Creating VS Code integration..."

mkdir -p .vscode
cat > .vscode/tasks.json << 'EOF'
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Claude: Analyze Feature Impact",
      "type": "shell",
      "command": "cd feature-development && claude -p \"Feature-analyzer: analyze the impact of ${input:featureName} on ${input:projectPath}\"",
      "group": "claude",
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    },
    {
      "label": "Claude: New Project Planning",
      "type": "shell",
      "command": "cd new-projects && claude -p \"think harder about creating a ${input:projectType} application for ${input:projectPurpose}\"",
      "group": "claude",
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    },
    {
      "label": "Claude: Run Regression Tests",
      "type": "shell",
      "command": "cd feature-development && claude -p \"Regression-guard: verify no existing functionality was broken\"",
      "group": "claude",
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    },
    {
      "label": "Claude: Safe Implementation",
      "type": "shell",
      "command": "cd feature-development && claude -p \"Safe-developer: implement the feature following the impact analysis, modifying ONLY approved files\"",
      "group": "claude",
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    }
  ],
  "inputs": [
    {
      "id": "featureName",
      "type": "promptString",
      "description": "Feature name/description"
    },
    {
      "id": "projectPath",
      "type": "promptString",
      "description": "Path to existing project"
    },
    {
      "id": "projectType",
      "type": "pickString",
      "description": "Project type",
      "options": [
        "React + Node.js",
        "Vue + FastAPI",
        "Next.js Full-Stack",
        "Angular + Spring Boot",
        "CLI Tool",
        "API Service",
        "Other"
      ]
    },
    {
      "id": "projectPurpose",
      "type": "promptString",
      "description": "What will this project do?"
    }
  ]
}
EOF

# Create quick start script
print_info "Creating quick start scripts..."

cat > start-new-project.sh << 'EOF'
#!/bin/bash
# Quick start script for new projects

echo "Starting new project with Claude Code..."
echo "======================================="
echo ""
read -p "Project name: " PROJECT_NAME
read -p "Project type (web/api/cli): " PROJECT_TYPE
read -p "Brief description: " DESCRIPTION

cd new-projects
mkdir -p "projects/$PROJECT_NAME"
cd "projects/$PROJECT_NAME"

echo "Initiating planning phase..."
claude -p "think harder about creating a $PROJECT_TYPE application called $PROJECT_NAME. $DESCRIPTION. Create a detailed plan but don't code yet."

echo ""
echo "After reviewing the plan, you can proceed with:"
echo "  claude -p \"Architect agent: design the system architecture\""
echo "  claude -p \"Backend-developer: implement the backend\""
echo "  claude -p \"Frontend-developer: implement the frontend\""
EOF
chmod +x start-new-project.sh

cat > add-feature.sh << 'EOF'
#!/bin/bash
# Quick start script for adding features

echo "Adding feature to existing project..."
echo "====================================="
echo ""
read -p "Feature name: " FEATURE_NAME
read -p "Project path: " PROJECT_PATH
read -p "Brief description: " DESCRIPTION

cd feature-development
mkdir -p "features/$FEATURE_NAME"
cd "features/$FEATURE_NAME"

echo "Phase 1: Analyzing impact (MANDATORY)..."
claude -p "Feature-analyzer: analyze the impact of adding $DESCRIPTION to the project at $PROJECT_PATH"

echo ""
echo "After reviewing the analysis, you can proceed with:"
echo "  claude -p \"Safe-developer: implement the feature following the impact analysis\""
echo "  claude -p \"Regression-guard: verify no regressions\""
echo "  claude -p \"Integration-tester: test integration\""
EOF
chmod +x add-feature.sh

# Create a gitignore file
cat > .gitignore << 'EOF'
# Claude Code
.claude-code-session/
*.backup

# Dependencies
node_modules/
venv/
env/
*.pyc
__pycache__/

# Build outputs
dist/
build/
out/
*.exe
*.dll
*.so
*.dylib

# IDE
.vscode/*
!.vscode/tasks.json
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Environment
.env
.env.*
!.env.example

# Test coverage
coverage/
.coverage
*.cover
.pytest_cache/

# Temporary
tmp/
temp/
*.tmp
EOF

# Create example environment file
cat > .env.example << 'EOF'
# Example environment file
# Copy to .env and fill in your values

# API Keys
ANTHROPIC_API_KEY=your_key_here
OPENAI_API_KEY=your_key_here

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/dbname

# Application
NODE_ENV=development
PORT=3000
HOST=localhost

# Feature Flags
ENABLE_NEW_FEATURE=false
ENABLE_BETA_FEATURES=false
EOF

# Final setup steps
print_success "Folder structure created successfully!"
echo ""
print_info "Setup complete! Here's what was created:"
echo ""
echo "📁 Directory Structure:"
echo "   ├── 📁 .claude-code/          (Global configuration)"
echo "   ├── 📁 new-projects/          (For new development)"
echo "   │   └── 📁 .claude-code/agents/"
echo "   ├── 📁 feature-development/   (For existing projects)"
echo "   │   └── 📁 .claude-code/agents/"
echo "   └── 📁 .vscode/               (VS Code integration)"
echo ""
echo "🤖 Agents Created:"
echo "   New Projects: architect, backend-developer, frontend-developer, tester, reviewer"
echo "   Features: feature-analyzer, safe-developer, regression-guard, integration-tester, pr-reviewer"
echo ""
echo "🛡️ Safety Features:"
echo "   ✓ Protected files list"
echo "   ✓ Regression test configuration"
echo "   ✓ Allowed patterns configuration"
echo "   ✓ Impact analysis templates"
echo ""
echo "🚀 Quick Start Commands:"
echo ""
echo "   For NEW projects:"
echo "   $ ./start-new-project.sh"
echo ""
echo "   For FEATURES in existing projects:"
echo "   $ ./add-feature.sh"
echo ""
echo "📝 VS Code Integration:"
echo "   Use Cmd/Ctrl+Shift+P → Tasks: Run Task → Claude:*"
echo ""
print_warning "IMPORTANT: For feature development, ALWAYS run the feature-analyzer agent first!"
echo ""
print_info "Next steps:"
echo "1. Review and customize the protected-files.txt for your projects"
echo "2. Adjust agent prompts for your specific tech stack"
echo "3. Set up any MCP connections you need (GitHub, Jira, etc.)"
echo "4. Start with a test project to familiarize yourself with the workflow"
echo ""
print_success "Happy coding with Claude Code! 🎉"