# .ai/ ファイル命名規則

## 概要

`.ai/` 配下の `commands/`, `skills/` にファイルやディレクトリを作成する際は、必ずカテゴリプレフィックスを付与する。

## フォーマット

```
{prefix}--{name}.md          # commands/
{prefix}--{name}/SKILL.md    # skills/
```

## プレフィックス一覧

| プレフィックス | カテゴリ | 説明 | 例 |
|---|---|---|---|
| `test--` | テスト | TDD, E2E, テストケース設計 | `test--tdd-command.md` |
| `git--` | Git/ワークフロー | ブランチ管理, PR, worktree | `git--branch-summary-command.md` |
| `review--` | レビュー | コードレビュー, PRレビュー | `review--pr-review-command.md` |
| `quality--` | コード品質 | リファクタリング | `quality--refactor-command.md` |
| `arch--` | アーキテクチャ | システム設計, 技術選定 | `arch--architect-command.md` |
| `devenv--` | 開発環境 | devcontainer | `devenv--devcontainer-launch-command.md` |
| `docs--` | ドキュメント | ドキュメント更新 | `docs--update-docs-command.md` |
| `research--` | 調査 | 仕様検索, コード調査 | `research--spec-search-command.md` |
| `spec--` | 要件/仕様 | 要件定義, 仕様レビュー, Backlog連携 | `spec--requirements-review-command.md` |
| `debug--` | バグ調査 | 根本原因分析, 再現テスト, 修正提案 | `debug--bug-investigation-command.md` |
| `team--` | エージェント・チームセッション管理 | 協調編成モード | `team--session-command.md` |
| `format--` | フォーマット変換 | テキスト整形, 記法変換, フォーマット統一 | `format--backlog-notation-command.md` |
| `security--` | セキュリティ | Dependabotアラート対応, 脆弱性スキャン | `security--dependabot-fix-command.md` |

## ルール

1. **新規ファイル作成時**: 上記プレフィックスの中から適切なものを選び、`{prefix}--{name}` の形式で命名する
2. **該当カテゴリがない場合**: 新しいプレフィックスを定義し、**このルールファイルのプレフィックス一覧テーブルに追記してから**ファイルを作成する
3. **プレフィックスの命名**: 小文字英単語、短く直感的な名前にする（例: `deploy--`, `perf--`, `security--`）
4. **対象ディレクトリ**: `commands/`, `skills/` が対象。`rules/` 自体はこの規則の対象外
