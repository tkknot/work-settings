# Agent Guidelines

Think in English, Answer in Japanese.

## Subagent Usage

- Use subagents whenever possible.
- Keep the main context window clean by delegating research, exploration, and parallel analysis to subagents.
- For complex problems, parallelize across multiple subagents. One task per subagent is the default.

## Problem Solving

- Stop and re-plan immediately when something goes wrong.
- Before completing a task, self-review your work.

## Error Handling & Recovery

- Diagnose the root cause before retrying any failed operation. Never retry blindly.
- When uncertain, ask clarifying questions rather than proceeding with assumptions.
- For logic errors, change the approach. For transient errors (network, file locks), retry.

## Continuous Improvement

- When an agent exhibits incorrect behavior, update this AGENTS.md to prevent recurrence.
- If the issue warrants reusable guardrails, create dedicated skills, agents, or commands under `~/.ai/` and report the created paths to the user.
- Treat every behavioral mistake as a learning opportunity: diagnose the root cause, codify the fix, and verify it addresses the original issue.

## Human-in-the-Loop

- At the end of your response, clearly list any decisions or trade-offs that require human judgment.

---

## Repository: work-settings

開発ツールの設定を一元管理するdotfilesリポジトリ。

### 構成

| ディレクトリ/ファイル | 説明 |
|---|---|
| `.ai/` | AIエージェント・スキル・コマンド・ルールの定義 |
| `.claude/` | Claude Code固有の設定（settings.json） |
| `nvim/` | Neovim設定（LazyVimベース） |
| `wezterm/` | WezTerm設定 |
| `git/` | グローバルgit設定 |
| `sync_*_settings.sh` | 各ツールの設定をホームディレクトリに配布するスクリプト |

### `.ai/` のファイル命名規則

`.ai/agents/`, `.ai/commands/`, `.ai/skills/` 配下は `{prefix}--{name}` 形式で命名する。
詳細は `.ai/rules/file-naming-convention.md` を参照。

### ローカル作業ファイル

`_local.` prefixのファイルはgitignoreで無視される。会社環境でのメモやスクラッチコードに使用する。
例: `_local.notes.md`, `_local.scratch.py`
