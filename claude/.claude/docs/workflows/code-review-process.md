# Code Review Process

## Core Principle

**Quality is verified through multiple specialized perspectives in parallel, synthesized by the Main Agent into prioritized, actionable feedback.**

Code review is not a single-agent activity. Comprehensive review requires security, performance, code quality, test coverage, and type safety perspectives.

## Review Types

### Standard Code Review

**Scope:** General code quality, patterns, maintainability

**Agents Invoked (parallel):**
- Quality & Refactoring Specialist
- Test Writer
- TypeScript Connoisseur

**Use when:**
- Pull request review
- Refactoring assessment
- General code health check

### Security or Performance-Sensitive Code Review

**Scope:** Authentication, authorization, PII, payments, user input, API endpoints, data processing, high-traffic paths

**Agents Invoked (sequential batches, max 2 parallel):**
- **Batch 1** (parallel): Quality & Refactoring Specialist + TypeScript Connoisseur
- **Batch 2** (parallel): Production Readiness Specialist + Test Writer

**Note**: Maximum 2 agents in parallel (hard limit). For comprehensive reviews requiring 3+ agents, use sequential batches.

**Use when:**
- Auth flows
- Payment processing
- Data handling (PII, credentials)
- User input processing
- API endpoints with SLA requirements
- Database queries
- Data transformation pipelines
- High-frequency operations

### Pre-Production Review

**Scope:** Comprehensive readiness assessment

**Agents Invoked (sequential batches, max 2 parallel):**
- **Batch 1** (parallel): Quality & Refactoring Specialist + TypeScript Connoisseur
- **Batch 2** (parallel): Production Readiness Specialist + Test Writer

**Note**: Maximum 2 agents in parallel (hard limit). For comprehensive reviews requiring 3+ agents, use sequential batches.

**Use when:**
- Before production deployment
- Major feature release
- Breaking change release
- Compliance-required review

## Review Process

### Step 1: Determine Review Scope

Main Agent analyzes code to determine review type:

**Decision criteria:**
```
Contains auth/authorization logic? → Include Production Readiness Specialist
Handles PII/credentials/payments? → Include Production Readiness Specialist
Processes user input? → Include Production Readiness Specialist
API endpoint with SLA? → Include Production Readiness Specialist
Database operations? → Include Production Readiness Specialist
Data transformation at scale? → Include Production Readiness Specialist

Otherwise → Standard review
```

### Step 2: Agent Invocation (Sequential Batches)

**Maximum 2 agents in parallel (hard limit).** For 3+ agents, use sequential batches.

**Standard Review Example (3 agents - uses batches):**
```
BATCH 1: [SINGLE message with TWO Task tool calls]

Task 1:
- subagent_type: "Quality & Refactoring Specialist"
- description: "Code quality review"
- prompt: "Review [files] for: immutability violations, nested conditionals, unclear naming, functional patterns, anti-patterns. Return prioritized feedback by severity."

Task 2:
- subagent_type: "TypeScript Connoisseur"
- description: "Type safety review"
- prompt: "Review types in [files]. Check: strict mode compliance, no 'any', proper schema usage, type assertions justified. Return type improvements needed."

[Wait for Batch 1 completion, review findings]

BATCH 2: [SINGLE message with ONE Task tool call]

Task 3:
- subagent_type: "Test Writer"
- description: "Test coverage review"
- prompt: "Review tests for [files]. Check: all behaviors tested, no implementation details, real schemas used, coverage gaps. Return missing test cases and coverage metrics."
```

**Security/Performance Review Example (4 agents - uses batches):**
```
BATCH 1: [SINGLE message with TWO Task tool calls]
- Quality & Refactoring Specialist
- TypeScript Connoisseur

[Wait for Batch 1 completion, review findings]

BATCH 2: [SINGLE message with TWO Task tool calls]
- Production Readiness Specialist
- Test Writer
```

### Step 3: Synthesize Feedback

Main Agent receives all agent responses and synthesizes into prioritized list.

**Synthesis criteria:**
1. Group findings by severity
2. Identify dependencies (e.g., fix security before performance)
3. Remove duplicates
4. Add context about tradeoffs

**Severity Classification:**

🔴 **CRITICAL** - Must fix before merge/deploy
- Security vulnerabilities
- Performance issues causing user-facing problems
- Data loss risks
- Breaking changes without migration path
- Broken functionality

⚠️ **HIGH VALUE** - Fix now (high impact, clear improvement)
- Moderate performance issues affecting UX
- Maintainability problems (duplication, unclear abstractions)
- Missing test coverage for critical paths
- Type safety issues causing runtime risks

💡 **NICE TO HAVE** - Consider fixing (low cost, clear benefit)
- Minor style improvements
- Additional edge case tests
- Type narrowing opportunities
- Documentation additions

✅ **SKIP** - Not worth addressing
- Bikeshedding (personal preference with no objective benefit)
- Premature optimization
- Over-engineering
- Suggestions that reduce readability

### Step 4: Present Prioritized Feedback

Main Agent presents synthesized findings to user with clear priority indicators.

**Format:**
```
Code Review: [Feature/PR Name]

🔴 CRITICAL (must fix before merge):
1. [Production Readiness] Unvalidated user input in /api/payment endpoint
   - Impact: SQL injection risk
   - Location: src/api/payment.ts:45
   - Fix: Use parameterized queries with PaymentSchema validation

2. [Test Writer] No tests for error handling in order processing
   - Impact: Unknown behavior when payment fails
   - Location: src/orders/processor.ts
   - Fix: Add tests for payment failure, network timeout, invalid data scenarios

⚠️ HIGH VALUE (fix now):
3. [Quality & Refactoring] Immutability violation in cart reducer
   - Impact: Unpredictable state updates, debugging difficulty
   - Location: src/cart/reducer.ts:23-28
   - Fix: Use spread operator instead of array.push()

4. [TypeScript] Using 'any' type in payment response handler
   - Impact: No type safety for payment responses
   - Location: src/api/payment.ts:78
   - Fix: Define PaymentResponse type and use strict typing

💡 NICE TO HAVE (consider):
5. [Production Readiness] Could memoize expensive calculation in ProductList
   - Impact: Minor render optimization
   - Location: src/products/ProductList.tsx:34
   - Note: Only worthwhile if profiling shows performance issue

✅ SKIP (not recommended):
6. [Quality & Refactoring] Suggested extracting 3-line function
   - Reason: Over-abstraction. Function is only used once and logic is clear inline.
```

## Agent Responsibilities

### Quality & Refactoring Specialist

**Reviews for:**
- Immutability violations (mutation of data)
- Nested conditionals (should use early returns)
- Functional patterns (pure functions, composition)
- Naming clarity (intention-revealing names)
- Anti-patterns (God objects, feature envy)
- Git operations (commit messages, branching strategy)
- Refactoring opportunities

**Output format:**
```
Category: [Immutability/Conditionals/Naming/Patterns/Anti-patterns/Refactoring]
Severity: [Critical/High/Medium/Low]
Location: [file:line]
Issue: [clear description]
Fix: [actionable recommendation]
```

### Test Writer

**Reviews for:**
- Coverage gaps (behaviors not tested)
- Implementation detail testing (tests that shouldn't exist)
- Schema usage (tests should import real schemas)
- Test organization (by behavior, not by file structure)
- Missing edge cases (boundary conditions, error paths)

**Output format:**
```
Category: [Coverage/Testing Approach/Edge Cases]
Severity: [Critical/High/Medium/Low]
Location: [test file or missing coverage for production file]
Issue: [what's not tested or wrongly tested]
Fix: [what tests to add or change]
```

### TypeScript Connoisseur

**Reviews for:**
- Strict mode compliance (compiler errors)
- `any` types (should be proper types or `unknown`)
- Type assertions (should be justified or removed)
- Schema-first violations (types defined separately from schemas)
- Type narrowing opportunities (unions, discriminated unions)

**Output format:**
```
Category: [Strict Mode/Any Types/Assertions/Schema-First/Type Safety]
Severity: [Critical/High/Medium/Low]
Location: [file:line]
Issue: [type safety problem]
Fix: [how to properly type]
```

### Production Readiness Specialist

**Reviews for:**
- **Security concerns:**
  - Input validation (all user input validated)
  - Injection risks (SQL, XSS, command injection)
  - Authentication/Authorization (proper checks in place)
  - PII handling (encryption, access controls)
  - Secret management (no hardcoded secrets)
- **Performance concerns:**
  - Database query optimization (N+1 queries, missing indexes)
  - Algorithmic complexity (O(n²) where O(n) possible)
  - Memory usage (unnecessary data loading, leaks)
  - Network calls (unnecessary requests, missing caching)
  - Render performance (unnecessary re-renders, missing memoization)

**Output format:**
```
Category: [Security|Performance]
Subcategory: [Input Validation/Injection/Auth/PII/Secrets/Database/Algorithm/Memory/Network/Rendering]
Severity: [Critical/High/Medium/Low]
Location: [file:line]
Issue: [security vulnerability or performance problem]
Impact: [what could happen or user-facing consequence]
Fix: [remediation steps or optimization approach]
Benchmark: [current vs expected performance] (performance issues only)
```

## Synthesis Guidelines

### Prioritization Framework

**Critical Severity Assignment:**
- Security vulnerability (any severity from Production Readiness Specialist)
- Performance issue causing user-facing problems (>500ms delay, blocking operations)
- Data loss risk
- Production outage risk
- Broken core functionality

**High Value Assignment:**
- Moderate performance issue affecting user experience (>100ms delay)
- Code Quality issue preventing future changes
- Test coverage gaps for critical paths
- Type safety issues risking runtime errors

**Nice to Have Assignment:**
- Minor performance optimization (<50ms improvement)
- Additional edge case tests for unlikely scenarios
- Type narrowing that improves DX but doesn't prevent bugs
- Style improvements with clear benefit

**Skip Assignment:**
- Subjective style preferences
- Premature optimization without measurement
- Over-engineering (abstraction before duplication)
- Suggestions that reduce code clarity

### Dependency Identification

**Common dependencies:**
1. Security fixes before any other changes (security always first)
2. Test coverage before refactoring (safety net required)
3. Type safety before optimization (need correct types for safe changes)
4. Fix broken functionality before adding features

**Example:**
```
🔴 CRITICAL:
1. [Production Readiness - Security] Fix SQL injection in /api/users (FIX FIRST)
2. [Test Writer] Add tests for user query logic (DEPENDS ON #1 - need secure implementation to test)

⚠️ HIGH VALUE:
3. [Production Readiness - Performance] Optimize user query with indexing (DEPENDS ON #1,#2 - optimize after secure and tested)
```

### Avoiding Duplication

Multiple agents may identify the same issue from different perspectives.

**Example of duplication:**
```
[Quality & Refactoring] Mutation of array in cart reducer (src/cart/reducer.ts:23)
[TypeScript] Return type of reducer is incorrect due to mutation (src/cart/reducer.ts:23)
```

**Synthesized (deduplicated):**
```
Immutability violation in cart reducer (src/cart/reducer.ts:23)
- Quality & Refactoring: Mutation makes state updates unpredictable
- TypeScript: Mutation causes type system to miss errors
Fix: Use spread operator to return new array
```

## Review Workflows

### Workflow: Standard Code Review

```
USER: "Review payment processing PR"

MAIN AGENT:
Step 1: Analyze code scope
- Files: src/payment/processor.ts, src/payment/validator.ts
- Scope: Payment logic (security-sensitive)

Step 2: Invoke agents in batches (max 2 parallel)
BATCH 1: [SINGLE message, TWO Task calls]
- Quality & Refactoring Specialist
- TypeScript Connoisseur

Step 3: Receive Batch 1 feedback, review findings

Step 4: Invoke Batch 2
BATCH 2: [SINGLE message, TWO Task calls]
- Production Readiness Specialist
- Test Writer

Step 5: Receive Batch 2 feedback

Step 6: Synthesize all findings
- Group by severity
- Identify dependencies
- Remove duplicates

Step 7: Present prioritized feedback to user
```

### Workflow: Pre-Production Review

```
USER: "Pre-production review for checkout feature"

MAIN AGENT:
Step 1: Analyze scope
- Feature: Complete checkout flow
- Security: Payment handling, PII
- Performance: API calls, database queries

Step 2: Invoke agents in batches (max 2 parallel)
BATCH 1: [SINGLE message, TWO Task calls]
- Quality & Refactoring Specialist
- TypeScript Connoisseur

Step 3: Receive Batch 1 feedback, review findings

Step 4: Invoke Batch 2 (comprehensive review)
BATCH 2: [SINGLE message, TWO Task calls]
- Production Readiness Specialist
- Test Writer

Step 5: Receive Batch 2 feedback

Step 6: Synthesize all findings with production focus
- Critical items MUST be fixed
- High value items strongly recommended
- Nice to have items documented for later

Step 7: Present readiness assessment
- Ready to deploy (no critical issues)
- Blocked (critical issues must be fixed first)
- Ready with caveats (critical fixed, high value tracked)
```

### Workflow: Iterative Review (After Fixes)

```
USER: "Fixed critical issues, re-review"

MAIN AGENT:
Step 1: Identify which agents reviewed affected code
- Changed files: src/api/payment.ts
- Original reviewers: Production Readiness Specialist, TypeScript Connoisseur

Step 2: Invoke ONLY affected domain agents in parallel
[SINGLE message, TWO Task calls]
- Production Readiness Specialist (verify fixes)
- TypeScript Connoisseur (verify type improvements)

Step 3: Receive verification feedback

Step 4: Confirm issues resolved or identify remaining work

Step 5: Present updated status
- ✅ Fixed: [list resolved issues]
- 🔴 Remaining: [list unresolved critical issues]
- ⚠️ New findings: [any new issues discovered]
```

## Quality Gates

### Pre-Merge Gate

**Criteria:**
- [ ] 🔴 Zero critical issues (security, performance, data loss, breaks)
- [ ] ⚠️ High value issues addressed or tracked in backlog with justification
- [ ] Test Writer confirms: 100% behavior coverage, no implementation detail tests
- [ ] All tests passing
- [ ] TypeScript: No compiler errors, strict mode compliant

**Enforcement:**
Main Agent must verify all criteria before allowing Quality & Refactoring Specialist to merge.

### Pre-Production Gate

**Criteria:**
- [ ] All Pre-Merge Gate criteria met
- [ ] Production Readiness Specialist approval for security and performance-sensitive features
- [ ] Quality & Refactoring Specialist approval: No critical maintainability issues
- [ ] Documentation Specialist: All learnings captured in project CLAUDE.md

**Enforcement:**
Main Agent must verify all criteria before deployment proceeds.

## Common Review Scenarios

### Scenario: Found Critical Security Issue

**Agent response:**
```
[Production Readiness Specialist - Security] CRITICAL: Unvalidated user input in /api/payment
```

**Main Agent action:**
1. Mark as 🔴 CRITICAL in synthesized feedback
2. Block merge/deploy until fixed
3. After fix: Re-invoke Production Readiness Specialist to verify
4. Ensure Test Writer adds security tests

### Scenario: Conflicting Feedback

**Agent responses:**
```
[Quality & Refactoring Specialist] Extract this repeated code into shared function
[Quality & Refactoring Specialist] (Later assessment) Duplication is acceptable here - patterns differ semantically
```

**Main Agent action:**
1. Recognize conflict or seek clarification from Quality & Refactoring Specialist
2. Analyze context (are patterns truly the same semantically?)
3. Make judgment call based on agent's refined assessment:
   - If semantic duplication → extract shared function
   - If semantic difference → keep duplication
4. Explain reasoning in synthesized feedback

### Scenario: All Agents Approve

**Agent responses:**
```
[Quality & Refactoring] No issues found. Clean code.
[Test Writer] 100% coverage. All behaviors tested. No implementation detail tests.
[TypeScript] Strict mode compliant. Proper types used. No issues.
[Production Readiness] No security or performance issues found.
```

**Main Agent action:**
```
Code Review: ✅ APPROVED

All quality gates passed:
- Code quality: Clean, maintainable code
- Test coverage: 100% behavior coverage
- Type safety: Strict mode compliant
- Security & Performance: No issues identified

Ready to merge.
```

## Summary

Code review is a multi-agent, parallel process:

1. **Main Agent determines review type** based on code scope
2. **Agents review in parallel** from specialized perspectives
3. **Main Agent synthesizes** into prioritized, actionable feedback
4. **Severity-based prioritization** ensures focus on high-impact issues
5. **Quality gates** enforce standards before merge/deploy

**Key principle:** Comprehensive quality through specialized expertise, synthesized into clear action items.
