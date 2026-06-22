# clean-commit

> 一个 Claude Code **Skill**，把随手的「提交一下」变成有纪律、可审查的流程——适用于任何项目、任何语言。

[English](README.md) · **中文**

当你让 Claude Code 提交、推送或开 PR 时，`clean-commit` 会接管，并像一个细心的工程师那样做事：读懂改动、把密钥和垃圾文件挡在外面、把工作拆成内聚的提交、用**你这个仓库**的风格写 message，并且绝不背着你 push 或改写历史。

它绑定的是**流程**，而不是任何人的环境——分支、远程、提交规范、项目类型全部在运行时探测。不假设你的目录结构或工具链，所以它在 Rust crate、Node 应用、还是单文件 Python 脚本里表现一致。

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

## 示例

```
你: 提交一下这些改动

clean-commit:
  • 仓库 ✓   分支: feature/reset-password   远程: origin
  • diff: 2 个文件 (auth/reset.ts, auth/reset.test.ts)
  • 密钥扫描: 干净
  • 约定: 发现 commitlint.config.js → 强制约定式提交
  • 已有风格: feat(scope): … 英文

  拟提交:
    feat(auth): add password-reset flow

    Send a one-time token by email and verify it before allowing a
    new password. Covered by reset.test.ts.

  测试: `npm test` → 14 passing
  已提交。（未 push——准备好了说一声 "push"）
```

## 约定式提交，做得准确

`clean-commit` 绝不会对一个本来不用约定的仓库**强加**约定。但当你的仓库已经在用——或通过 `commitlint` / `commitizen` / `commit-msg` hook 强制——约定式提交时，它会精确套用规则：正确的 `type`、可选的 `scope`、祈使语气的摘要，以及破坏性变更用 `!` / `BREAKING CHANGE:` 标注。

这套行为落地于真实标准，而非凭感觉：

- [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
- Angular 提交信息规范
- [语义化版本 2.0.0](https://semver.org/lang/zh-CN/)
- [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119)（MUST / SHOULD / MAY 的含义）

## 安装

克隆到任意位置，再把它链接进你的 skills 目录，让 Claude Code 能看到：

skill 本体放在 `clean-commit/` 子文件夹里，所以安装就是把这个文件夹放进你的 skills 目录：

```sh
git clone https://github.com/Biscoffee/clean-commit.git ~/clean-commit

# 方式 A —— 软链接整个 skill 文件夹（即插即用，推荐）
ln -s ~/clean-commit/clean-commit ~/.claude/skills/clean-commit

# 方式 B —— 直接复制而非软链接
cp -r ~/clean-commit/clean-commit ~/.claude/skills/clean-commit
```

然后直接说「提交一下」/「commit this」，或用 `/clean-commit` 显式调用。

若只想在单个项目里用而非全局，把它指向 `<项目>/.claude/skills/clean-commit` 而不是 `~/.claude/skills/clean-commit`。

## 它不会做什么

- 提交密钥，或你没打算包含的文件
- 编造一套与仓库历史相冲突的提交规范
- 未经你明确要求就 push、force-push 或改写历史
- 默认添加 `Co-Authored-By` 署名
- 检查失败时闷头继续——它会停下并告诉你

## 文件

- [`clean-commit/SKILL.md`](clean-commit/SKILL.md) —— skill 本体（frontmatter + 流程 + 约定式提交附录）
- [`design-notes.md`](design-notes.md) —— 设计思考：Skill 是什么、私人 vs 可分发 Skill、为何面向泛程序员
- [`README.md`](README.md) —— English README

## 许可证

MIT —— 见 `LICENSE`（如需明确条款，正式大范围发布前补一个）。
