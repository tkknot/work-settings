---
description: このブランチで起きた変更を解説・要約
model: inherit
subtask: true
---

# Branch Summary Command

## 概要

現在チェックアウトしているブランチで行われた変更を自動で取得し、何が起きたかを分かりやすく解説します。

---

## 実行フロー

### Phase 1: 情報収集

1. 現在のブランチ名を取得

```bash
git branch --show-current
```

2. リモートのデフォルトブランチを取得

```bash
git remote show origin | grep "HEAD branch" | sed 's/.*: //'
```

3. リモートを最新化

```bash
git fetch origin
```

### Phase 2: 変更内容の取得

1. デフォルトブランチからの**コミット一覧**を取得

```bash
PAGER=cat git log --oneline origin/<default-branch>..HEAD
```

2. **変更されたファイル一覧**を取得

```bash
git diff --name-status origin/<default-branch>...HEAD
```

3. **差分の統計情報**を取得

```bash
git diff --stat origin/<default-branch>...HEAD
```

4. **詳細な差分**を取得

```bash
PAGER=cat git diff origin/<default-branch>...HEAD
```

### Phase 3: PR情報の取得（存在する場合）

1. PRが存在するか確認

```bash
gh pr view --json number,title,state,body 2>/dev/null
```

2. PRが存在する場合は以下も取得
   - PRのタイトル・説明
   - レビュワー・レビュー状態
   - CI/CDの状態

```bash
PAGER=cat gh pr checks
```

### Phase 4: 解説の生成

取得した情報をもとに、以下の形式で**日本語で**要約する：

---

## 📋 ブランチサマリー: `<branch-name>`

### 🎯 目的
このブランチで達成しようとしていることの要約

### 📝 変更内容
1. **コミット1のタイトル** (`abc1234`)
   - 何をしたか
   - なぜそうしたか（推測可能な場合）

2. **コミット2のタイトル** (`def5678`)
   - 何をしたか

### 📁 変更されたファイル
| ファイル | 変更種別 | 概要 |
|---------|---------|------|
| `path/to/file.ts` | 追加 | 新規機能の実装 |
| `path/to/other.ts` | 変更 | リファクタリング |

### 🔍 主な変更ポイント
- 重要な変更点1
- 重要な変更点2

### ⚠️ 注意点・懸念事項（あれば）
- 破壊的変更
- 要確認箇所

---

## 注意事項

- `gh` CLIがインストールされていなくても、gitコマンドのみで動作可能
- PR情報は`gh`が利用可能な場合のみ取得
- デフォルトブランチは動的に取得するため `main` / `master` / `develop` 等いずれでも対応可能

## gh CLI が存在しない場合

- `which gh` の結果が空の場合は、PR関連の情報取得をスキップ
- gitコマンドのみで差分とコミットログを取得して要約
