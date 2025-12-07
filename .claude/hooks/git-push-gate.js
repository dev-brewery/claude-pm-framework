#!/usr/bin/env node

/**
 * Git Push Gate Hook
 *
 * Runs local versions of GitHub CI workflows before allowing push.
 * This is the second quality gate after code-critic approves the commit.
 *
 * Flow:
 *   1. Developer writes code
 *   2. git commit → code-critic blocks until code quality passes
 *   3. git push → THIS HOOK runs local CI checks
 *   4. Only if all checks pass → push proceeds
 *   5. GitHub Actions run (should pass since we pre-validated)
 */

const fs = require('fs');
const path = require('path');
const { execSync, spawnSync } = require('child_process');

// Read input from stdin
let inputData = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => inputData += chunk);
process.stdin.on('end', () => {
  try {
    const input = JSON.parse(inputData);
    processInput(input);
  } catch (e) {
    allowPush();
  }
});

const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();

function processInput(input) {
  const toolInput = input.tool_input || {};
  const command = toolInput.command || '';

  // Only intercept git push commands
  if (!command.match(/git\s+push/i)) {
    allowPush();
    return;
  }

  // Check if we're pushing to a branch that matters
  const branchMatch = command.match(/git\s+push\s+\S+\s+(\S+)/);
  const currentBranch = getCurrentBranch();

  console.error('\n');
  console.error('═══════════════════════════════════════════════════════════════════════════════');
  console.error('                         GIT PUSH GATE - LOCAL CI');
  console.error('═══════════════════════════════════════════════════════════════════════════════');
  console.error('');
  console.error(`Branch: ${currentBranch}`);
  console.error('Running local CI checks before push...');
  console.error('');

  const results = {
    branchNaming: { status: 'pending', message: '' },
    commitLint: { status: 'pending', message: '' },
    lint: { status: 'pending', message: '' },
    typecheck: { status: 'pending', message: '' },
    tests: { status: 'pending', message: '' },
    security: { status: 'pending', message: '' }
  };

  // ─────────────────────────────────────────────────────────────────────────
  // Check 1: Branch Naming Convention
  // ─────────────────────────────────────────────────────────────────────────
  console.error('📋 [1/6] Checking branch naming convention...');

  const validBranchPattern = /^(feature|bugfix|hotfix|release|chore|docs|refactor|test)\/[a-z0-9._-]+$/;
  const protectedBranches = ['main', 'master', 'develop'];

  if (protectedBranches.includes(currentBranch)) {
    results.branchNaming = { status: 'skip', message: 'Protected branch (direct push)' };
  } else if (validBranchPattern.test(currentBranch)) {
    results.branchNaming = { status: 'pass', message: 'Branch name follows convention' };
  } else {
    results.branchNaming = {
      status: 'fail',
      message: `Invalid branch name: ${currentBranch}\n` +
        'Expected: <type>/<description>\n' +
        'Types: feature, bugfix, hotfix, release, chore, docs, refactor, test'
    };
  }
  logResult('Branch Naming', results.branchNaming);

  // ─────────────────────────────────────────────────────────────────────────
  // Check 2: Commit Message Lint
  // ─────────────────────────────────────────────────────────────────────────
  console.error('📋 [2/6] Checking commit messages...');

  const commitLintResult = checkCommitMessages();
  results.commitLint = commitLintResult;
  logResult('Commit Lint', results.commitLint);

  // ─────────────────────────────────────────────────────────────────────────
  // Check 3: Linting (ESLint/Prettier)
  // ─────────────────────────────────────────────────────────────────────────
  console.error('📋 [3/6] Running linter...');

  const lintResult = runLint();
  results.lint = lintResult;
  logResult('Lint', results.lint);

  // ─────────────────────────────────────────────────────────────────────────
  // Check 4: TypeScript Type Check
  // ─────────────────────────────────────────────────────────────────────────
  console.error('📋 [4/6] Running TypeScript check...');

  const typecheckResult = runTypeCheck();
  results.typecheck = typecheckResult;
  logResult('TypeScript', results.typecheck);

  // ─────────────────────────────────────────────────────────────────────────
  // Check 5: Tests
  // ─────────────────────────────────────────────────────────────────────────
  console.error('📋 [5/6] Running tests...');

  const testResult = runTests();
  results.tests = testResult;
  logResult('Tests', results.tests);

  // ─────────────────────────────────────────────────────────────────────────
  // Check 6: Security Scan
  // ─────────────────────────────────────────────────────────────────────────
  console.error('📋 [6/6] Running security scan...');

  const securityResult = runSecurityScan();
  results.security = securityResult;
  logResult('Security', results.security);

  // ─────────────────────────────────────────────────────────────────────────
  // Summary
  // ─────────────────────────────────────────────────────────────────────────
  console.error('');
  console.error('═══════════════════════════════════════════════════════════════════════════════');
  console.error('                              LOCAL CI RESULTS');
  console.error('═══════════════════════════════════════════════════════════════════════════════');
  console.error('');

  const failed = [];
  const passed = [];
  const skipped = [];

  for (const [name, result] of Object.entries(results)) {
    if (result.status === 'fail') {
      failed.push({ name, ...result });
    } else if (result.status === 'pass') {
      passed.push({ name, ...result });
    } else {
      skipped.push({ name, ...result });
    }
  }

  // Print summary
  for (const item of passed) {
    console.error(`  ✅ ${formatName(item.name)}: PASSED`);
  }
  for (const item of skipped) {
    console.error(`  ⏭️  ${formatName(item.name)}: SKIPPED (${item.message})`);
  }
  for (const item of failed) {
    console.error(`  ❌ ${formatName(item.name)}: FAILED`);
  }

  console.error('');

  if (failed.length > 0) {
    console.error('═══════════════════════════════════════════════════════════════════════════════');
    console.error('                              PUSH BLOCKED');
    console.error('═══════════════════════════════════════════════════════════════════════════════');
    console.error('');
    console.error(`${failed.length} check(s) failed. Fix the issues before pushing.`);
    console.error('');

    for (const item of failed) {
      console.error(`─── ${formatName(item.name)} ───`);
      console.error(item.message);
      console.error('');
    }

    console.error('═══════════════════════════════════════════════════════════════════════════════');

    blockPush(
      `Local CI failed: ${failed.map(f => formatName(f.name)).join(', ')}\n\n` +
      `Fix these issues before pushing to ensure GitHub Actions will pass.`
    );
    return;
  }

  console.error('═══════════════════════════════════════════════════════════════════════════════');
  console.error('                              PUSH AUTHORIZED');
  console.error('═══════════════════════════════════════════════════════════════════════════════');
  console.error('');
  console.error('All local CI checks passed. Push will proceed.');
  console.error('GitHub Actions should pass based on these pre-checks.');
  console.error('');
  console.error('═══════════════════════════════════════════════════════════════════════════════');

  allowPush();
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper Functions
// ─────────────────────────────────────────────────────────────────────────────

function getCurrentBranch() {
  try {
    return execSync('git rev-parse --abbrev-ref HEAD', {
      cwd: projectDir,
      encoding: 'utf8'
    }).trim();
  } catch (e) {
    return 'unknown';
  }
}

function checkCommitMessages() {
  try {
    // Get commits not on main/master
    const mainBranch = getMainBranch();
    const commits = execSync(`git log ${mainBranch}..HEAD --format=%s 2>/dev/null || git log -10 --format=%s`, {
      cwd: projectDir,
      encoding: 'utf8'
    }).trim().split('\n').filter(Boolean);

    if (commits.length === 0) {
      return { status: 'skip', message: 'No new commits to check' };
    }

    const conventionalPattern = /^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9._-]+\))?!?: .+$/;
    const invalid = [];

    for (const commit of commits) {
      if (!conventionalPattern.test(commit)) {
        invalid.push(commit);
      }
    }

    if (invalid.length > 0) {
      return {
        status: 'fail',
        message: `Invalid commit messages:\n${invalid.map(c => `  - "${c}"`).join('\n')}\n\n` +
          'Expected format: type(scope): description\n' +
          'Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert'
      };
    }

    return { status: 'pass', message: `${commits.length} commit(s) follow conventional format` };
  } catch (e) {
    return { status: 'skip', message: 'Could not check commits' };
  }
}

function runLint() {
  const packageJsonPath = path.join(projectDir, 'package.json');

  if (!fs.existsSync(packageJsonPath)) {
    return { status: 'skip', message: 'No package.json found' };
  }

  try {
    const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
    const scripts = packageJson.scripts || {};

    // Try different lint commands
    if (scripts.lint) {
      const result = spawnSync('npm', ['run', 'lint'], {
        cwd: projectDir,
        encoding: 'utf8',
        timeout: 60000,
        shell: true
      });

      if (result.status === 0) {
        return { status: 'pass', message: 'Lint passed' };
      } else {
        return {
          status: 'fail',
          message: `Lint errors:\n${result.stdout || result.stderr || 'Unknown error'}`
        };
      }
    }

    // Check if eslint is available
    if (packageJson.devDependencies?.eslint || packageJson.dependencies?.eslint) {
      const result = spawnSync('npx', ['eslint', '.', '--ext', '.js,.jsx,.ts,.tsx', '--max-warnings', '0'], {
        cwd: projectDir,
        encoding: 'utf8',
        timeout: 60000,
        shell: true
      });

      if (result.status === 0) {
        return { status: 'pass', message: 'ESLint passed' };
      } else {
        return {
          status: 'fail',
          message: `ESLint errors:\n${result.stdout || result.stderr || 'Unknown error'}`
        };
      }
    }

    return { status: 'skip', message: 'No lint script or ESLint configured' };
  } catch (e) {
    return { status: 'skip', message: `Lint check error: ${e.message}` };
  }
}

function runTypeCheck() {
  const tsconfigPath = path.join(projectDir, 'tsconfig.json');

  if (!fs.existsSync(tsconfigPath)) {
    return { status: 'skip', message: 'No tsconfig.json found' };
  }

  try {
    const packageJsonPath = path.join(projectDir, 'package.json');
    let hasTypeScript = false;

    if (fs.existsSync(packageJsonPath)) {
      const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
      const scripts = packageJson.scripts || {};

      // Try typecheck script first
      if (scripts.typecheck) {
        const result = spawnSync('npm', ['run', 'typecheck'], {
          cwd: projectDir,
          encoding: 'utf8',
          timeout: 120000,
          shell: true
        });

        if (result.status === 0) {
          return { status: 'pass', message: 'TypeScript check passed' };
        } else {
          return {
            status: 'fail',
            message: `TypeScript errors:\n${result.stdout || result.stderr || 'Unknown error'}`
          };
        }
      }

      hasTypeScript = packageJson.devDependencies?.typescript || packageJson.dependencies?.typescript;
    }

    if (hasTypeScript) {
      const result = spawnSync('npx', ['tsc', '--noEmit'], {
        cwd: projectDir,
        encoding: 'utf8',
        timeout: 120000,
        shell: true
      });

      if (result.status === 0) {
        return { status: 'pass', message: 'TypeScript check passed' };
      } else {
        return {
          status: 'fail',
          message: `TypeScript errors:\n${result.stdout || result.stderr || 'Unknown error'}`
        };
      }
    }

    return { status: 'skip', message: 'TypeScript not installed' };
  } catch (e) {
    return { status: 'skip', message: `TypeScript check error: ${e.message}` };
  }
}

function runTests() {
  const packageJsonPath = path.join(projectDir, 'package.json');

  if (!fs.existsSync(packageJsonPath)) {
    return { status: 'skip', message: 'No package.json found' };
  }

  try {
    const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
    const scripts = packageJson.scripts || {};

    if (!scripts.test || scripts.test.includes('no test specified')) {
      return { status: 'skip', message: 'No test script configured' };
    }

    const result = spawnSync('npm', ['test'], {
      cwd: projectDir,
      encoding: 'utf8',
      timeout: 300000, // 5 minutes for tests
      shell: true,
      env: { ...process.env, CI: 'true' }
    });

    if (result.status === 0) {
      return { status: 'pass', message: 'All tests passed' };
    } else {
      return {
        status: 'fail',
        message: `Test failures:\n${result.stdout || result.stderr || 'Unknown error'}`
      };
    }
  } catch (e) {
    return { status: 'skip', message: `Test error: ${e.message}` };
  }
}

function runSecurityScan() {
  const packageJsonPath = path.join(projectDir, 'package.json');

  if (!fs.existsSync(packageJsonPath)) {
    return { status: 'skip', message: 'No package.json found' };
  }

  try {
    // Run npm audit
    const result = spawnSync('npm', ['audit', '--audit-level=high'], {
      cwd: projectDir,
      encoding: 'utf8',
      timeout: 60000,
      shell: true
    });

    if (result.status === 0) {
      return { status: 'pass', message: 'No high/critical vulnerabilities' };
    } else {
      // Check if it's just warnings vs actual high/critical issues
      const output = result.stdout || result.stderr || '';
      if (output.includes('high') || output.includes('critical')) {
        return {
          status: 'fail',
          message: `Security vulnerabilities found:\n${output.slice(0, 500)}`
        };
      }
      return { status: 'pass', message: 'No high/critical vulnerabilities' };
    }
  } catch (e) {
    return { status: 'skip', message: `Security scan error: ${e.message}` };
  }
}

function getMainBranch() {
  try {
    // Check if main exists
    execSync('git rev-parse --verify main', { cwd: projectDir, encoding: 'utf8', stdio: 'pipe' });
    return 'main';
  } catch (e) {
    try {
      // Check if master exists
      execSync('git rev-parse --verify master', { cwd: projectDir, encoding: 'utf8', stdio: 'pipe' });
      return 'master';
    } catch (e2) {
      return 'HEAD~10'; // Fallback to last 10 commits
    }
  }
}

function formatName(name) {
  return name.replace(/([A-Z])/g, ' $1').replace(/^./, s => s.toUpperCase()).trim();
}

function logResult(name, result) {
  const icon = result.status === 'pass' ? '✅' : result.status === 'fail' ? '❌' : '⏭️';
  console.error(`   ${icon} ${result.status.toUpperCase()}`);
}

function allowPush(message = '') {
  const output = {
    continue: true,
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      additionalContext: message
    }
  };
  console.log(JSON.stringify(output));
  process.exit(0);
}

function blockPush(reason) {
  const output = {
    continue: false,
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      additionalContext: reason
    }
  };
  console.log(JSON.stringify(output));
  process.exit(2);
}
