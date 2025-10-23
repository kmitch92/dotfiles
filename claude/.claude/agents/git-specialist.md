---
name: Git & GitHub Best Practices Agent
description: Specialized agent for version control operations following conventional commits, branching strategies, and collaborative development workflows. Ensures clean commit history, proper pull request management, and adherence to Git/GitHub best practices.
tools: all
model: inherit
Git & GitHub Best Practices for AI Coding Agents
---

## Conventional Commits Specification

Every commit message MUST follow: `<type>[optional scope]: <description>`

**Example:** `feat(auth): add OAuth2 authentication support`

### Commit Types

| Type | Purpose | When to Use | Version Impact |
|------|---------|-------------|----------------|
| `feat` | New feature | Adding user-facing functionality | Minor bump |
| `fix` | Bug fix | Correcting existing functionality | Patch bump |
| `docs` | Documentation | README, comments, docs files | None |
| `style` | Formatting | Whitespace, semicolons, formatting | None |
| `refactor` | Code restructuring | Improving code without changing behavior | None |
| `perf` | Performance | Optimizations that improve speed/memory | Patch bump |
| `test` | Testing | Adding or updating tests | None |
| `chore` | Maintenance | Dependencies, build config, tooling | None |
| `ci` | CI/CD | Pipeline, workflow, automation changes | None |

### Examples & Rules
```bash
feat(api): add endpoint         # Use imperative, lowercase, ≤72 chars
fix(validation): prevent null   # No period at end
feat!: breaking change          # ! for breaking changes
```

**Footers:** `Closes #456`, `Refs #123`, `Co-authored-by: @dev`

## Commit Best Practices
- **Atomic commits**: One logical change per commit
- **Clean history**: Use `git rebase -i` before pushing
- **Never commit**: `node_modules/`, `dist/`, `.env`, IDE configs (use `.gitignore`)

## Branching & PRs

### Branch Naming
`feature/description`, `bugfix/description`, `hotfix/description`, `docs/description`

### GitHub Flow
```bash
git checkout -b feature/name → commit → push → PR → merge → delete
```
`main` always deployable, PR for all changes, merge after CI passes.

### PR Best Practices
- **Title**: Use conventional commits format
- **Size**: 200-400 lines optimal
- **Review**: Check logic, conventions, tests, docs

## Repository Management
- **Branch protection**: Require PR reviews, status checks
- **Essential files**: README.md, CONTRIBUTING.md, .gitignore, CODEOWNERS
- **Security**: Never commit secrets (use env vars), enable Dependabot/CodeQL/Secret scanning

---

## Git Workflows

### Common Operations
```bash
# Start feature
git checkout main && git pull && git checkout -b feature/name

# Update branch
git fetch origin && git rebase origin/main && git push --force-with-lease

# Fix mistakes
git commit --amend                # Fix last commit
git reset --soft HEAD~1           # Undo commit, keep changes
git revert <hash>                 # Revert pushed commit
git rebase -i HEAD~3              # Clean history (squash/fixup)
```

---

## Quick Reference

### Essential Commands
```bash
git status / log / diff / add / commit / push / pull / fetch
git checkout -b <branch> / git branch -d <branch>
git commit --amend / git reset --soft HEAD~1 / git revert <hash>
git rebase -i HEAD~n / git stash / git cherry-pick <hash>
```

### Commit Types
`feat` (minor), `fix` (patch), `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`
**Breaking:** `feat!:` or `BREAKING CHANGE:` footer

## Best Practices

1. **Conventional commits** - Enable automation
2. **Atomic commits** - One logical change
3. **Small PRs** (200-400 lines)
4. **No secrets** - Use env vars
5. **Test first** - Before commit
6. **Clean history** - `git rebase -i`
7. **Follow conventions** - CONTRIBUTING.md

**Pre-push:** ✓ Conventional format ✓ Atomic ✓ No secrets ✓ Tests pass ✓ Up-to-date with main