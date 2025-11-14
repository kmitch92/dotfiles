# Working with Claude Code - Quick Reference

## Expectations for All Work

### 1. Always Follow TDD
**No production code without a failing test.**

- Write failing test FIRST
- Implement minimum code to pass
- Refactor (if valuable)
- Commit

**Never:**
- Write code before tests
- Skip tests "for now"
- Test after implementation

### 2. Think Deeply Before Edits
**Understand before changing.**

- Read relevant code thoroughly
- Understand dependencies and callers
- Consider edge cases and implications
- Think through the full change

**Never:**
- Make quick fixes without understanding
- Change code based on assumptions
- Skip reading related code

### 3. Understand Full Context
**See the bigger picture.**

- Why does this code exist?
- What are the requirements?
- What are the constraints?
- What's the user impact?
- What's the architectural pattern?

**Never:**
- Focus only on immediate task
- Ignore architectural patterns
- Miss the "why" behind code

### 4. Ask Clarifying Questions
**When in doubt, ask.**

Ask when:
- Requirements are ambiguous or conflicting
- Multiple valid approaches exist
- Breaking changes might be needed
- User preference is needed
- Tradeoffs aren't clear

**Never:**
- Assume requirements
- Guess at user intent
- Make breaking changes without confirmation

### 5. Delegate to Specialists
**Main agent orchestrates, doesn't implement.**

Main agent ONLY:
- Reads files for investigation
- Runs read-only bash commands
- Does web research
- Tracks tasks
- Asks questions
- Synthesizes results

Main agent NEVER:
- Writes production code
- Edits files directly
- Creates new files
- Implements features

**All implementation delegated to specialized agents.**

### 6. Use TodoWrite for Complex Tasks
**Track progress for multi-step work.**

Use TodoWrite when:
- 3+ distinct steps required
- Multiple operations needed
- Non-trivial complexity
- User provides multiple tasks

**Format:**
- `content`: Imperative form ("Run tests")
- `activeForm`: Present continuous ("Running tests")
- `status`: pending, in_progress, completed

**Never:**
- Use for single simple tasks
- Batch completions (mark complete immediately)
- Have multiple tasks in_progress (only ONE)

### 7. Keep Project Docs Current
**Update CLAUDE.md after every feature.**

After completing work:
- Document learnings and gotchas
- Capture context that would have helped
- Note workarounds or technical debt
- Update architectural decisions

**This is CRITICAL.**

---

## When to Ask vs. Proceed

### Ask User First

**Requirements Issues:**
- Requirements ambiguous or conflicting
- Multiple interpretations possible
- Unclear acceptance criteria
- Edge cases not specified

**Approach Decisions:**
- Multiple valid approaches with different tradeoffs
- Architectural pattern unclear
- Library/tool choice needed
- Performance vs. maintainability tradeoff

**Breaking Changes:**
- Would break existing API
- Would require migration
- Would affect other systems
- Would change user-facing behavior

**User Preference:**
- Subjective decisions (naming, structure)
- Configuration choices
- Feature scope decisions
- Priority decisions

### Proceed with Delegation

**Clear Requirements:**
- Single obvious interpretation
- Well-defined acceptance criteria
- Standard patterns apply
- No ambiguity

**Standard Approach:**
- Follows established conventions
- Uses existing patterns
- No architectural decisions needed
- Clear implementation path

**No Breaking Changes:**
- Backwards compatible
- Internal only
- No migration needed
- Safe to proceed

**Follows Conventions:**
- Uses project patterns
- Matches existing code style
- Standard solution
- Low risk

---

## Code Changes Process

### Every Change Follows This Flow

**1. Triage (Main Agent)**
- Understand requirements
- Identify appropriate agents
- Determine parallel vs. sequential
- Delegate to Technical Architect (if complex)

**2. Planning (Technical Architect, if needed)**
- Break into testable tasks
- Identify dependencies
- Plan execution order
- Define success criteria

**3. For Each Task:**

**Test Writer** → Write failing test
- Verify behavior through public API
- Cover edge cases
- Test error paths

**Domain Agent** → Implement minimum code
- Pass the failing test
- Follow standards
- Keep it simple

**Test Writer** → Verify coverage
- All behaviors tested
- Edge cases covered
- 100% coverage side effect

**Quality & Refactoring Specialist** → Assess and refactor
- Identify improvements
- Refactor if valuable
- Maintain test pass

**Quality & Refactoring Specialist** → Commit changes
- Conventional commit format
- Explain "why" not "what"
- Reference tickets

**4. Documentation (Documentation Specialist)**
- Update project CLAUDE.md
- Capture learnings
- Document decisions

---

## Plan Requirements

### Every Plan Must Include

**1. Assign Sub-Agents to Every Step**

❌ **DON'T:**
```
1. Write tests for authentication
2. Implement authentication
3. Commit changes
```

✅ **DO:**
```
Step 1: Test Writer - Write failing tests for user authentication
Step 2: Backend TypeScript Developer - Implement auth to pass tests (after Step 1)
Step 3: Production Readiness Specialist - Security review auth implementation (after Step 2)
Step 4: Quality & Refactoring Specialist - Assess refactoring opportunities (after Step 2)
Step 5: Quality & Refactoring Specialist - Commit auth implementation (after Steps 3 and 4)
```

**2. Use Consistent Format**
```
Step N: [Agent Name] - [Task description] [execution model]
```

**3. Specify Execution Model**
- Sequential (default): "(after Step N)"
- Parallel: "(parallel with Step N)"
- Independent: no annotation

### Plan Review Checklist

- [ ] Every step assigned to specific agent
- [ ] No generic "implement X" or "test Y"
- [ ] Main agent never implements directly
- [ ] Execution model clear (parallel/sequential)
- [ ] Dependencies explicitly stated
- [ ] Return expectations clear

---

## Communication Standards

### Be Explicit About Tradeoffs

**✅ DO:**
```
Approach A: Faster implementation, but less flexible for future changes
Approach B: More upfront work, but easier to extend later
Recommendation: B, because requirements suggest future extensions
```

**❌ DON'T:**
```
I'll use Approach B.
```

### Explain Reasoning

**✅ DO:**
```
Using Zod schema here because this is a trust boundary (API input).
This ensures type safety at runtime, not just compile time.
```

**❌ DON'T:**
```
Adding Zod schema.
```

### Flag Deviations

**✅ DO:**
```
Note: Using 'interface' instead of 'type' here because we're extending
a third-party library interface that uses 'interface' pattern.
```

**❌ DON'T:**
```
[Silently uses interface]
```

### Suggest Improvements

**✅ DO:**
```
Current approach works, but consider using Result type instead of throwing
exceptions. This makes error handling more explicit and type-safe.
```

**❌ DON'T:**
```
[Says nothing about potential improvements]
```

### Ask When Unsure

**✅ DO:**
```
I see two valid approaches here:
1. In-memory cache (simpler, but lost on restart)
2. Redis cache (more complex, but persists)

What's the priority: simplicity or persistence?
```

**❌ DON'T:**
```
[Picks one without asking]
```

---

## Providing Feedback

### When Claude Makes Mistakes

**Redirect, don't criticize:**

❌ **DON'T:**
```
You did this wrong. You should have done X instead.
```

✅ **DO:**
```
Please delegate this to [Agent Name] instead of implementing directly.
```

or

```
The requirement is X, not Y. Please revise the approach.
```

### When Claude Needs Clarification

**Provide context:**

❌ **DON'T:**
```
No, do it differently.
```

✅ **DO:**
```
The goal is to optimize for read performance, not write performance.
Please revise the approach to use a denormalized structure.
```

### When Claude Does Well

**Acknowledge:**

✅ **DO:**
```
Great analysis. Proceed with Approach B as recommended.
```

---

## Working with Main Agent

### Main Agent Role

**Orchestrator, NOT implementer.**

**Main Agent:**
- Triages requests
- Delegates to specialists
- Synthesizes results
- Tracks progress
- Asks questions

**Main Agent NEVER:**
- Writes code
- Edits files
- Creates files
- Implements features

### Correcting Main Agent

**If main agent starts implementing:**

```
Please delegate this to the appropriate subagent instead of implementing directly.
```

**Main agent will:**
- Stop implementation
- Identify appropriate agent
- Delegate properly
- Continue orchestration

### Expecting Proper Delegation

**Every task should show:**
1. Agent identification
2. Task delegation
3. Result synthesis
4. Next steps

**You should see:**
```
[Main Agent] I'll delegate this to Test Writer for failing tests,
then Backend Developer for implementation.

[Delegates to Test Writer via Task tool]
[Test Writer completes]

[Delegates to Backend Developer via Task tool]
[Backend Developer completes]

[Main Agent] Tests passing. Ready for review.
```

---

## Quality Signals

### Good Signals

✅ Tests written BEFORE implementation
✅ Questions asked when requirements unclear
✅ Tradeoffs explained with recommendations
✅ Proper delegation to specialists
✅ Deviations flagged and justified
✅ Code follows all standards
✅ Progress tracked with TodoWrite
✅ CLAUDE.md updated after changes

### Warning Signals

⚠️ Code without tests
⚠️ Assumptions made without asking
⚠️ Main agent implementing directly
⚠️ Standards violated without justification
⚠️ No explanation for approach
⚠️ Complex task without TodoWrite
⚠️ CLAUDE.md not updated

---

## Common Patterns

### Starting New Feature

**Expected flow:**
```
User: "Add user authentication"

Main Agent:
1. Ask clarifying questions (if needed)
2. Delegate to Technical Architect for breakdown
3. For each task:
   - Test Writer (failing test)
   - Backend Developer (implement)
   - Test Writer (verify)
   - Production Readiness Specialist (review)
   - Quality & Refactoring Specialist (assess and commit)
4. Documentation Specialist (update CLAUDE.md)
```

### Fixing Bug

**Expected flow:**
```
User: "Fix login error"

Main Agent:
1. Investigate (read files, understand context)
2. Test Writer (write failing test that reproduces bug)
3. Backend Developer (fix bug)
4. Test Writer (verify fix, add edge cases)
5. Quality & Refactoring Specialist (assess if larger issues and commit)
```

### Code Review

**Expected flow:**
```
User: "Review this code"

Main Agent:
1. Delegate to multiple agents in parallel:
   - Quality & Refactoring Specialist (style, patterns)
   - Test Writer (test coverage)
   - TypeScript Connoisseur (types)
   - Production Readiness Specialist (security, performance)
2. Synthesize feedback by severity
3. Present prioritized recommendations
```

---

## Remember

**Core Principles:**
1. Test-first (no code without failing test)
2. Behavior-driven (test public APIs)
3. Schema-first (Zod at trust boundaries)
4. Immutable (no data mutation)
5. Pure functions (no side effects)
6. Delegate to specialists (main agent orchestrates)

**Always:**
- Think deeply before changing
- Understand full context
- Ask when unsure
- Delegate to specialists
- Track complex tasks
- Update documentation

**Never:**
- Code without tests
- Assume requirements
- Skip reading context
- Have main agent implement
- Forget to update CLAUDE.md
