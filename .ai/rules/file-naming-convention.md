# .ai/ ファイル命名規則

## 概要

`.ai/` 配下の `agents/`, `commands/`, `skills/` にファイルやディレクトリを作成する際は、必ずカテゴリプレフィックスを付与する。

## フォーマット

```
{prefix}--{name}.md          # agents/, commands/
{prefix}--{name}/SKILL.md    # skills/
```

## プレフィックス一覧

| プレフィックス | カテゴリ | 説明 | 例 |
|---|---|---|---|
| `test--` | テスト | TDD, E2E, テストケース設計 | `test--tdd-guide.md` |
| `git--` | Git/ワークフロー | ブランチ管理, PR, worktree | `git--branch-analyst.md` |
| `review--` | レビュー | コードレビュー, PRレビュー | `review--code-reviewer.md` |
| `quality--` | コード品質 | リファクタリング | `quality--refactor-command.md` |
| `arch--` | アーキテクチャ | システム設計, 技術選定 | `arch--architect.md` |
| `devenv--` | 開発環境 | devcontainer | `devenv--devcontainer-manager.md` |
| `docs--` | ドキュメント | ドキュメント更新 | `docs--update-docs-command.md` |
| `research--` | 調査 | 仕様検索, コード調査 | `research--spec-researcher.md` |

## ルール

1. **新規ファイル作成時**: 上記プレフィックスの中から適切なものを選び、`{prefix}--{name}` の形式で命名する
2. **該当カテゴリがない場合**: 新しいプレフィックスを定義し、**このルールファイルのプレフィックス一覧テーブルに追記してから**ファイルを作成する
3. **プレフィックスの命名**: 小文字英単語、短く直感的な名前にする（例: `deploy--`, `perf--`, `security--`）
4. **対象ディレクトリ**: `agents/`, `commands/`, `skills/` が対象。`rules/` 自体はこの規則の対象外
