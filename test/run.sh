#!/usr/bin/env bash
#
# clean-commit scenario tests.
#
# A Skill is a prompt, not a program, so these tests don't exercise Claude's
# judgment. What they DO guarantee is that the probe commands SKILL.md relies
# on produce the expected signal in each situation — if git ever changed its
# behavior, or a step referenced a wrong command, these would catch it.
#
# Run:  bash test/run.sh      (exits non-zero if any scenario fails)

set -u

# Isolate from the machine's global/system git config so results are
# deterministic regardless of who runs this.
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_SYSTEM=/dev/null

PASS=0
FAIL=0
ok() { printf '  \033[32mPASS\033[0m %s\n' "$1"; PASS=$((PASS + 1)); }
no() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAIL=$((FAIL + 1)); }

newrepo() { # make a throwaway repo with a valid identity; echo its path
	local d
	d=$(mktemp -d)
	git -C "$d" init -q -b main
	git -C "$d" config user.email dev@example.test
	git -C "$d" config user.name dev
	echo "$d"
}

echo "clean-commit scenario tests"
echo

# 1 — not a git repo (step 1 must stop)
echo "1) not a git repo"
d=$(mktemp -d)
if git -C "$d" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	no "should not look like a repo"
else
	ok "detected as non-repo"
fi
rm -rf "$d"

# 2 — on the default branch (warn before pushing)
echo "2) on the default branch"
d=$(newrepo)
echo x >"$d/a"
git -C "$d" add a
git -C "$d" commit -qm "feat: init"
[ "$(git -C "$d" branch --show-current)" = main ] &&
	ok "branch detected as main" || no "branch not main"
rm -rf "$d"

# 3 — merge in progress (.git/MERGE_HEAD present)
echo "3) merge in progress"
d=$(newrepo)
printf 'base\n' >"$d/f"
git -C "$d" add f
git -C "$d" commit -qm "feat: base"
git -C "$d" checkout -q -b other
printf 'other\n' >"$d/f"
git -C "$d" commit -qam "feat: other"
git -C "$d" checkout -q main
printf 'mine\n' >"$d/f"
git -C "$d" commit -qam "feat: mine"
git -C "$d" merge other -q >/dev/null 2>&1
[ -f "$d/.git/MERGE_HEAD" ] &&
	ok "MERGE_HEAD present" || no "no MERGE_HEAD"
rm -rf "$d"

# 4 — missing commit identity (step 1 must ask)
echo "4) missing commit identity"
d=$(mktemp -d)
git -C "$d" init -q -b main
if [ -z "$(git -C "$d" config user.email || true)" ]; then
	ok "empty identity detected"
else
	no "identity unexpectedly set"
fi
rm -rf "$d"

# 5 — a secret in the changes (step 3 must block)
echo "5) secret in the changes"
d=$(newrepo)
printf 'API_KEY=sk-test-FAKE0123456789\n' >"$d/.env"
git -C "$d" add -A
git -C "$d" diff --cached | grep -qiE 'api[_-]?key|secret|sk-[a-z0-9]' &&
	ok "secret detected" || no "secret missed"
rm -rf "$d"

# 6 — leftover conflict markers (caught by git diff --check)
echo "6) leftover conflict markers"
d=$(newrepo)
printf 'a\n' >"$d/f"
git -C "$d" add f
git -C "$d" commit -qm "feat: base"
printf '<<<<<<< HEAD\nx\n=======\ny\n>>>>>>> b\n' >"$d/f"
git -C "$d" diff --check | grep -qi 'conflict' &&
	ok "conflict markers flagged" || no "conflict markers missed"
rm -rf "$d"

# 7 — trailing whitespace (caught by git diff --check)
echo "7) trailing whitespace"
d=$(newrepo)
printf 'clean\n' >"$d/f"
git -C "$d" add f
git -C "$d" commit -qm "feat: base"
printf 'trailing   \n' >"$d/f"
git -C "$d" diff --check | grep -qiE 'whitespace|trailing' &&
	ok "whitespace flagged" || no "whitespace missed"
rm -rf "$d"

# 8 — nothing to commit (step 2 must stop, no empty commit)
echo "8) nothing to commit"
d=$(newrepo)
echo x >"$d/a"
git -C "$d" add a
git -C "$d" commit -qm "feat: init"
[ -z "$(git -C "$d" status --porcelain)" ] &&
	ok "clean tree detected" || no "tree not clean"
rm -rf "$d"

# 9 — large file added (step 4 suggests LFS)
echo "9) large file added"
d=$(newrepo)
dd if=/dev/zero of="$d/big.bin" bs=1048576 count=6 >/dev/null 2>&1
sz=$(wc -c <"$d/big.bin" | tr -d ' ')
[ "$sz" -gt 5000000 ] &&
	ok "large file (${sz} bytes) detectable" || no "file too small ($sz)"
rm -rf "$d"

# 10 — pre-commit hooks present (step 7 respects them)
echo "10) pre-commit hooks present"
d=$(newrepo)
mkdir -p "$d/.husky"
printf '#!/bin/sh\n' >"$d/.husky/pre-commit"
{ [ -d "$d/.husky" ] || [ -f "$d/.pre-commit-config.yaml" ]; } &&
	ok "hooks detected" || no "hooks missed"
rm -rf "$d"

# 11 — enforced Conventional Commits + existing type(scope) style (step 6)
echo "11) Conventional Commits enforced + existing style"
d=$(newrepo)
echo x >"$d/a"
git -C "$d" add a
git -C "$d" commit -qm "feat(core): add a"
git -C "$d" commit -q --allow-empty -m "fix(core): patch b"
printf "module.exports={extends:['@commitlint/config-conventional']}\n" >"$d/commitlint.config.js"
enforced=no
[ -f "$d/commitlint.config.js" ] && enforced=yes
styled=no
git -C "$d" log --oneline -5 | grep -qE ' (feat|fix|chore)(\(.+\))?: ' && styled=yes
[ "$enforced" = yes ] && [ "$styled" = yes ] &&
	ok "enforced config + type(scope): history detected" ||
	no "enforced=$enforced styled=$styled"
rm -rf "$d"

# 12 — local branch behind remote (step 8 pulls --rebase before pushing)
echo "12) local branch behind remote"
remote=$(mktemp -d)
git -C "$remote" init -q --bare
git -C "$remote" symbolic-ref HEAD refs/heads/main # default branch = main
a=$(mktemp -d)
git clone -q "$remote" "$a" 2>/dev/null
git -C "$a" config user.email a@example.test
git -C "$a" config user.name a
echo 1 >"$a/f"
git -C "$a" add f
git -C "$a" commit -qm "feat: first"
git -C "$a" branch -M main
git -C "$a" push -qu origin main
b=$(mktemp -d)
git clone -q "$remote" "$b" 2>/dev/null
git -C "$b" config user.email b@example.test
git -C "$b" config user.name b
echo 2 >"$b/g"
git -C "$b" add g
git -C "$b" commit -qm "feat: second"
git -C "$b" push -q
git -C "$a" fetch -q
behind=$(git -C "$a" rev-list --count HEAD..origin/main 2>/dev/null || echo 0)
[ "$behind" -gt 0 ] &&
	ok "local is $behind behind origin" || no "not detected behind ($behind)"
rm -rf "$remote" "$a" "$b"

echo
echo "----------------------------------------"
printf 'Total: %d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
