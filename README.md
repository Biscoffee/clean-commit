# clean-commit

A Claude Code **Skill** that enforces a disciplined, language-agnostic workflow for committing changes to git/GitHub — for any project, any language.

It binds to the *process*, not to anyone's setup: it discovers branch, remote, conventions, and project type at runtime, and assumes nothing about your directory layout or tooling.

## What it does

When you ask Claude Code to commit, stage, push, or open a PR, the skill walks an 8-step workflow:

1. **Probe the environment** — git repo? current branch? remote? (warns before pushing from `main`/`master`)
2. **See exactly what changed** — reads the diff; never `git add .` blindly
3. **Self-check for secrets** — scans for tokens/keys/`.env`; stops if a secret would be committed
4. **Drop temporary files** — keeps scratch/debug artifacts out of the commit
5. **Split into logical commits** — one coherent change per commit
6. **Write the message in the repo's existing style** — follows the project's convention instead of imposing one; applies Conventional Commits precisely when the repo uses or enforces it
7. **Verify before committing** — runs the project's tests/build when cheap
8. **Push / PR only when asked** — never pushes, force-pushes, or rewrites history unsolicited

It does **not** add a `Co-Authored-By` trailer by default, and never invents a commit convention that contradicts the repo's history.

A built-in appendix grounds the Conventional Commits behavior in the [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) spec, the Angular commit guidelines, [SemVer 2.0.0](https://semver.org/), and [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119).

## Install

Clone anywhere, then make it visible to Claude Code by linking it into your skills directory:

```sh
git clone https://github.com/<you>/clean-commit.git ~/clean-commit

# option A — symlink just the skill file (keeps your skills dir clean)
mkdir -p ~/.claude/skills/clean-commit
ln -s ~/clean-commit/SKILL.md ~/.claude/skills/clean-commit/SKILL.md

# option B — symlink the whole folder
ln -s ~/clean-commit ~/.claude/skills/clean-commit
```

Then in Claude Code just say "commit this" / "提交一下", or invoke it explicitly with `/clean-commit`.

To scope it to a single project instead of globally, link it into `<project>/.claude/skills/` instead of `~/.claude/skills/`.

## Files

- [`SKILL.md`](SKILL.md) — the skill itself (frontmatter + workflow + Conventional Commits appendix)
- [`design-notes.md`](design-notes.md) — the design thinking behind it: what a Skill is, private vs distributable skills, and why this one targets general programmers
