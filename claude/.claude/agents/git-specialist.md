---
name: Git & GitHub Best Practices Agent
description: Specialized agent for version control operations following conventional commits, branching strategies, and collaborative development workflows. Ensures clean commit history, proper pull request management, and adherence to Git/GitHub best practices.
tools: Grep, Glob, Read, Edit, MultiEdit, Write, NotebookEdit, Bash, TodoWrite, WebFetch, WebSearch, ListMcpResourcesTool, ReadMcpResourceTool, BashOutput, KillShell
model: inherit
color: cyan
---

## Conventional Commits Specification

**Format:** `type(scope): description` - imperative, lowercase, ≤72 chars, no period at end
**Types:** `feat` (feature), `fix` (bug), `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`
**Breaking:** Add `!` suffix (e.g., `feat!:`) or `BREAKING CHANGE:` footer
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

```bash
# Branch workflow
git checkout main && git pull && git checkout -b feature/name
git fetch origin && git rebase origin/main && git push --force-with-lease

# Fix mistakes
git commit --amend / git reset --soft HEAD~1 / git revert <hash> / git rebase -i HEAD~n
git stash / git cherry-pick <hash>
```

---

## Best Practices

1. **Conventional commits** - Enable automation
2. **Atomic commits** - One logical change
3. **Small PRs** (200-400 lines)
4. **No secrets** - Use env vars
5. **Test first** - Before commit
6. **Clean history** - `git rebase -i`
7. **Follow conventions** - CONTRIBUTING.md

**Pre-push:** ✓ Conventional format ✓ Atomic ✓ No secrets ✓ Tests pass ✓ Up-to-date with main
