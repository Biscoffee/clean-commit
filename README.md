# clean-commit

> A Claude Code **Skill** that turns "just commit it" into a disciplined, reviewable workflow — in any project, any language.

**English** · [中文](README.zh-CN.md)

When you ask Claude Code to commit, push, or open a PR, `clean-commit` takes over and does what a careful engineer would: read the diff, keep secrets and junk out, split work into coherent commits, write the message in *your repo's* style, and never push or rewrite history behind your back.

It binds to the **process**, not to anyone's setup — branch, remote, commit conventions, and project type are all discovered at runtime. Nothing about your directory layout or toolchain is assumed, so it works the same in a Rust crate, a Node app, or a one-file Python script.

## The 8-step workflow

| # | Step | What it guarantees |
|---|------|--------------------|
| 1 | **Probe the environment** | Confirms it's a git repo; reads branch & remote; warns before pushing from `main`/`master` |
| 2 | **See exactly what changed** | Reads the diff and understands every hunk — never `git add .` blindly |
| 3 | **Self-check for secrets** | Scans for tokens / keys / `.env` contents; **stops** if a secret would be committed |
| 4 | **Drop temporary files** | Keeps scratch, debug, and build artifacts out of the commit |
| 5 | **Split into logical commits** | One coherent change per commit, each revertible on its own |
| 6 | **Match the repo's message style** | Follows your project's existing convention instead of imposing one |
| 7 | **Verify before committing** | Runs the project's tests/build when one exists and is cheap |
| 8 | **Push / PR only when asked** | Never pushes, force-pushes, or rewrites history unsolicited |

## Example

```
You: 提交一下这些改动

clean-commit:
  • repo ✓   branch: feature/reset-password   remote: origin
  • diff: 2 files (auth/reset.ts, auth/reset.test.ts)
  • secret scan: clean
  • convention: commitlint.config.js found → Conventional Commits enforced
  • existing style: feat(scope): … in English

  Proposed commit:
    feat(auth): add password-reset flow

    Send a one-time token by email and verify it before allowing a
    new password. Covered by reset.test.ts.

  Tests: `npm test` → 14 passing
  Committed. (not pushed — say "push" when you're ready)
```

## Conventional Commits, done right

`clean-commit` never *forces* a convention on a repo that doesn't use one. But when your repo already uses — or enforces via `commitlint` / `commitizen` / a `commit-msg` hook — Conventional Commits, it applies the rules precisely: correct `type`, optional `scope`, imperative-mood summary, and `!` / `BREAKING CHANGE:` for breaking changes.

That behavior is grounded in the actual standards, not guesswork:

- [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
- Angular commit message guidelines
- [Semantic Versioning 2.0.0](https://semver.org/)
- [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) (MUST / SHOULD / MAY)

## Install

Clone anywhere, then make it visible to Claude Code by linking it into your skills directory:

The skill lives in the `clean-commit/` subfolder, so installing is just dropping that folder into your skills directory:

```sh
git clone https://github.com/Biscoffee/clean-commit.git ~/clean-commit

# option A — symlink the skill folder (drop-in; recommended)
ln -s ~/clean-commit/clean-commit ~/.claude/skills/clean-commit

# option B — copy it instead of linking
cp -r ~/clean-commit/clean-commit ~/.claude/skills/clean-commit
```

Then just say "commit this" / "提交一下", or invoke it explicitly with `/clean-commit`.

To scope it to a single project instead of globally, point it at `<project>/.claude/skills/clean-commit` instead of `~/.claude/skills/clean-commit`.

## What it will not do

- Commit secrets, or files you didn't intend to include
- Invent a commit convention that contradicts the repo's history
- Push, force-push, or rewrite history unless you explicitly ask
- Add a `Co-Authored-By` trailer by default
- Continue silently when a check fails — it stops and tells you

## Files

- [`clean-commit/SKILL.md`](clean-commit/SKILL.md) — the skill itself (frontmatter + workflow + Conventional Commits appendix)
- [`design-notes.md`](design-notes.md) — the design thinking: what a Skill is, private vs distributable skills, and why this one targets general programmers
- [`README.zh-CN.md`](README.zh-CN.md) — 中文说明

## License

MIT — see `LICENSE` (add one before publishing widely if you want explicit terms).
