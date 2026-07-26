---
name: meta--skill-catalog
description: .claude/skills/ 配下のスキル一覧をカテゴリ別に要約して表示するスキル
---

# スキルカタログ

`.claude/skills/` に今どんなスキルがあるかを一覧化するスキルです。
「使えるスキルを教えて」「スキル一覧を見せて」と言われたときに使います。

内容は都度スキャンして生成すること。このファイル自体にスキル名を列挙して固定しない
（スキルの追加・削除のたびに手動更新が必要になり、齟齬の温床になるため）。

## 実行手順

1. `.claude/skills/*/SKILL.md` を Glob で列挙する
2. 各ファイルの frontmatter（`name:` / `description:`）を読み取る
3. `.claude/rules/file-naming-convention.md` のプレフィックス一覧に従ってカテゴリ分けする
4. カテゴリ見出し＋スキル名＋説明の一覧をチャットに出力する

## 出力フォーマット

```markdown
## Git/ワークフロー (`git--`)
- **git--branch-summary** — このブランチで起きた変更を解説・要約するスキル
- **git--create-pull-request** — 作業内容からPRの内容を自動作成するスキル

## テスト (`test--`)
- **test--test-case-design** — 包括的で効果的なテストケースを設計・作成するためのスキル
...
```

## 整合性チェック（副次的に実施）

一覧化のついでに以下も検出し、あれば別枠で報告する。

- frontmatter の `name:` とディレクトリ名が不一致
- ディレクトリ名がどのプレフィックスにも属さない（命名規則違反）
- `file-naming-convention.md` のプレフィックス一覧に載っていないプレフィックスが実在する
