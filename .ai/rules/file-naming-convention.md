# .ai/ ファイル命名規則

## 概要

`.ai/` 配下の `skills/` にディレクトリを作成する際は、必ずカテゴリプレフィックスを付与する。

## フォーマット

```
{prefix}--{name}/SKILL.md    # skills/
```

## プレフィックス一覧

| プレフィックス | カテゴリ | 説明 | 例 |
|---|---|---|---|
| `test--` | テスト | TDD, E2E, テストケース設計 | `test--tdd/SKILL.md` |
| `git--` | Git/ワークフロー | ブランチ管理, PR, worktree | `git--branch-summary/SKILL.md` |
| `review--` | レビュー | コードレビュー, PRレビュー | `review--code-review/SKILL.md` |
| `quality--` | コード品質 | リファクタリング | `quality--refactor/SKILL.md` |
| `arch--` | アーキテクチャ | システム設計, 技術選定 | `arch--design-implementation-workflow/SKILL.md` |
| `devenv--` | 開発環境 | devcontainer | `devenv--devcontainer-cli/SKILL.md` |
| `docs--` | ドキュメント | ドキュメント更新 | `docs--update-docs/SKILL.md` |
| `research--` | 調査 | 仕様検索, コード調査 | `research--spec-search/SKILL.md` |
| `spec--` | 要件/仕様 | 要件定義, 仕様レビュー, Backlog連携 | `spec--requirements-workflow/SKILL.md` |
| `debug--` | バグ調査 | 根本原因分析, 再現テスト, 修正提案 | `debug--bug-investigation-workflow/SKILL.md` |
| `team--` | エージェント・チームセッション管理 | 協調編成モード | `team--session/SKILL.md` |
| `format--` | フォーマット変換 | テキスト整形, 記法変換, フォーマット統一 | `format--backlog-notation/SKILL.md` |
| `security--` | セキュリティ | Dependabotアラート対応, 脆弱性スキャン | `security--dependabot-workflow/SKILL.md` |

## ルール

1. **新規ディレクトリ作成時**: 上記プレフィックスの中から適切なものを選び、`{prefix}--{name}` の形式で命名する
2. **該当カテゴリがない場合**: 新しいプレフィックスを定義し、**このルールファイルのプレフィックス一覧テーブルに追記してから**ディレクトリを作成する
3. **プレフィックスの命名**: 小文字英単語、短く直感的な名前にする（例: `deploy--`, `perf--`, `security--`）
4. **対象ディレクトリ**: `skills/` が対象。`rules/` 自体はこの規則の対象外
