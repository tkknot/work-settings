---
name: git--stacked-pr
description: gh stack 拡張で依存のある変更を階層ブランチに積み、stacked PR として作成・追従・マージするスキル
---

# Stacked PR (`gh stack`)

大きな変更を「1 PR = 1 関心事」に割り、依存順に積んでレビューに出すためのガイド。GitHub 公式の CLI 拡張
[`github/gh-stack`](https://github.com/github/gh-stack) を使う。スタックのローカル追跡・カスケード rebase・
PR の base 付け替え・スタック単位のマージは拡張が担当するため、素の `git rebase --onto` は使わない。

スタックは `(main) <- feat/schema <- feat/api` の向きで表示される。左が**下段**（先にマージ）、右が**上段**。
`up` は上段へ、`down` は trunk へ向かう。

## 使いどころ / 使わない方がよいケース

| 状況 | 判断 |
|---|---|
| 後段の変更が前段のコード（型・関数・マイグレーション）に依存する | **stacked PR 向き** |
| 1つの PR が大きすぎてレビューが止まっている | **stacked PR 向き** |
| 変更同士に依存がない | 並列の独立 PR で十分。積む必要はない |
| 積む段数が5段以上になる | 分割方針を見直す。目安は3〜4段 |

## 人間 / AI 役割分担

| 役割 | 担当 |
|------|------|
| **スタック分割方針の承認**: どこで PR を切るか、何段積むか | 人間 |
| **`git config` 変更の承認**: 下記セットアップはユーザーの git 設定を書き換える | 人間 |
| **`submit` / `push` / `sync` / `merge` の実行承認**: いずれも push・force push・マージを内包する | 人間 |
| **マージ方式の決定**: squash / merge commit / rebase merge | 人間 |
| **CI が落ちたときの続行判断**: 上段を先に直すか、下段に戻るか | 人間 |
| **分割案の提示**: 変更内容から依存順の分割案を作る | AI |
| **`gh stack` コマンドの実行**: 非対話フラグを守って実行する | AI |
| **PR 本文の日本語テンプレ差し替え**: 自動生成本文を規約どおりに書き直す | AI |
| **スタックの可視化**: `view --json` から親子関係・状態を一覧にする | AI |

---

## セットアップ

```bash
gh --version                            # 2.0 以上が必要
gh extension install github/gh-stack
git config rerere.enabled true          # コンフリクト解決を再利用する
git config remote.pushDefault origin    # remote が複数ある場合は必須
```

- `git config` の2行は**ユーザーの設定を書き換える**ため、実行前に確認を取る。
- stacked PR はパブリックプレビュー機能。**リポジトリで有効化されていないと exit 9** になる。その場合は
  「`gh stack` が使えないとき」へ。
- `gh` が無い / 未ログインなら中断し、インストールと `gh auth login` を案内する。

## 非対話実行の作法

`gh stack` は **stdout が TTY かどうか**で挙動を変える。素で叩くと TUI が開いて固まるため、必ず下記の形で
実行する。

| 必ずこう叩く | 素で叩かない | 理由 |
|---|---|---|
| `gh stack view --json` | `gh stack view` | TUI が開く |
| `gh stack submit --auto --open` | `gh stack submit` | PR ごとにタイトルを聞かれる |
| `gh stack init <branch>...` / `gh stack add <branch>` | 引数なし | ブランチ名を聞かれる |
| `gh stack checkout <target>` | `gh stack checkout` | 選択メニューが開く |
| `gh stack up` / `down` / `top` / `bottom` | `gh stack switch` | `switch` はメニュー専用 |
| `gh stack merge <target> --yes` | `gh pr merge` | `gh pr merge` はスタックをマージできない |
| （代替: `unstack` → `init`） | `gh stack modify` | TUI 専用で非対話手段が無い |

- `--json` は **stdout** に出る。stderr は状態メッセージなのでパースしない（→ exit code で分岐する）。
- remote が複数ある場合、`remote.pushDefault` 未設定なら `push` / `submit` / `sync` / `rebase` / `link` に
  `--remote <name>` を付ける。`checkout` / `trunk` には `--remote` が無いので config が必須。

## 実行手順

### Step 1: スタック設計

変更を依存順に並べ、**1 PR = 1 関心事**で切る。**実装を書き始める前に**スタックを作る（trunk に全部書いて
後から割るのは避ける）。分割案は表で提示し、実行前にユーザーの承認を取る。

| 段 | ブランチ | 関心事 |
|---|---|---|
| 1（下段） | `feat/schema` | DBスキーマ・型定義（後段が依存する土台） |
| 2 | `feat/api` | schema に依存する API 実装 |
| 3（上段） | `feat/ui` | api に依存する画面実装 |

### Step 2: スタック作成とコミット

```bash
gh stack init feat/schema          # スタック作成 + そのブランチへ checkout
git add … && git commit            # コミット規約に従う（下記注意）
gh stack add feat/api              # 次の層。現在のブランチから分岐する
git add … && git commit
gh stack add feat/ui
git add … && git commit
```

- ブランチ名はそのまま使われる（`gh stack add refactor/foo` → `refactor/foo`）。
- **`gh stack add -Am "MSG"` は既定にしない。** 一行 `-m` では `.claude/rules/commit-convention.md` の
  `Co-Authored-By` フッターを載せられないため。`add <branch>` + 通常の `git commit` を使う。
  `-Am` は署名不要な些末な雑務に限る。

### Step 3: push と PR 作成

```bash
gh stack submit --auto --open      # ← 承認ゲート: 全ブランチを push し PR とスタックを作る
```

- `--auto` はタイトル自動生成（対話プロンプトを回避）、`--open` は**レビュー可**での作成（無しだと draft）。
- push を伴う破壊的操作のため、**実行前に人間の承認を取る**。

### Step 4: PR 本文を規約どおりに直す

`submit` が生成するタイトル・本文は自動生成で、本リポジトリの規約に合わない。**各層の PR を上書きする。**

```bash
gh stack view --json               # .branches[].pr.number から PR 番号を取得
gh pr edit <番号> --title "…" --body-file ./_local.pr-schema.md
```

- 本文は `git--create-pull-request` のテンプレート（日本語・「やったこと」に各コミットハッシュ・**AI 署名なし**）。
- 本文ファイルは `_local.` prefix にする（`.gitignore` 済みでコミットされない）。
- **スタックナビゲーションを本文に手書きしない。** GitHub が merge box にスタックマップ（全 PR と状態・
  各層へのリンク）を自動描画するため、本文に一覧を貼ると二重管理になる。レビュー順に関する補足が要る
  場合だけ「その他」セクションに1行書く。

### Step 5: スタックの可視化

状態は毎回 `gh stack view --json` から取り直す（ローカルの記憶と GitHub 側はズレる）。

```
trunk           string   ← デフォルトブランチ名はここから取る（ハードコードしない）
currentBranch   string
branches[]      name, head, base, isCurrent, isMerged, isQueued, needsRebase
branches[].pr   number, url, state ("OPEN" | "MERGED" | "QUEUED")  ※PR未作成なら無い
```

`needsRebase` が true の層は親の先端を取り込めていない。Step 6 で積み直す。

### Step 6: 下段の修正を上段へ伝搬

レビュー指摘は**その関心事を持つ層で直す**。上段のブランチに下段の修正をコミットしない。

```bash
gh stack down                      # または gh stack checkout feat/schema
git add … && git commit
gh stack rebase --upstack          # 上の全層を積み直す
gh stack top                       # 元の位置に戻る
gh stack push                      # ← 承認ゲート: force push を内包する
```

- どの層が持つ変更か不明なときは `git log --all -- <path>` で持ち主を特定する。
- `gh stack rebase` は `--downstack` / `--upstack` / `--no-trunk` で範囲を絞れる。

### Step 7: 追従とマージ

```bash
gh stack sync                      # ← 承認ゲート: fetch → rebase → push → PR状態同期
gh stack sync --prune              # マージ済み PR のローカルブランチも削除する
```

- 下段が squash merge された後も `sync` が積み直す。**旧スキルにあった手動の積み直しは不要**。
- `sync` がローカルとリモートの乖離を検出した場合、両方の連なりを表示して**何も変更せず** `Sync aborted`
  と出して exit 0 で終わる。0 だから成功、と解釈しない。

```bash
gh stack merge 102 --yes --squash  # ← 承認ゲート
```

- PR 番号を渡すと**その PR とそれより下の未マージ PR すべて**、スタック番号を渡すとそのスタックの
  未マージ PR すべてが対象。**all-or-nothing**（1つでもマージできなければ全部マージされない）。
- 方式は `--squash` / `--merge` / `--rebase` / `--merge-method <method>`。**無指定だと前回の方式が再利用**
  されるため、明示するか人間に確認する。
- base にマージキューがある場合はキューに積まれ、方式フラグは警告付きで無視される。

### Step 8: 後始末

マージ後は `gh stack sync --prune` でローカルブランチを片付ける。ローカル追跡だけ解除したい場合は
`gh stack unstack --local`（GitHub 側のスタックは残る）。worktree を使っている場合は
`git--git-worktree` を参照する。

---

## exit code と対処

stderr をパースせず、**exit code で分岐する**。

| code | 意味 | 対処 |
|---|---|---|
| 2 | スタックに居ない | `gh stack init` または `gh stack checkout <target>` |
| 3 | rebase コンフリクト | 解消 → `git add` → `gh stack rebase --continue`（戻すなら `--abort`）。`sync` で出た場合はスタックが復元済みなので、`gh stack rebase` で再現してから解消する |
| 4 | GitHub API 失敗 | `gh auth status` を確認して再実行 |
| 6 | 曖昧（複数スタックに属するブランチ） | 共有していないブランチへ checkout する |
| 7 | rebase 実行中 | `gh stack rebase --continue` / `--abort` |
| 8 | スタックファイルがロック中 | 他プロセスが書き込み中。5秒ほど待って再実行 |
| 9 | stacked PR がリポジトリで無効 | 機能が未有効。ユーザーに伝え、下記フォールバックへ |
| 10 | modify の復旧待ち | `gh stack modify --abort` |

- `checkout <pr>` が既存ローカルスタックと衝突する場合は強制できない。`gh stack unstack --local`（GitHub 側は
  残る）してから再実行する。
- 上段 PR の CI が下段の未マージ機能を参照して落ちるのは、単体では当然のケースがある。「下段待ち」かを
  切り分け、PR 本文に明記してレビュアーに伝える。
- コンフリクトが手に負えないほど深いなら `--abort` で戻し、分割方針の見直しをユーザーに相談する。

## `gh stack` が使えないとき

拡張が入っていない、または exit 9（リポジトリで未有効）の場合は、git と gh だけで最小構成を組む。

```bash
git switch -c feat/api feat/schema             # 分岐元は必ず親ブランチ
git push -u origin feat/schema                 # 親 → 子の順に push（順序が重要）
git push -u origin feat/api
gh pr create --base feat/schema --head feat/api --title "…" --body-file ./_local.pr-api.md
```

- 親を直したら子を追従させる: `git rebase --onto feat/schema <親の旧tip> feat/api` → 親から順に
  `git push --force-with-lease`（**`--force` は使わない。実行前に人間の承認を取る**）。
- 親を squash merge した場合、子には同じ変更の古いコミットが残るので `origin/<trunk>` へ積み直す。

## 重要な制約

- スタックは厳密に線形（親1・子1まで）。並行作業は別スタックにする。段数は3〜4段が目安。
- 非対話での並べ替え・削除手段は無い。エラーが `gh stack modify` を勧めても TUI 専用なので、
  `unstack` → `init` で組み直す。
- デフォルトブランチ名をハードコードしない（`gh stack view --json` の `.trunk` から取る）。
- `submit` / `push` / `sync` / `merge` は実行前に人間の承認を取る。
- コミットメッセージは `.claude/rules/commit-convention.md`、PR 本文は日本語・AI 署名なしで
  `git--create-pull-request` の規約に従う。
- フラグの正は `gh stack <command> --help`（`gh stack help <command>` は効かない）。

## 関連スキル

| スキル | 用途 |
|--------|------|
| `git--create-pull-request` | 各 PR の本文テンプレートと作成手順 |
| `git--git-worktree` | スタックの各段を別ディレクトリで並行して扱う |
| `git--branch-summary` | 各段のブランチで起きた変更を要約し、PR 本文の材料にする |
