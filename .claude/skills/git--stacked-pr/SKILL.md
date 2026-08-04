---
name: git--stacked-pr
description: 依存のある変更を親子ブランチに積んで stacked PR として作成・追従・マージするスキル
---

# Stacked PR

大きな変更を「1 PR = 1 関心事」に割り、依存順に親子ブランチとして積んでレビューに出すためのガイドです。前提ツールは **git と gh のみ**（Graphite などの専用 CLI には依存しない）。

## 使いどころ / 使わない方がよいケース

| 状況 | 判断 |
|---|---|
| 後段の変更が前段のコード（型・関数・マイグレーション）に依存する | **stacked PR 向き** |
| 1つの PR が大きすぎてレビューが止まっている | **stacked PR 向き** |
| 変更同士に依存がない | 並列の独立 PR で十分。積む必要はない |
| 積む段数が5段以上になる | 分割方針を見直す。深いスタックは追従 rebase とコンフリクトの手間が段数に比例して増える（目安は3〜4段） |

## 人間 / AI 役割分担

| 役割 | 担当 |
|------|------|
| **スタック分割方針の承認**: どこで PR を切るか、何段積むか | 人間 |
| **force push の承認**: 追従 rebase 後の force push を実行してよいか（履歴を書き換える破壊的操作） | 人間 |
| **マージ順とマージ方式の決定**: squash / merge commit / rebase merge のどれで親をマージするか | 人間 |
| **CI が落ちたときの続行判断**: 子を先に直すか、親に戻るか | 人間 |
| **分割案の提示**: 変更内容から依存順の分割案を作る | AI |
| **ブランチ作成・push・PR 作成**: 順序を守って実行する | AI |
| **追従 rebase の実行**: 親の変更を子へ伝搬する | AI |
| **スタックの可視化**: 各 PR の親子関係・状態を一覧にする | AI |

---

## 実行手順

### Step 0: 前提チェック

```bash
command -v gh >/dev/null 2>&1 && gh auth status 2>&1 || echo "gh: missing"
git --version
DEFAULT_BRANCH=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#origin/##')
echo "default branch: ${DEFAULT_BRANCH:-<unresolved>}"
```

- `gh` が無い、または未ログイン → 中断し、インストールと `gh auth login` を案内する。
- `git --version` が **2.38 以上なら Step 6 で `--update-refs` が使える**。2.38 未満なら子ごとの `git rebase --onto` を使う。ここで判定した結果を Step 6 で分岐に使う（無条件に `--update-refs` を前提にしない）。
- デフォルトブランチは `origin/HEAD` から解決する。取得できなければユーザーに明示的に確認する（`master` / `main` のハードコードはしない）。

### Step 1: スタック設計

変更を依存順に並べ、**1 PR = 1 関心事**で切る。典型的な切り方:

```
<default>
 └─ 1. feat/schema      … DBスキーマ・型定義の追加（後段が依存する土台）
     └─ 2. feat/api     … 1 に依存する API 実装
         └─ 3. feat/ui  … 2 に依存する画面実装
```

分割案は表で提示し、**実行前にユーザーの承認を取る**。承認された分割をそのままブランチ名とPRタイトルに使う。

### Step 2: ブランチ作成

親から順に積む。子の分岐元は必ず**その親ブランチ**（デフォルトブランチではない）。

```bash
git switch -c feat/schema "origin/${DEFAULT_BRANCH}"
# ... 作業してコミット ...
git switch -c feat/api feat/schema
# ... 作業してコミット ...
git switch -c feat/ui feat/api
```

### Step 3: push（順序が重要）

**親 → 子の順に push する。** 親ブランチがリモートに存在しない状態で `gh pr create --base <親>` を実行すると、base が見つからず失敗する。

1. `git push -u origin feat/schema`
2. `git push -u origin feat/api`
3. `git push -u origin feat/ui`

### Step 4: PR 作成

親から順に、`--base` にその PR の**親ブランチ**を指定する。最下段の親だけがデフォルトブランチを base にする。

```bash
gh pr create --base "$DEFAULT_BRANCH" --head feat/schema --title "..." --body-file ./_local.pr-schema.md
gh pr create --base feat/schema       --head feat/api    --title "..." --body-file ./_local.pr-api.md
gh pr create --base feat/api          --head feat/ui     --title "..." --body-file ./_local.pr-ui.md
```

- PR 本文は `git--create-pull-request` のテンプレートに従って作成する（日本語・AI 署名なし）。
- 本文の**先頭にスタックナビゲーションを貼る**。レビュアーが読む順を間違えないようにするため、全 PR に同じ一覧を入れ、自分の位置を太字にする。

  ```markdown
  ## スタック構成

  1. #101 スキーマ追加
  2. **#102 API 実装 ← このPR**
  3. #103 画面実装

  このPRは #101 に積まれています。先に #101 をご覧ください。
  ```

- 本文を書くファイルは `_local.` prefix にする（`.gitignore` 済みでコミットされない）。

### Step 5: スタックの可視化

現状確認は毎回 gh から取り直す（ローカルの記憶と GitHub 側の base はズレる。特に親マージ後）。

```bash
gh pr list --state open --json number,title,headRefName,baseRefName,state
```

取得した `headRefName` / `baseRefName` から親子関係を組み立て、以下の形で表示する。

```
<default>
 └─ #101 feat/schema  [open]
     └─ #102 feat/api [open]
         └─ #103 feat/ui [open]
```

### Step 6: 親の修正を子へ伝搬

親をレビュー指摘で修正したら、**子を追従させる**。放置すると子 PR の差分に親の変更が混ざり、レビューが読めなくなる。

**1. 各段の現在 tip を控える（rebase の前に必ず）**

```bash
git rev-parse feat/schema feat/api feat/ui   # 例: a1b2c3d ... メモに残す（Step 7 でも使う）
```

rebase 後は元のコミットを名前から辿れなくなる。この値は `git rebase --onto` の「どこから移すか」を指す起点であり、控え忘れると積み直しの復旧が面倒になる。親だけでなく**スタック全段**を控える（2.38 未満の手順では子の旧 tip も要る）。

**2. rebase する**

git 2.38 以上（Step 0 で確認済み）— 最上段で1回実行すれば、途中段の ref もまとめて更新される:

```bash
git switch feat/ui                                        # スタックの最上段
git rebase --update-refs --onto feat/schema <旧schema-tip>
```

`--onto <新しい親> <旧親tip>` の形にする。`git rebase --update-refs feat/schema` のように起点を省くと、**親を amend / squash / `rebase -i` で書き換えていた場合に古い親コミットが子側へ複製される**（書き換え後は patch が一致せず、upstream 済みとみなされないため）。起点を明示する形なら、親に追記した場合も書き換えた場合も同じコマンドで正しく積み直せる。

git 2.38 未満、または段ごとに確認しながら進めたい場合は、下から順に1段ずつ:

```bash
git rebase --onto feat/schema <旧schema-tip> feat/api
git rebase --onto feat/api    <旧api-tip>    feat/ui
```

**3. push する**

- **親（下）から順に** push する。
- **必ず `--force-with-lease` を使う**（`--force` は他者の push を無言で消す）。
- 履歴を書き換える破壊的操作のため、**実行前に人間の承認を取る**。

```bash
# 親自身の履歴も書き換えた（amend / rebase -i）場合は、親も force push が要る
git push --force-with-lease origin feat/schema
git push --force-with-lease origin feat/api
git push --force-with-lease origin feat/ui
```

### Step 7: マージ

**親から順にマージする。** 子を先にマージすることはできない（base が未マージのため）。

親 PR がマージされると、GitHub は子 PR の base を自動で親の base（多くはデフォルトブランチ）へ付け替える。ただし**base の付け替えは子のコミットを書き換えない**。

- **merge commit でマージした場合**: 親のコミットがそのままデフォルトブランチに乗るため、子は追加操作なしで差分が正しく出る。
- **squash merge / rebase merge でマージした場合**: 親のコミットが別のコミットに作り替えられるため、子には「同じ変更の古いコミット」が残り、差分が二重に見える。子を積み直す:

  ```bash
  git fetch origin
  # 上にさらに子がある場合は最上段で --update-refs を付けて一度に積み直す
  git switch feat/ui
  git rebase --update-refs --onto "origin/${DEFAULT_BRANCH}" <旧親tip>
  git push --force-with-lease origin feat/api
  git push --force-with-lease origin feat/ui
  ```

  `<旧親tip>` は Step 6-1 で控えた値（＝マージ直前の親ブランチ先端）。控えていない場合は `gh pr view <親PR番号> --json headRefOid -q .headRefOid` で取得できる。

マージ方式はリポジトリの設定と人間の判断による。**squash 運用のリポジトリでは、親をマージするたびにこの積み直しが必要**になる前提で進める。

### Step 8: 後始末

```bash
git switch "$DEFAULT_BRANCH" && git pull origin "$DEFAULT_BRANCH"
git fetch --prune
git branch -d feat/schema    # マージ済みのみ削除（-D は使わない）
```

- worktree で各段を別ディレクトリに置いている場合は `git--git-worktree` を参照して片付ける。
- ブランチ削除は `-d`（マージ済みのみ）に留める。`-D` での強制削除は未マージの変更を失う。

---

## トラブルシュート

| 症状 | 対処 |
|---|---|
| 子 PR の差分に親の変更が混ざっている | 親を修正したまま子を追従させていない。Step 6 を実行する |
| 親マージ後、子 PR の差分が二重に見える | squash / rebase merge で親の履歴が変わった。Step 7 の積み直しを実行する |
| `gh pr create --base` が base 不明で失敗する | 親ブランチが未 push。Step 3 の順序（親→子）に戻る |
| rebase 中にコンフリクトした | 各段で解消して `git rebase --continue`。段数が多く手に負えなければ `git rebase --abort` で戻し、分割方針の見直しをユーザーに相談する |
| 子 PR の CI が親の未マージ機能を参照して落ちる | 子単体では落ちて当然のケースがある。落ちた理由が「親待ち」かどうかを切り分け、PR 本文に明記してレビュアーに伝える |
| `--force-with-lease` が拒否される | リモートが自分の知らないコミットで進んでいる。`git fetch` して差分を確認してから再実行する（`--force` での上書きはしない） |

## 重要な制約

- デフォルトブランチ名をハードコードしない。`origin/HEAD` から解決し、取れなければユーザーに確認する。
- force push は必ず `--force-with-lease`、かつ**実行前に人間の承認を取る**。
- スタックは浅く保つ（目安3〜4段）。
- コミットメッセージは `.claude/rules/commit-convention.md` に従う。
- PR 本文に AI 署名は付けない（`git--create-pull-request` と同じ規約）。

## 関連スキル

| スキル | 用途 |
|--------|------|
| `git--create-pull-request` | 各 PR の本文テンプレートと作成手順 |
| `git--git-worktree` | スタックの各段を別ディレクトリで並行して扱う |
| `git--branch-summary` | 各段のブランチで起きた変更を要約し、PR 本文の材料にする |
