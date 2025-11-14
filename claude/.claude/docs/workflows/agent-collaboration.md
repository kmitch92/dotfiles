# Agent Collaboration Workflows

## Core Principle

**The Main Agent orchestrates, never implements.** All code changes are delegated to specialized agents.

## Invocation Mechanics

### Single Agent Invocation

Use Task tool with:
- **subagent_type**: Agent name (e.g., "Test Writer", "Technical Architect")
- **description**: Short 3-5 word summary
- **prompt**: Detailed instructions, what to accomplish, what to return

**Example:**
```
[Task tool call]
- subagent_type: "Test Writer"
- description: "Write payment validation tests"
- prompt: "Write failing tests for payment validation. Cover: amount validation (positive, non-zero), card details validation (token required, CVV format), address validation (required fields). Use PaymentSchema from @/schemas/payment. Return test file path."
```

### Parallel Agent Invocation

**Key Rule:** To run agents in parallel, send ONE message with MULTIPLE Task tool calls.

**Example:**
```
[SINGLE message with FOUR Task tool calls]

Task 1:
- subagent_type: "Code Quality Enforcer"
- description: "Review code quality"
- prompt: "Review src/payment/processor.ts for: immutability violations, nested conditionals, unclear naming, functional patterns. Return prioritized feedback."

Task 2:
- subagent_type: "Test Writer"
- description: "Review test coverage"
- prompt: "Review tests for payment processor. Verify: all behaviors tested, no implementation details tested, real schemas used. Return coverage gaps."

Task 3:
- subagent_type: "TypeScript Connoisseur"
- description: "Review type definitions"
- prompt: "Review types in src/payment/. Check: strict mode compliance, no 'any', proper schema usage. Return type improvements."

Task 4:
- subagent_type: "Security Specialist"
- description: "Security review"
- prompt: "Review payment processor for: PII handling, injection risks, authorization checks. Return security findings."
```

## Collaboration Patterns

### Pattern 1: Sequential Delegation

**Use when:** Tasks have dependencies (output of one feeds into next)

**Flow:**
```
Main Agent
  → Agent 1 completes
  → Main Agent reviews
  → Agent 2 completes
  → Main Agent reviews
  → Agent 3 completes
```

**Example: New Feature Implementation**
```
Step 1: Technical Architect breaks feature into tasks
Step 2: Main reviews task breakdown
Step 3: Test Writer writes failing tests for Task 1
Step 4: Main verifies tests fail
Step 5: Backend Developer implements to pass tests
Step 6: Main verifies tests pass
Step 7: Refactoring Specialist assesses code quality
Step 8: Main coordinates any refactoring
Step 9: Git Specialist commits changes
Step 10: Repeat for remaining tasks
```

### Pattern 2: Parallel Consultation

**Use when:** Multiple independent perspectives needed on same artifact

**Flow:**
```
Main Agent
  → [Agent 1 + Agent 2 + Agent 3] analyze simultaneously
  → Main Agent synthesizes feedback
  → Main Agent prioritizes actions
```

**Example: Comprehensive Code Review**
```
Main invokes in parallel:
- Code Quality Enforcer (style, patterns, anti-patterns)
- Test Writer (coverage, behavior focus, test quality)
- TypeScript Connoisseur (types, schemas, strict mode)
- Security Specialist (vulnerabilities, PII handling)

Main receives all feedback, synthesizes, presents prioritized list to user.
```

### Pattern 3: Iterative Refinement

**Use when:** Complex task requires multiple rounds of review and adjustment

**Flow:**
```
Main Agent
  → Agent 1 (initial implementation)
  → Main Agent reviews
  → Agent 2 (feedback on implementation)
  → Main Agent synthesizes
  → Agent 1 (refinement)
  → Main Agent verifies
```

**Example: API Design with Security Review**
```
Step 1: API Design Specialist creates initial design
Step 2: Main reviews design document
Step 3: Security Specialist reviews for security concerns
Step 4: Main identifies required changes
Step 5: API Design Specialist refines design
Step 6: Main confirms design meets all requirements
```

## Decision Trees

### When User Requests New Feature

```
User: "Add [feature]"
  ↓
Requirements clear?
  NO → Main asks clarifying questions
  YES → Continue
  ↓
Complex feature?
  YES → Invoke Technical Architect for task breakdown
  NO → Continue
  ↓
For each task (sequential):
  ↓
  Test Writer: Write failing tests (RED)
  ↓
  Domain Agent: Implement minimum code (GREEN)
  ↓
  Test Writer: Verify tests pass and coverage
  ↓
  Refactoring Specialist: Assess refactoring (REFACTOR)
  ↓
  Domain Agent: Execute refactoring if recommended
  ↓
  Test Writer: Verify tests still pass
  ↓
  [Security/Performance review if needed - parallel]
  ↓
  Git Specialist: Commit
  ↓
Next task or Done
  ↓
Documentation Agent: Capture learnings in project CLAUDE.md
```

### When User Reports Bug

```
User: "Bug in [feature]"
  ↓
Can reproduce?
  NO → Main asks for reproduction steps
  YES → Continue
  ↓
Test Writer: Write failing test reproducing bug (RED)
  ↓
Domain Agent: Fix bug (GREEN)
  ↓
Test Writer: Verify test passes + add edge case tests
  ↓
Refactoring Specialist: Assess if bug indicates larger issue
  ↓
If larger issue identified:
  Domain Agent: Address root cause
  Test Writer: Verify all tests pass
  ↓
Git Specialist: Commit fix
  ↓
Documentation Agent: Document root cause and fix
```

### When User Requests Refactoring

```
User: "Refactor [code]"
  ↓
Refactoring Specialist: Assess current state
  ↓
Test Writer: Verify 100% test coverage exists
  ↓
Coverage < 100%?
  YES → Test Writer: Write missing tests first
  NO → Continue
  ↓
Domain Agent: Refactor maintaining public API
  ↓
Test Writer: Verify tests pass WITHOUT modification
  ↓
Tests modified?
  YES → STOP - Not true refactoring (behavior changed)
  NO → Continue
  ↓
Code Quality Enforcer: Review refactored code (parallel)
Performance Specialist: Verify no regressions (parallel)
  ↓
Main synthesizes feedback
  ↓
Issues found?
  YES → Domain Agent: Address issues, repeat verification
  NO → Continue
  ↓
Git Specialist: Commit
  ↓
Documentation Agent: Document refactoring rationale
```

### When User Requests Code Review

```
User: "Review [code/PR]"
  ↓
Security sensitive? (auth, PII, payments)
  YES → Include Security Specialist in parallel review
  NO → Standard review
  ↓
Performance critical? (API endpoints, data processing)
  YES → Include Performance Specialist in parallel review
  NO → Standard review
  ↓
Main invokes in parallel:
- Code Quality Enforcer
- Test Writer
- TypeScript Connoisseur
- [Security Specialist if needed]
- [Performance Specialist if needed]
  ↓
Main receives all feedback
  ↓
Main synthesizes and prioritizes:
1. Critical (security, data loss, breaks)
2. High value (performance, maintainability)
3. Nice to have (style, minor improvements)
4. Skip (bikeshedding, personal preference)
  ↓
Present prioritized feedback to user
```

## Domain Agent Selection

### Primary Technology Determines Agent

| Technology | Primary Agent | When to Invoke |
|------------|--------------|----------------|
| React components | React Engineer | Component implementation, hooks, SSR, client state |
| API endpoints | Backend TypeScript Developer | Lambda functions, Express routes, API logic |
| Database schema | Database Design Specialist | Schema design, migrations, queries, optimization |
| AWS infrastructure | AWS CDK Expert | CDK stacks, AWS services, deployment pipelines |
| Shell scripts | Bash/Shell Specialist | Installation scripts, git hooks, CLI automation |
| Type definitions | TypeScript Connoisseur | Complex types, generics, schema design |
| Tests | Test Writer | All testing activities, coverage verification |

### Supporting Agents for Cross-Cutting Concerns

| Concern | Agent | When to Invoke |
|---------|-------|----------------|
| Security | Security Specialist | Auth, PII, payments, user input, before production |
| Performance | Performance Specialist | Slow operations, high-traffic endpoints, optimization |
| Code quality | Code Quality Enforcer | Style review, pattern violations, maintainability |
| Refactoring | Refactoring Specialist | After GREEN phase (mandatory), before considering task complete |
| API design | API Design Specialist | Before implementing endpoints, contract-first design |
| Documentation | Documentation Agent | After feature completion, capture learnings |
| Git operations | Git Specialist | All commits, branching, PR creation |

## Parallelization Decision Matrix

### Use Parallel When:

**Independent Analysis Tasks:**
- Code review from multiple perspectives
- Security + Performance + Quality assessments
- Multi-domain design (API + Database)

**Example:**
```
Parallel code review:
[Code Quality + Test Writer + TypeScript + Security] → Synthesize
```

### Use Sequential When:

**Dependency Chain:**
- TDD cycle steps (test → implement → verify)
- Design then implement
- Fix then verify

**Example:**
```
Sequential TDD:
Test Writer (red) → Domain Agent (green) → Test Writer (verify) → Refactoring Specialist (assess)
```

**Decision Rule:**
- Task B needs Task A output? → Sequential
- Tasks analyzing same artifact independently? → Parallel
- Tasks working on different components? → Depends (parallel if no dependencies)

## Standard Workflows

### Workflow: New Feature (Complex)

**Phases:**
1. Planning (sequential)
2. Design (parallel if multiple domains)
3. Implementation (sequential per task)
4. Quality gates (parallel)
5. Documentation (sequential)

**Step-by-Step:**

```
PLANNING PHASE
Step 1: Technical Architect - Break feature into testable tasks
Step 2: Main Agent - Review task breakdown, confirm with user

DESIGN PHASE (if needed)
Step 3a: API Design Specialist - Design API contracts (parallel)
Step 3b: Database Design Specialist - Design schema (parallel)
Step 4: Main Agent - Ensure designs align

IMPLEMENTATION PHASE (repeat for each task)
Step 5: Test Writer - Write failing tests (RED)
Step 6: Domain Agent - Implement minimum code (GREEN)
Step 7: Test Writer - Verify tests pass
Step 8: Refactoring Specialist - Assess refactoring opportunities (REFACTOR)
Step 9: Domain Agent - Execute refactoring if recommended
Step 10: Test Writer - Verify tests still pass

QUALITY GATES (parallel)
Step 11a: Security Specialist - Security review (if auth/PII/payments)
Step 11b: Performance Specialist - Performance check (if critical path)
Step 12: Main Agent - Synthesize feedback, coordinate fixes if needed

FINALIZATION
Step 13: Git Specialist - Commit with conventional message
Step 14: Documentation Agent - Capture learnings in project CLAUDE.md
```

### Workflow: Bug Fix

**Phases:**
1. Reproduction
2. Fix
3. Verification
4. Root cause analysis
5. Documentation

**Step-by-Step:**

```
REPRODUCTION
Step 1: Test Writer - Write failing test reproducing bug (RED)

FIX
Step 2: Domain Agent - Fix bug (GREEN)

VERIFICATION
Step 3: Test Writer - Verify test passes + add edge case tests

ROOT CAUSE ANALYSIS
Step 4: Refactoring Specialist - Assess if bug indicates larger issue
Step 5: Domain Agent - Address root cause if needed (after Step 4)

FINALIZATION
Step 6: Git Specialist - Commit fix with conventional message
Step 7: Documentation Agent - Document bug, root cause, fix
```

### Workflow: Refactoring

**Phases:**
1. Assessment
2. Coverage verification
3. Refactoring execution
4. Verification
5. Review
6. Documentation

**Step-by-Step:**

```
ASSESSMENT
Step 1: Refactoring Specialist - Assess current code, identify opportunities

COVERAGE VERIFICATION
Step 2: Test Writer - Verify 100% test coverage exists
Step 3: Test Writer - Write missing tests if coverage < 100% (after Step 2)

REFACTORING
Step 4: Domain Agent - Refactor maintaining public API

VERIFICATION
Step 5: Test Writer - Verify tests pass WITHOUT modification

REVIEW (parallel)
Step 6a: Code Quality Enforcer - Review refactored code
Step 6b: Performance Specialist - Verify no performance regressions
Step 7: Main Agent - Synthesize feedback

FINALIZATION
Step 8: Git Specialist - Commit refactoring
Step 9: Documentation Agent - Document refactoring rationale
```

### Workflow: Pre-Production Review

**Phases:**
1. Comprehensive audit (parallel)
2. Synthesis and prioritization
3. Issue resolution
4. Final verification

**Step-by-Step:**

```
COMPREHENSIVE AUDIT (parallel)
Step 1a: Security Specialist - Security audit
Step 1b: Performance Specialist - Performance audit
Step 1c: Code Quality Enforcer - Code quality review
Step 1d: Test Writer - Coverage and test quality verification

SYNTHESIS
Step 2: Main Agent - Synthesize findings, prioritize by severity
Step 3: Main Agent - Present findings to user

ISSUE RESOLUTION (if needed)
Step 4: Domain Agent - Address critical/high priority issues
Step 5: [Security/Performance/Test Writer] - Verify fixes (parallel)

FINAL VERIFICATION
Step 6: Test Writer - Run full test suite
Step 7: Git Specialist - Commit fixes if any
Step 8: Documentation Agent - Document readiness assessment
```

## Agent Handoff Patterns

### Pattern: Test Writer → Domain Agent

**Test Writer completes RED phase:**
```
Test Writer: "Failing tests written for payment validation.
Tests verify: positive amounts, required card details, address validation.
Test file: src/payment/payment-processor.test.ts
All tests fail as expected. Ready for implementation."

Main Agent → Domain Agent: "Implement payment validation to pass tests.
Tests are in src/payment/payment-processor.test.ts.
Minimum code to make tests pass. No premature abstraction.
Return implementation file path when complete."
```

### Pattern: Domain Agent → Refactoring Specialist

**Domain Agent completes GREEN phase:**
```
Domain Agent: "Payment validation implemented.
All tests passing. Implementation in src/payment/payment-processor.ts.
Simple conditional logic, no abstractions yet."

Main Agent → Refactoring Specialist: "Assess refactoring opportunities for payment processor.
Code: src/payment/payment-processor.ts
Tests: src/payment/payment-processor.test.ts
Check for: duplication, complex conditionals, unclear naming.
Return: recommendations or confirmation code is clean."
```

### Pattern: Refactoring Specialist → Test Writer

**Refactoring Specialist identifies no changes needed:**
```
Refactoring Specialist: "Code is clean. Single responsibility, clear logic, no duplication.
No refactoring needed. Ready for commit."

Main Agent → Test Writer: "Verify final test run before commit.
Run full test suite. Confirm 100% passing.
Return test results and coverage."
```

### Pattern: Multiple Specialists → Main Agent (Parallel)

**Parallel review completion:**
```
Code Quality Enforcer: "Found: 2 immutability violations, 1 nested conditional. Priority: High."
Test Writer: "Coverage: 95%. Missing: error boundary tests. Priority: Critical."
TypeScript Connoisseur: "Found: 1 'any' type, 2 unneeded assertions. Priority: High."
Security Specialist: "Found: Unvalidated user input in /api/payment. Priority: Critical."

Main Agent synthesizes:
"Critical issues (fix first):
1. Security: Unvalidated user input in /api/payment
2. Test coverage: Missing error boundary tests

High priority (fix next):
3. Code quality: 2 immutability violations, 1 nested conditional
4. TypeScript: 1 'any' type, 2 unneeded assertions"
```

## Summary

Agent collaboration is orchestrated through clear patterns:

1. **Sequential for dependencies** - TDD cycle, design-then-implement
2. **Parallel for independent analysis** - Code review, quality gates
3. **Iterative for refinement** - Complex designs, user feedback
4. **Clear handoffs** - Each agent knows what to expect from previous agent
5. **Main agent synthesizes** - Never implements, always delegates

**Key principle:** The right agent for the right task at the right time. Main agent ensures this happens.
