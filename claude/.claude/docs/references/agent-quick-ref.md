# Agent Selection & Invocation - Quick Reference

## Agent Roster

| Agent | Primary Domain | When to Invoke |
|-------|---------------|----------------|
| **Technical Architect** | Task breakdown, planning | New features, complex changes, unclear requirements |
| **Test Writer** | TDD, behavioral testing | Writing tests, verifying coverage, test strategy |
| **TypeScript Connoisseur** | TypeScript patterns, Zod schemas | Type definitions, schema design, TypeScript questions |
| **Quality & Refactoring Specialist** | Code review, refactoring, git operations | Code review, post-green refactoring, git commits/PRs |
| **Production Readiness Specialist** | Security, performance, production prep | Security review, performance optimization, pre-production audit |
| **Design Specialist** | API & database design | Designing endpoints, schemas, contracts BEFORE implementation |
| **Bash/Shell Specialist** | Shell scripts, automation | Installation scripts, git hooks, CLI tools |
| **React Engineer** | React components, hooks, SSR | React-specific implementation |
| **Backend TypeScript Developer** | Lambda, API, database, AWS/CDK | Backend implementation, AWS services, infrastructure as code |
| **Documentation Specialist** | Project documentation | Update CLAUDE.md, write docs, capture learnings |

## Domain Agent Selection by Task Type

| Task Type | Primary Agent | Supporting Agents |
|-----------|--------------|-------------------|
| API design | Design Specialist | TypeScript Connoisseur, Production Readiness Specialist |
| Database schema | Design Specialist | TypeScript Connoisseur, Backend Developer |
| React component | React Engineer | TypeScript Connoisseur, Test Writer |
| Lambda function | Backend TypeScript Developer | Design Specialist |
| Shell scripts | Bash/Shell Specialist | — |
| Security review | Production Readiness Specialist | Test Writer, Domain Agent |
| Performance optimization | Production Readiness Specialist | Design Specialist, Domain Agent |
| CDK infrastructure | Backend TypeScript Developer | Production Readiness Specialist |
| Type definitions | TypeScript Connoisseur | — |
| Testing | Test Writer | Domain agent for setup |
| Refactoring | Quality & Refactoring Specialist | Test Writer |
| Git operations | Quality & Refactoring Specialist | — |

## Decision Tree

### New Feature
```
Technical Architect (breakdown)
  ↓
Design Specialist (API/DB if needed)
  ↓
FOR EACH TASK:
  Test Writer (failing test)
    ↓
  Domain Agent (implement)
    ↓
  Test Writer (verify)
    ↓
  Production Readiness Specialist (if needed, security/performance)
    ↓
  Quality & Refactoring Specialist (assess and refactor)
    ↓
  Quality & Refactoring Specialist (commit)
```

### Bug Fix
```
Test Writer (reproduce with failing test)
  ↓
Domain Agent (fix)
  ↓
Test Writer (verify + edge cases)
  ↓
Quality & Refactoring Specialist (assess if larger issues)
  ↓
Quality & Refactoring Specialist (commit)
```

### Refactoring
```
Quality & Refactoring Specialist (assess)
  ↓
Test Writer (verify 100% coverage)
  ↓
Domain Agent (refactor maintaining API)
  ↓
Test Writer (tests pass unchanged)
  ↓
Quality & Refactoring Specialist (review and commit)
```

### Code Review
```
[Quality & Refactoring + Test Writer + TypeScript + Production Readiness] (parallel)
  ↓
Main Agent (synthesize feedback)
```

### Documentation
```
Documentation Specialist → Domain Agent (if needed) → Quality & Refactoring Specialist
```

### Security Review
```
Production Readiness Specialist (identify)
  ↓
Test Writer (security tests)
  ↓
Domain Agent (fix)
  ↓
Production Readiness Specialist (verify)
  ↓
Quality & Refactoring Specialist (commit)
```

### Performance Optimization
```
Production Readiness Specialist (profile)
  ↓
Test Writer (benchmark)
  ↓
Domain Agent (optimize)
  ↓
Production Readiness Specialist (verify)
  ↓
Test Writer (regression test)
  ↓
Quality & Refactoring Specialist (commit)
```

## Parallelization Quick Guide

### When to Parallelize
✓ **USE PARALLEL** (one message, multiple Task calls):
- Code review (multiple perspectives on same code)
- Concurrent design (API + Database)
- Security + Performance audit
- Post-implementation verification
- Independent investigations

✗ **USE SEQUENTIAL**:
- TDD cycle (Test → Implement → Verify)
- Task dependencies (Architect breakdown → then implement)
- Verification chains (Implement → Verify → Refactor)
- Design before implementation
- Fix before verify

### Common Parallel Patterns

**Pattern 1: Comprehensive Code Review**
- **Agents**: Quality & Refactoring Specialist + Test Writer + TypeScript Connoisseur + Production Readiness Specialist
- **When**: Pre-merge, pre-production, significant refactoring

**Pattern 2: Parallel Design Phase**
- **Agents**: Design Specialist (handles both API and database design)
- **When**: New feature requiring design work (note: Design Specialist handles both API and DB)

**Pattern 3: Security + Performance Audit**
- **Agents**: Production Readiness Specialist (handles both security and performance)
- **When**: Pre-production readiness, critical features

**Pattern 4: Post-Implementation Verification**
- **Agents**: Test Writer + Production Readiness Specialist
- **When**: After feature implementation, before complete

**Pattern 5: Parallel Investigation**
- **Agents**: Varies (Production Readiness + Domain Agent + Test Writer)
- **When**: Complex bugs requiring multiple analysis angles

## Invocation Syntax

**Task tool parameters:**
- `subagent_type`: Agent name (e.g., "Test Writer")
- `description`: 3-5 word summary
- `prompt`: Detailed instructions, what to accomplish, what to return

**Single agent:**
```
[One Task tool call]
```

**Parallel agents:**
```
[Multiple Task tool calls in SINGLE message]
```

## Decision Checklist

**Is Task B dependent on Task A results?** → Sequential
**Independent tasks analyzing same artifact?** → Parallel
**Concurrent design of different components?** → Parallel
**Independent investigations?** → Parallel

## Agent Collaboration Patterns

**Sequential Delegation** (most common):
```
Main → Architect → Test Writer → Domain Agent → Quality & Refactoring (assess and commit)
```

**Parallel Consultation** (cross-cutting concerns):
```
Main → [Quality & Refactoring + Test Writer + TypeScript] → Synthesize
```

**Iterative Refinement** (complex tasks):
```
Main → Agent 1 → Main → Agent 2 → Main → Agent 1 (refinement)
```

## Main Agent Meta-Tasks (Exceptions)

Main agent may perform directly:
- Reading files for investigation
- Read-only bash (git status, git log, ls)
- Web research (WebFetch, WebSearch)
- Task tracking (TodoWrite)
- Asking questions (AskUserQuestion)

**Everything else MUST be delegated.**
