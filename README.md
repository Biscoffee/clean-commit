# clean-commit

> 一个 Claude Code **Skill**，把随手的「提交一下」变成有纪律、可审查的流程——适用于任何项目、任何语言。

**中文** · [English](README.en.md)

当你让 Claude Code 提交、推送或开 PR 时，`clean-commit` 会接管，并像一个细心的工程师那样做事：读懂改动、把密钥和垃圾文件挡在外面、把工作拆成内聚的提交、用**你这个仓库**的风格写 message，并且绝不背着你 push 或改写历史。

它绑定的是**流程**，而不是任何人的环境——分支、远程、提交规范、项目类型全部在运行时探测。不假设你的目录结构或工具链，所以它在 Rust crate、Node 应用、还是单文件 Python 脚本里表现一致。

## 能做什么

- **提交前体检环境**：确认是 git 仓库、提交身份（`user.name`/`email`）正常，识别当前分支/远程，发现 merge·rebase·cherry-pick 中途或 detached HEAD 就停下
- **读懂你的改动**：逐处看 diff，绝不 `git add .` 一把梭；用 `git diff --check` 揪出冲突残留标记与空白错误；无改动时直接告诉你、不空转
- **拦截密钥**：扫描 token·key·`.env`·密码·私钥，可能泄露就停下报警
- **挡掉垃圾与大文件**：日志·调试·构建产物不进提交；超大/二进制文件提醒走 Git LFS 或排除
- **逻辑切分**：把混在一起的改动拆成多个内聚、可独立回滚的提交
- **跟随你仓库的 message 风格**：自动识别语言、是否约定式提交、有无 body 并照做
- **约定式提交精确执行**：检测到 `commitlint`/`commitizen` 等强制约定时，按 CC v1.0.0 / Angular / SemVer / RFC 2119 生成规范 message
- **按需补 footer**：分支名带 Issue 号就关联 `Closes`/`Refs #`；仓库要求 DCO 时加 `Signed-off-by`
- **提交前验证**：尊重并跑 pre-commit 钩子；探测 `package.json`/`Cargo.toml`/`Makefile` 等跑测试或构建
- **克制地推送**：默认只本地提交；push/PR 要你明确开口；主分支上要推先建议建特性分支（按仓库命名习惯）；push 前先与远程同步（`pull --rebase`），绝不靠 force push 解决
- **规范开 PR**：用 `gh`/`glab`，PR 描述讲清改了什么·为什么·怎么验证；开 PR 前可提议把凌乱的 WIP 提交 squash 整理

## 8 步流程

| # | 步骤 | 它保证什么 |
|---|------|-----------|
| 1 | **探测环境** | 确认是 git 仓库；读取分支与远程；在 `main`/`master` 上 push 前先提醒 |
| 2 | **看清改动** | 读懂 diff 的每一处，绝不盲目 `git add .` |
| 3 | **密钥自查** | 扫描 token / key / `.env` 内容；一旦可能提交密钥就**停下** |
| 4 | **清理临时文件** | 把草稿、调试、构建产物挡在提交之外 |
| 5 | **逻辑切分** | 一个提交一件内聚的事，每个都能单独回滚 |
| 6 | **跟随仓库的 message 风格** | 遵循你项目已有的约定，而不是强加一套 |
| 7 | **提交前验证** | 探测到项目的测试/构建且代价不高时先跑一遍 |
| 8 | **仅在你要求时 push/PR** | 绝不擅自 push、force-push 或改写历史 |

## 完整示例

一个真实的混乱工作区——改了功能、又夹带了密钥和日志、人还正站在 `main` 上：

```
你: 我写完密码重置了，提交并推上去

clean-commit:
  ① 环境   git 仓库 ✓   身份 dev <dev@acme.io> ✓   分支 main   远程 origin
           ⚠ 你在 main 上且要 push —— 建议先建特性分支
  ② 改动   4 个文件，git diff --check 无冲突/空白问题：
             src/auth/reset.ts        +58
             src/auth/reset.test.ts   +40
             .env                     新增  ← 含密钥
             debug.log                新增  ← 临时文件
  ③ 密钥   .env 命中 API_KEY → 拦下，不提交，建议加入 .gitignore
  ④ 垃圾   debug.log 是临时文件 → 不提交，建议 gitignore
  ⑤ 切分   剩余两个文件属同一功能 → 合为 1 个提交
  ⑥ 规范   历史是 feat(scope): 英文 + commitlint 强制 → 按约定式提交

  我建议这样执行：
    git switch -c feat/password-reset
    printf '.env\ndebug.log\n' >> .gitignore && git add .gitignore
    git add src/auth/reset.ts src/auth/reset.test.ts
    git commit -m "feat(auth): add password-reset flow

    Email a one-time token and verify it before allowing a new
    password. Covered by reset.test.ts."

  ⑦ 验证   npm test → 14 passing ✓
  ⑧ 推送   git fetch：未落后 → git push -u origin feat/password-reset
           要我顺手开个 PR 吗？(gh pr create)

确认后我才执行。
```

## 各种情况下它怎么做

| 情况 | clean-commit 的反应 |
|---|---|
| 不在 git 仓库 | 说明并停下 |
| 处于 merge / rebase / cherry-pick 中途 | 停下，先帮你完成或中止 |
| `user.name`/`email` 没配或离谱 | 停下，先让你设置 |
| 在 `main`/`master` 上要 push | 提醒并建议先建特性分支 |
| diff 里有密钥 / `.env` | 拦下，建议 gitignore，不提交 |
| 残留冲突标记 / 行尾空白 | `git diff --check` 揪出，先修再提交 |
| 没有任何改动 | 直接说「无可提交」，不空转 |
| 加入超大 / 二进制文件 | 提醒走 Git LFS 或排除 |
| 仓库强制约定式提交 | 按 CC v1.0.0 精确生成 message |
| 一堆 wip/fixup 提交要开 PR | 提议 squash 整理 |
| 本地落后于远程 | 先 `pull --rebase` 再 push，绝不 force |
| 测试失败 | 带输出报告，不在坏构建上提交 |

## 测试

仓库自带 [`test/run.sh`](test/run.sh)，为上面每种情况搭建临时仓库、校验 skill 依赖的探测信号。它不测 Claude 的判断（那是 prompt 的事），但保证流程引用的 git 命令在各场景下确实给出预期信号：

```sh
bash test/run.sh   # 预期输出 Total: 12 passed, 0 failed
```

## 约定式提交，做得准确

`clean-commit` 绝不会对一个本来不用约定的仓库**强加**约定。但当你的仓库已经在用——或通过 `commitlint` / `commitizen` / `commit-msg` hook 强制——约定式提交时，它会精确套用规则：正确的 `type`、可选的 `scope`、祈使语气的摘要，以及破坏性变更用 `!` / `BREAKING CHANGE:` 标注。

这套行为落地于真实标准，而非凭感觉：

- [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
- Angular 提交信息规范
- [语义化版本 2.0.0](https://semver.org/lang/zh-CN/)
- [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119)（MUST / SHOULD / MAY 的含义）

## 安装

skill 本体放在 `clean-commit/` 子文件夹里，安装就是把这个文件夹放进你的 skills 目录，让 Claude Code 能看到它：

```sh
git clone https://github.com/Biscoffee/clean-commit.git ~/clean-commit

# 方式 A —— 软链接整个 skill 文件夹（即插即用，推荐）
ln -s ~/clean-commit/clean-commit ~/.claude/skills/clean-commit

# 方式 B —— 直接复制而非软链接
cp -r ~/clean-commit/clean-commit ~/.claude/skills/clean-commit
```

然后直接说「提交一下」/「commit this」，或用 `/clean-commit` 显式调用。

若只想在单个项目里用而非全局，把它指向 `<项目>/.claude/skills/clean-commit` 而不是 `~/.claude/skills/clean-commit`。

### Codex 也能用

Codex 的 Agent Skills 用的是同一套 `SKILL.md` 格式，所以**同一个文件夹**软链进 Codex 的 skills 目录即可，正文无需任何改动：

```sh
ln -s ~/clean-commit/clean-commit ~/.agents/skills/clean-commit
```

差别只在调用语法：在 Codex 里用 `$clean-commit` 或 `/skills` 选择器，或让它按 `description` 自动触发。仓库级则放 `<项目>/.agents/skills/clean-commit`。

## 它不会做什么

- 提交密钥，或你没打算包含的文件
- 编造一套与仓库历史相冲突的提交规范
- 未经你明确要求就 push、force-push 或改写历史
- 默认添加 `Co-Authored-By` 署名
- 检查失败时闷头继续——它会停下并告诉你

## 文件

- [`clean-commit/SKILL.md`](clean-commit/SKILL.md) —— skill 本体（frontmatter + 流程 + 约定式提交附录）
- [`design-notes.md`](design-notes.md) —— 设计思考：Skill 是什么、私人 vs 可分发 Skill、为何面向泛程序员
- [`test/run.sh`](test/run.sh) —— 各情况场景测试
- [`README.en.md`](README.en.md) —— English README

## 许可证

MIT —— 见 [`LICENSE`](LICENSE)。
