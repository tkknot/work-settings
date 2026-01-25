---
description: git worktreeでブランチを別ディレクトリにチェックアウト（作成/一覧/削除/切り替え）
model: inherit
subtask: true
---

# Git Worktree Command

インタラクティブにgit worktreeを管理するコマンド。

## 実行手順

### Phase 1: 現状確認と操作選択

1. 現在のworktree一覧を表示

```bash
git worktree list
```

2. ユーザーに操作を選択させる

- **新規作成**: 新しいworktreeを作成
- **一覧表示**: 詳細情報付きでworktree一覧を表示
- **切り替え**: 指定したworktreeのディレクトリに移動（パスを表示）
- **削除**: 指定したworktreeを削除
- **プルーン**: 不要なworktree参照をクリーンアップ

---

### Phase 2A: 新規作成

1. ブランチの種類を確認

- **既存ブランチ**: リモートまたはローカルの既存ブランチをチェックアウト
- **新規ブランチ**: 新しいブランチを作成してチェックアウト

2. ブランチ名を取得

- 既存ブランチの場合: `git branch -a` で一覧を表示して選択させる
- 新規ブランチの場合: ユーザーにブランチ名を入力させる

3. worktreeのディレクトリパスを決定

- デフォルト: `../{ブランチ名}`（スラッシュはハイフンに置換）
- 例: `feature/login` → `../feature-login`
- ユーザーが別のパスを希望する場合は変更可能

4. worktreeを作成

```bash
# 既存ブランチの場合
git worktree add <path> <branch>

# 新規ブランチの場合
git worktree add -b <new-branch> <path> [<start-point>]
```

5. 作成完了メッセージとディレクトリパスを表示

---

### Phase 2B: 一覧表示

1. 詳細情報付きでworktree一覧を表示

```bash
git worktree list --porcelain
```

2. 各worktreeについて以下を整形して表示
   - パス
   - HEAD コミット
   - ブランチ名
   - ロック状態

---

### Phase 2C: 切り替え（情報表示）

1. worktree一覧から選択させる
2. 選択したworktreeのディレクトリパスを表示
3. `cd <path>` コマンドを提示（シェルの制約上、直接cdはできない）

---

### Phase 2D: 削除

1. worktree一覧から削除対象を選択させる
2. **メインのworktreeは削除不可**であることを確認
3. 削除前に確認を求める

```bash
# 通常の削除
git worktree remove <path>

# 変更がある場合は強制削除の確認
git worktree remove --force <path>
```

4. 削除完了メッセージを表示

---

### Phase 2E: プルーン

1. プルーンの説明を表示
   - 手動で削除されたworktreeディレクトリの参照をクリーンアップ

```bash
# ドライラン（確認）
git worktree prune --dry-run

# 実行
git worktree prune
```

---

## 重要な制約

- **メインのworktree（.git がある元のディレクトリ）は削除不可**
- worktreeのパスは**リポジトリ外**に作成することを推奨
- 同じブランチを複数のworktreeでチェックアウトすることは**不可**
- 操作前に必ず現在のworktree一覧を確認する
- エラーが発生した場合はユーザーに状況を説明して対処法を提案
