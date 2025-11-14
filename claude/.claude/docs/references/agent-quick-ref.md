# Agent Selection & Invocation - Quick Reference

## Agent Roster

| Agent | Primary Domain | When to Invoke |
|-------|---------------|----------------|
| **Technical Architect** | Task breakdown, planning | New features, complex changes, unclear requirements |
| **Test Writer** | TDD, behavioral testing | Writing tests, verifying coverage, test strategy |
| **TypeScript Connoisseur** | TypeScript patterns, Zod schemas | Type definitions, schema design, TypeScript questions |
| **Code Quality Enforcer** | Code style, patterns, anti-patterns | Code review, style questions, refactoring assessment |
| **Refactoring Specialist** | Post-green refactoring | After tests pass, code improvement, abstraction |
| **Security Specialist** | Security review, vulnerabilities | Auth, sensitive data, before production, code review |
| **API Design Specialist** | API contracts, REST/GraphQL | Designing endpoints BEFORE implementation |
| **Database Design Specialist** | Schema design, optimization | Database schema BEFORE implementation |
| **Performance Specialist** | Optimization, profiling | Performance issues, before release, critical paths |
| **Bash/Shell Specialist** | Shell scripts, automation | Installation scripts, git hooks, CLI tools |
| **React Engineer** | React components, hooks, SSR | React-specific implementation |
| **Backend TypeScript Developer** | Lambda, API, database patterns | Backend implementation, AWS services |
| **AWS CDK Expert** | Infrastructure as code | CDK stacks, AWS resources, deployment |
| **Git Specialist** | Version control, commits, PRs | Git operations, commit messages, branching |
| **Documentation Agent** | Project documentation | Update CLAUDE.md, write docs, capture learnings |

## Domain Agent Selection by Task Type

| Task Type | Primary Agent | Supporting Agents |
|-----------|--------------|-------------------|
| API design | API Design Specialist | TypeScript Connoisseur, Security Specialist |
| Database schema | Database Design Specialist | TypeScript Connoisseur, Backend Developer |
| React component | React Engineer | TypeScript Connoisseur, Test Writer |
| Lambda function | Backend TypeScript Developer | API Design Specialist, Database Design Specialist |
| Shell scripts | Bash/Shell Specialist | — |
| Security review | Security Specialist | Test Writer, Domain Agent |
| Performance optimization | Performance Specialist | Database Design Specialist, Domain Agent |
| CDK infrastructure | AWS CDK Expert | Backend TypeScript Developer, Security Specialist |
| Type definitions | TypeScript Connoisseur | — |
| Testing | Test Writer | Domain agent for setup |
| Refactoring | Refactoring Specialist | Code Quality Enforcer, Test Writer |
| Git operations | Git Specialist | — |

## Decision Tree

### New Feature
```
Technical Architect (breakdown)
  ↓
API/DB Design Specialists (if needed, parallel)
  ↓
FOR EACH TASK:
  Test Writer (failing test)
    ↓
  Domain Agent (implement)
    ↓
  Test Writer (verify)
    ↓
  Security/Performance (if needed, parallel)
    ↓
  Refactoring Specialist (assess)
    ↓
  Git Specialist (commit)
```

### Bug Fix
```
Test Writer (reproduce with failing test)
  ↓
Domain Agent (fix)
  ↓
Test Writer (verify + edge cases)
  ↓
Refactoring Specialist (assess if larger issues)
  ↓
Git Specialist (commit)
```

### Refactoring
```
Refactoring Specialist (assess)
  ↓
Test Writer (verify 100% coverage)
  ↓
Domain Agent (refactor maintaining API)
  ↓
Test Writer (tests pass unchanged)
  ↓
Code Quality Enforcer (review)
  ↓
Git Specialist (commit)
```

### Code Review
```
[Code Quality + Test Writer + TypeScript + Security] (parallel)
  ↓
Main Agent (synthesize feedback)
```

### Documentation
```
Documentation Agent → Domain Agent (if needed) → Git Specialist
```

### Security Review
```
Security Specialist (identify)
  ↓
Test Writer (security tests)
  ↓
Domain Agent (fix)
  ↓
Security Specialist (verify)
  ↓
Git Specialist (commit)
```

### Performance Optimization
```
Performance Specialist (profile)
  ↓
Test Writer (benchmark)
  ↓
Domain Agent (optimize)
  ↓
Performance Specialist (verify)
  ↓
Test Writer (regression test)
  ↓
Git Specialist (commit)
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
- **Agents**: Code Quality Enforcer + Test Writer + TypeScript Connoisseur + Security Specialist
- **When**: Pre-merge, pre-production, significant refactoring

**Pattern 2: Parallel Design Phase**
- **Agents**: API Design Specialist + Database Design Specialist
- **When**: New feature requiring multiple design domains

**Pattern 3: Security + Performance Audit**
- **Agents**: Security Specialist + Performance Specialist
- **When**: Pre-production readiness, critical features

**Pattern 4: Post-Implementation Verification**
- **Agents**: Test Writer + Security Specialist + Performance Specialist
- **When**: After feature implementation, before complete

**Pattern 5: Parallel Investigation**
- **Agents**: Varies (Performance + Domain Agent + Test Writer)
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
Main → Architect → Test Writer → Domain Agent → Refactoring → Git
```

**Parallel Consultation** (cross-cutting concerns):
```
Main → [Code Quality + Test Writer + TypeScript] → Synthesize
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
