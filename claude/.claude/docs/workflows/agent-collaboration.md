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
- subagent_type: "Quality & Refactoring Specialist"
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
- subagent_type: "Production Readiness Specialist"
- description: "Security review"
- prompt: "Review payment processor for: PII handling, injection risks, authorization checks. Return security findings."
```

## Critical Architecture: No Agent-to-Agent Invocation

**ONLY Main Agent invokes specialized agents.** Specialized agents complete their work and return to Main Agent with recommendations.

**Why this architecture:**
- **Prevents recursive invocation chains**: Agent A cannot invoke Agent B who invokes Agent C (infinite loops)
- **Avoids heap memory errors**: Prevents JavaScript heap exhaustion from agent call stacks
- **Maintains clear control flow**: Single orchestrator makes debugging and monitoring easier
- **Enables proper error handling**: Main Agent can catch and handle agent failures

**Pattern - CORRECT:**
```
Main Agent → Agent A (assign task)
Agent A completes work
Agent A → Main Agent (results + "Recommend invoking Agent B for [reason]")
Main Agent evaluates recommendation
Main Agent → Agent B (assign task based on Agent A results)
```

**Pattern - WRONG (DO NOT DO):**
```
Main Agent → Agent A
Agent A → Agent B (direct invocation - RECURSIVE)
Agent B → Agent C (deeper recursion)
Agent C → Agent D (even deeper)
[System crashes: JavaScript heap out of memory]
```

### Hard Limit: Maximum 2 Agents in Parallel

**Enforced by Main Agent only.** Specialized agents cannot control parallel execution.

**When 2 agents needed:**
- Invoke in parallel (single message with two Task tool calls)
- Example: Design Specialist + Test Writer for parallel design and test planning

**When 3+ agents needed:**
- Use sequential batches
- Batch 1: Invoke 2 agents (parallel)
- Wait for Batch 1 completion and review results
- Batch 2: Invoke remaining agents (1-2 agents, sequential)
- Synthesize all results

**Example - Comprehensive Code Review (4 perspectives needed):**
```
Batch 1 (2 agents parallel):
- Quality & Refactoring Specialist
- TypeScript Connoisseur

[Wait for Batch 1 completion, review findings]

Batch 2 (2 agents parallel):
- Production Readiness Specialist (security + performance)
- Test Writer (coverage verification)

[Synthesize all 4 perspectives]
```

**Rationale for 2-agent limit:**
- Prevents resource contention
- Maintains focus and synthesis quality
- Reduces cognitive load when integrating feedback
- Avoids "too many cooks" problem

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
Step 7: Quality & Refactoring Specialist assesses code quality
Step 8: Main coordinates any refactoring
Step 9: Quality & Refactoring Specialist commits changes
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
Main invokes in batches (max 2 parallel):

Batch 1:
- Quality & Refactoring Specialist (style, patterns, anti-patterns)
- TypeScript Connoisseur (types, schemas, strict mode)

[Wait for Batch 1, review findings]

Batch 2:
- Production Readiness Specialist (vulnerabilities, PII handling)
- Test Writer (coverage, behavior focus, test quality)

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
Step 1: Design Specialist creates initial design
Step 2: Main reviews design document
Step 3: Production Readiness Specialist reviews for security concerns
Step 4: Main identifies required changes
Step 5: Design Specialist refines design
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
  Quality & Refactoring Specialist: Assess refactoring (REFACTOR)
  ↓
  Domain Agent: Execute refactoring if recommended
  ↓
  Test Writer: Verify tests still pass
  ↓
  [Production Readiness review if needed - parallel]
  ↓
  Quality & Refactoring Specialist: Commit
  ↓
Next task or Done
  ↓
Documentation Specialist: Capture learnings in project CLAUDE.md
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
Quality & Refactoring Specialist: Assess if bug indicates larger issue
  ↓
If larger issue identified:
  Domain Agent: Address root cause
  Test Writer: Verify all tests pass
  ↓
Quality & Refactoring Specialist: Commit fix
  ↓
Documentation Specialist: Document root cause and fix
```

### When User Requests Refactoring

```
User: "Refactor [code]"
  ↓
Quality & Refactoring Specialist: Assess current state
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
Quality & Refactoring Specialist: Review refactored code (parallel)
Production Readiness Specialist: Verify no regressions (parallel)
  ↓
Main synthesizes feedback
  ↓
Issues found?
  YES → Domain Agent: Address issues, repeat verification
  NO → Continue
  ↓
Quality & Refactoring Specialist: Commit
  ↓
Documentation Specialist: Document refactoring rationale
```

### When User Requests Code Review

```
User: "Review [code/PR]"
  ↓
Security or performance critical? (auth, PII, payments, API endpoints, data processing)
  YES → Include Production Readiness Specialist in parallel review
  NO → Standard review
  ↓
Main invokes in parallel:
- Quality & Refactoring Specialist
- Test Writer
- TypeScript Connoisseur
- [Production Readiness Specialist if needed]
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
| API endpoints | Backend TypeScript Developer | Lambda functions, Express routes, API logic, AWS CDK stacks |
| Database schema | Design Specialist | Schema design, migrations, queries, optimization |
| Shell scripts | Bash/Shell Specialist | Installation scripts, git hooks, CLI automation |
| Type definitions | TypeScript Connoisseur | Complex types, generics, schema design |
| Tests | Test Writer | All testing activities, coverage verification |

### Supporting Agents for Cross-Cutting Concerns

| Concern | Agent | When to Invoke |
|---------|-------|----------------|
| Security & Performance | Production Readiness Specialist | Auth, PII, payments, user input, slow operations, high-traffic endpoints, before production |
| Code quality & Refactoring | Quality & Refactoring Specialist | After GREEN phase (mandatory), style review, pattern violations, maintainability, all commits, branching, PR creation |
| API & Database design | Design Specialist | Before implementing endpoints, contract-first design, schema design |
| Documentation | Documentation Specialist | After feature completion, capture learnings |

## Parallelization Decision Matrix

### Use Parallel When:

**Independent Analysis Tasks:**
- Code review from multiple perspectives
- Security + Performance + Quality assessments
- Multi-domain design (API + Database)

**Example:**
```
Batched code review (max 2 parallel):
Batch 1: [Quality & Refactoring + TypeScript] → Review
Batch 2: [Production Readiness + Test Writer] → Review
→ Synthesize all findings
```

### Use Sequential When:

**Dependency Chain:**
- TDD cycle steps (test → implement → verify)
- Design then implement
- Fix then verify

**Example:**
```
Sequential TDD:
Test Writer (red) → Domain Agent (green) → Test Writer (verify) → Quality & Refactoring Specialist (assess)
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
Step 3: Design Specialist - Design API contracts and schema (can be parallel if needed)
Step 4: Main Agent - Ensure designs align

IMPLEMENTATION PHASE (repeat for each task)
Step 5: Test Writer - Write failing tests (RED)
Step 6: Domain Agent - Implement minimum code (GREEN)
Step 7: Test Writer - Verify tests pass
Step 8: Quality & Refactoring Specialist - Assess refactoring opportunities (REFACTOR)
Step 9: Domain Agent - Execute refactoring if recommended
Step 10: Test Writer - Verify tests still pass

QUALITY GATES (parallel if needed)
Step 11: Production Readiness Specialist - Security and performance review (if auth/PII/payments/critical path)
Step 12: Main Agent - Synthesize feedback, coordinate fixes if needed

FINALIZATION
Step 13: Quality & Refactoring Specialist - Commit with conventional message
Step 14: Documentation Specialist - Capture learnings in project CLAUDE.md
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
Step 4: Quality & Refactoring Specialist - Assess if bug indicates larger issue
Step 5: Domain Agent - Address root cause if needed (after Step 4)

FINALIZATION
Step 6: Quality & Refactoring Specialist - Commit fix with conventional message
Step 7: Documentation Specialist - Document bug, root cause, fix
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
Step 1: Quality & Refactoring Specialist - Assess current code, identify opportunities

COVERAGE VERIFICATION
Step 2: Test Writer - Verify 100% test coverage exists
Step 3: Test Writer - Write missing tests if coverage < 100% (after Step 2)

REFACTORING
Step 4: Domain Agent - Refactor maintaining public API

VERIFICATION
Step 5: Test Writer - Verify tests pass WITHOUT modification

REVIEW (parallel if needed)
Step 6: Quality & Refactoring Specialist - Review refactored code
Step 7: Production Readiness Specialist - Verify no performance regressions (if performance-critical code)
Step 8: Main Agent - Synthesize feedback

FINALIZATION
Step 9: Quality & Refactoring Specialist - Commit refactoring
Step 10: Documentation Specialist - Document refactoring rationale
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
Step 1a: Production Readiness Specialist - Security and performance audit
Step 1b: Quality & Refactoring Specialist - Code quality review
Step 1c: Test Writer - Coverage and test quality verification

SYNTHESIS
Step 2: Main Agent - Synthesize findings, prioritize by severity
Step 3: Main Agent - Present findings to user

ISSUE RESOLUTION (if needed)
Step 4: Domain Agent - Address critical/high priority issues
Step 5: [Production Readiness/Test Writer] - Verify fixes (parallel)

FINAL VERIFICATION
Step 6: Test Writer - Run full test suite
Step 7: Quality & Refactoring Specialist - Commit fixes if any
Step 8: Documentation Specialist - Document readiness assessment
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

### Pattern: Domain Agent → Quality & Refactoring Specialist

**Domain Agent completes GREEN phase:**
```
Domain Agent: "Payment validation implemented.
All tests passing. Implementation in src/payment/payment-processor.ts.
Simple conditional logic, no abstractions yet."

Main Agent → Quality & Refactoring Specialist: "Assess refactoring opportunities for payment processor.
Code: src/payment/payment-processor.ts
Tests: src/payment/payment-processor.test.ts
Check for: duplication, complex conditionals, unclear naming.
Return: recommendations or confirmation code is clean."
```

### Pattern: Quality & Refactoring Specialist → Test Writer

**Quality & Refactoring Specialist identifies no changes needed:**
```
Quality & Refactoring Specialist: "Code is clean. Single responsibility, clear logic, no duplication.
No refactoring needed. Ready for commit."

Main Agent → Test Writer: "Verify final test run before commit.
Run full test suite. Confirm 100% passing.
Return test results and coverage."
```

### Pattern: Multiple Specialists → Main Agent (Parallel)

**Parallel review completion:**
```
Quality & Refactoring Specialist: "Found: 2 immutability violations, 1 nested conditional. Priority: High."
Test Writer: "Coverage: 95%. Missing: error boundary tests. Priority: Critical."
TypeScript Connoisseur: "Found: 1 'any' type, 2 unneeded assertions. Priority: High."
Production Readiness Specialist: "Found: Unvalidated user input in /api/payment. Priority: Critical."

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
