# .claude/ ファイル命名規則

`.claude/skills/` 配下にディレクトリを作成する際は、必ずカテゴリプレフィックスを付与する（`rules/` は対象外）。

```
{prefix}--{name}/SKILL.md
```

## プレフィックス一覧

| プレフィックス | カテゴリ | 説明 | 例 |
|---|---|---|---|
| `test--` | テスト | TDD, E2E, テストケース設計 | `test--test-case-design/SKILL.md` |
| `git--` | Git/ワークフロー | ブランチ管理, PR, worktree | `git--branch-summary/SKILL.md` |
| `arch--` | アーキテクチャ | システム設計, 技術選定 | `arch--design-implementation-workflow/SKILL.md` |
| `devenv--` | 開発環境 | devcontainer | `devenv--devcontainer-cli/SKILL.md` |
| `docs--` | ドキュメント | ドキュメント更新 | `docs--{name}/SKILL.md` |
| `research--` | 調査 | 仕様検索, コード調査 | `research--{name}/SKILL.md` |
| `spec--` | 要件/仕様 | 要件定義, 仕様レビュー, Backlog連携 | `spec--requirements-workflow/SKILL.md` |
| `debug--` | バグ調査 | 根本原因分析, 再現テスト, 修正提案 | `debug--bug-investigation-workflow/SKILL.md` |
| `team--` | エージェント・チームセッション管理 | 協調編成モード | `team--session/SKILL.md` |
| `format--` | フォーマット変換 | テキスト整形, 記法変換, フォーマット統一 | `format--backlog-notation/SKILL.md` |
| `security--` | セキュリティ | Dependabotアラート対応, 脆弱性スキャン | `security--dependabot-workflow/SKILL.md` |
| `check--` | 事前チェック | 機能撤去・文言影響範囲チェック, PR前チェック | `check--removal-impact/SKILL.md` |
| `review--` | レビュー | クロスレビュー, レビュー自動化, 反復レビュー | `review--cross-review/SKILL.md` |
| `meta--` | エージェント設定自体 | スキル一覧・カタログ化など `.claude/` 自身を対象とした操作 | `meta--skill-catalog/SKILL.md` |

## ルール

1. 上記プレフィックスから適切なものを選び `{prefix}--{name}` 形式で命名する
2. 該当カテゴリがない場合は新しいプレフィックスを定義し、**上表に追記してから**ディレクトリを作成する（小文字英単語、短く直感的に）
