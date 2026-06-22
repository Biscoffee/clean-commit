---
name: clean-commit
description: Use when the user wants to commit, stage, push, or open a PR for their changes in a git repository — "commit this", "提交一下", "push these changes", "帮我提个 PR". Enforces a disciplined, language-agnostic commit workflow: understand the diff, isolate secrets, split by logical unit, write messages that match the repo's existing style, verify before pushing. Not for explaining git concepts or rewriting old history.
---

# clean-commit

A disciplined workflow for turning working-tree changes into clean, reviewable commits — in **any** project, any language. Bind to the *process*, not to one person's setup: discover everything at runtime, assume nothing about directory layout, tooling, or conventions.

Run the steps in order. Stop and surface the problem if any check fails — never push through a failed check silently.

## 1. Probe the environment

- Confirm this is a git repo (`git rev-parse --is-inside-work-tree`). If not, say so and stop.
- **Check for an operation in progress** — a merge, rebase, or cherry-pick (look for `.git/MERGE_HEAD`, `.git/rebase-merge`, `.git/rebase-apply`, `.git/CHERRY_PICK_HEAD`, or the hint in `git status`). If one is underway, **stop**: help the user finish or abort it first, never stack a fresh commit on top of a half-done operation.
- Read current branch (`git branch --show-current`) and whether a remote exists (`git remote -v`). Note a detached HEAD and warn before committing onto it.
- If on the default branch (`main`/`master`) **and** the user wants to push, warn and offer to create a feature branch first. Local-only commits on the default branch are fine.

## 2. See exactly what changed

- Run `git status` and `git diff` (plus `git diff --staged` if anything is already staged).
- **If there is nothing to commit** (no staged, unstaged, or untracked changes), say so and stop — don't create an empty commit.
- Actually read the diff and understand each change. **Never `git add .` blindly** — you must be able to explain what every staged hunk does.
- If the changes mix unrelated concerns, note that for step 5.

## 3. Self-check for secrets

- Grep the diff for likely secrets before staging: tokens, API keys, passwords, private keys, `.env` contents, connection strings (e.g. `grep -iE 'api[_-]?key|secret|token|password|BEGIN .*PRIVATE KEY|aws_|bearer '`).
- If a secret-bearing file appears, confirm it is in `.gitignore`. If it is being tracked, **stop and flag it** — do not commit. Suggest adding to `.gitignore` (and, if already tracked, `git rm --cached`).

## 4. Drop temporary files

- Identify scratch/diagnostic/build artifacts that crept into the changes (probe scripts, `*.log`, `*.tmp`, debug dumps, editor junk). Don't stage them; suggest deleting or gitignoring.

## 5. Split into logical commits

- One coherent change per commit (a feature, a fix, a refactor) — not one giant blob.
- Stage selectively with `git add <path>` or `git add -p`. Each commit should stand on its own and be revertible in isolation.

## 6. Write the message — match the repo's existing style

- **First, discover the convention**: `git log --oneline -20` (and inspect a few full messages with `git log -5`). Detect the language used (English/中文/…), whether it follows Conventional Commits (`type(scope): summary`), line-length habits, and whether bodies are used.
- **Check for enforced conventions**: if the repo has `commitlint.config.*`, `.czrc`, `.commitlintrc*`, a `commitizen` entry in `package.json`, or a `commit-msg` hook, the repo **enforces** Conventional Commits — follow the Appendix strictly or the commit will be rejected.
- **Follow what's already there.** Do not impose a new convention on an established repo. For a brand-new/empty repo with no signal, default to a concise `type: summary` line in the language the user is writing to you.
- **When the repo uses (or enforces) Conventional Commits**, apply the rules in the Appendix precisely: correct `type`, optional `scope`, imperative-mood summary, and `!`/`BREAKING CHANGE:` for breaking changes.
- The body (when warranted) explains **why** the change was made and **how it was verified** — not a restatement of the diff.
- Do **not** add a `Co-Authored-By` trailer by default. Add one only if the user asks, or if the repo's own history clearly does it on every commit.

## 7. Verify before committing

- Probe the project type and run the relevant gate when one exists and is cheap: `package.json` → the test/lint/build script; `Cargo.toml` → `cargo test`/`cargo build`; `Makefile` → `make test`; `pyproject.toml`/`pytest` → tests; etc.
- If tests fail, report the failure with output — do not commit on top of a broken build unless the user explicitly says to.

## 8. Push / PR — only when asked

- Commit by default; **push only when the user explicitly asks.**
- If pushing from the default branch, create a feature branch first (step 1).
- For a PR, use the platform CLI if available (`gh pr create`, `glab mr create`). Write the PR body the same way as a commit body: what changed and why, how to verify.

## Examples

**Bad — what this skill exists to prevent:**

```
$ git add .                 # swept up .env and a debug.log too
$ git commit -m "update"    # says nothing; mixes 3 unrelated changes
$ git push                  # straight onto main, no review
```

**Good — the same work, the clean-commit way.** Two unrelated changes, staged separately, secrets kept out, messages in the repo's existing `type(scope):` style:

```
$ git status                # noticed .env and debug.log — left unstaged
$ git add src/auth/reset.ts src/auth/reset.test.ts
$ git commit -m "feat(auth): add password-reset flow

Send a one-time token by email and verify it before allowing a new
password. Covered by reset.test.ts."

$ git add docs/auth.md
$ git commit -m "docs(auth): document the reset endpoint"
# not pushed — waits for the user to ask
```

The difference isn't cosmetic: each commit is independently revertible, the history reads as a story, no secret leaks, and nothing lands on a shared branch unreviewed.

## Hard rules

- Never commit secrets or files the user didn't intend to include.
- Never invent a commit convention that contradicts the repo's history.
- Never push, force-push, or rewrite history unless the user explicitly asks.
- If a check fails, stop and report — silence is not success.

## Appendix: Conventional Commits reference

Use this only when the repo already uses or enforces Conventional Commits, or when the user asks for it. Based on the Conventional Commits v1.0.0 spec, the Angular commit guidelines, SemVer 2.0.0, and RFC 2119.

**Structure**

```
<type>[optional scope][!]: <description>

[optional body]

[optional footer(s)]
```

**Types** — `feat` and `fix` are the spec's only required types; the rest are the widely-used Angular set:

| type | meaning | SemVer bump |
|------|---------|-------------|
| `feat` | a new feature | MINOR |
| `fix` | a bug fix | PATCH |
| `docs` | documentation only | — |
| `style` | formatting/whitespace, no logic change | — |
| `refactor` | neither fixes a bug nor adds a feature | — |
| `perf` | performance improvement | — |
| `test` | adds or corrects tests | — |
| `build` | build system or external dependencies | — |
| `ci` | CI configuration and scripts | — |
| `chore` | other maintenance, no src/test change | — |
| `revert` | reverts a previous commit | — |

**Scope** — optional noun in parentheses naming the affected area, e.g. `feat(parser):`. May be omitted for cross-cutting changes.

**Description (summary)** — follow Angular's rules: imperative present tense ("change", not "changed"/"changes"), no capitalized first letter, no trailing period. Keep it short.

**Body** — start one blank line after the description; explain *why* and *how verified*, in imperative present tense.

**Breaking changes** (→ SemVer MAJOR) — signal in **either** way:
- a `!` before the colon: `feat(api)!: drop support for v1 tokens`
- a footer `BREAKING CHANGE: <description with migration steps>` (this token MUST be uppercase)

**Footers** — `Token: value` or `Token #value`; use `-` instead of spaces in multi-word tokens (`Reviewed-by:`), except `BREAKING CHANGE`. Common ones: `Closes #123` / `Fixes #123` (link issues), `Refs:`, `DEPRECATED:`.

**SemVer mapping** — `fix:` → PATCH, `feat:` → MINOR, any breaking change → MAJOR. This is what tools like semantic-release / standard-version read to auto-bump versions and build the changelog.

**RFC 2119 reading** — in this spec, MUST/REQUIRED = absolute; SHOULD/RECOMMENDED = strong default, deviate only with good reason; MAY/OPTIONAL = genuinely optional.
