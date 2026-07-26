---
name: review--cross-review
description: codex と pr-review-toolkit を交互に走らせ、指摘が枯れるまで反復クロスレビューするスキル
---

# クロスレビュー（codex × pr-review-toolkit）

OpenAI Codex と Claude の `pr-review-toolkit` プラグインを交互にぶつけ、片方が見落とした指摘をもう片方が拾う反復レビューを行うガイドです。

**重量級ワークフロー**: 1ラウンドで codex 1回 + サブエージェント最大6体を消費します。3ラウンドまわすと codex 3回・サブエージェント最大18体になり、決して安くありません。小さな差分には単発の `/pr-review-toolkit:review-pr` で十分です。差分が大きい・複数モジュールにまたがる・レビュー品質を特に上げたい場合に使ってください。

## 人間 / AI 役割分担

| 役割 | 担当 |
|------|------|
| **タイブレークの最終判断**: codex と pr-review-toolkit の指摘が対立し規約でも決着しない場合の採否 | 人間 |
| **見送りリストの採否**: Suggestion や `code-simplifier` の提案を採用するか | 人間 |
| **`codex login` の実施**: 未ログイン環境でのセットアップ | 人間 |
| **レビューの実行と修正の適用**: codex・pr-review-toolkit を起動し、Critical/Important を反映する | AI |
| **収束判定**: seen-set・ラウンド上限に基づきループを継続/終了する | AI |
| **見送りリストの整理**: 見送り理由・エスカレーション理由を記録する | AI |

---

## 実行手順

### Step 1: プリフライト（ゲート）

以下の両方が揃わなければ**中断**する。片肺運転はしない。

```bash
command -v codex >/dev/null 2>&1 && echo "codex: installed" || echo "codex: missing"
codex login status 2>&1
```

- `codex` が存在しない、または `codex login status` の**出力テキストに `Not logged in` が含まれる** → 中断し、`codex login` の実行を案内して終了する。
  - 終了コードでの判定はしない。未ログイン時の終了コードは未確認のため、出力テキストでの判定の方が頑健。
- `pr-review-toolkit` プラグインが有効でない（`.claude/settings.json` の `enabledPlugins` を確認、または `/plugin` で確認） → 中断し、有効化を案内して終了する。

両方揃って初めて Step 2 に進む。

### Step 2: レビュー対象の固定

ベースコミットだけを開始時に1回固定し、以降のラウンドでは再計算しない。先端（作業ツリー）は毎回浮かせて見る。

```bash
DEFAULT_BRANCH=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#origin/##')
# 取得できなければユーザーに明示的に確認する（master/main のハードコードはしない）
BASE=$(git merge-base HEAD "origin/${DEFAULT_BRANCH}")
```

毎ラウンド、この `BASE` を使って**2ドット diff**（`BASE...HEAD` ではなく `BASE` から作業ツリーまで）で差分を取る:

```bash
git diff "$BASE" --name-only
```

3ドット（`BASE...HEAD`）を使うと、直前ラウンドで加えた未コミットの修正が次ラウンドの差分に含まれず、同じ指摘が無限に再燃する。必ず2ドットにすること。

見送りリスト・seen-set（fixed/declined の2集合）・ラウンドカウンタを初期化する。

### Step 3: 1ラウンドの実行

**Phase A — codex レビュー**

プロンプトはスクラッチパッドにファイルとして書き出し、stdin 経由で渡す（長い日本語プロンプトを引数にするとクォートが崩れる）。

```bash
codex exec -s read-only -C "$PWD" -o "$OUT/codex-round-N.md" - < "$OUT/codex-prompt-N.md"
```

- `-s read-only` を必ず指定する。codex にファイルを書かせない（修正の適用者は Claude のみ）。
- codex は `CLAUDE.md` を読まない（読むのは `AGENTS.md`）。プロンプトには **`CLAUDE.md` と `.claude/rules/*.md` の内容をインラインで埋め込む**か明示的にパスを渡し、規約違反の空振り指摘を減らす。
- レビュー対象は Step 2 の `git diff "$BASE"` の範囲に限定する。
- 出力フォーマットを固定で指示する（後続の重複排除・終了判定を機械的に行うため）:

  ```
  ### [Critical|Important|Suggestion] <path>:<line>
  - 指摘: <一文>
  - 根拠: <なぜ問題か>
  - 提案: <どう直すか>
  ```

**Phase A' — 反映**

Critical / Important のみ Claude が修正する。Suggestion は見送りリストへ（この時点では修正しない）。

**Phase B — pr-review-toolkit レビュー**

`/pr-review-toolkit:review-pr` はスラッシュコマンドでありスキルからプログラム的に起動できないため、Agent ツールで各エージェントを直接起動する。差分内容に応じて出し分け、並列起動してよい。

| 条件 | 起動するエージェント |
|---|---|
| 常時 | `pr-review-toolkit:code-reviewer` |
| エラー処理/catch の変更あり | `pr-review-toolkit:silent-failure-hunter` |
| テストファイルの変更あり | `pr-review-toolkit:pr-test-analyzer` |
| コメント/docs の追加あり | `pr-review-toolkit:comment-analyzer` |
| 型の追加/変更あり | `pr-review-toolkit:type-design-analyzer` |
| 最終ラウンドのみ | `pr-review-toolkit:code-simplifier`（**報告のみ・自動適用しない**） |

各エージェントには Step 2 の `BASE` を明示し、レビュー対象をそのラウンドの差分に限定する。ユーザーがこのスキルを起動したこと自体が、上記サブエージェントを起動する許可とみなす。

`code-simplifier` の提案は最後の変更が誰にもレビューされない状態を避けるため、自動適用せず見送りリストに載せて人間の判断に委ねる。

**Phase B' — 反映**

同様に Critical / Important のみ Claude が修正する。

### Step 4: 収束判定

各ラウンドの終わりに以下を行う。

1. **重大度フロア**: ループ継続の判定材料は Critical / Important のみ。Suggestion はカウントに入れない。
2. **seen-set は2種類に分ける**（同一集合にしない）:

   | 種別 | 次ラウンドでの扱い |
   |---|---|
   | 見送り (declined) | 恒久的に抑制。二度と再掲しない |
   | 修正済み (fixed) | 再掲を許可する。**2度目の再掲で修正を諦め**、理由付きで見送りリストにエスカレーションする |

   直した指摘が再掲されるのは「修正が不完全だった」という有効なシグナル。fixed と declined を混ぜて抑制すると、実際にはバグが残ったまま「指摘なし」と偽の収束報告をしてしまう。
3. **オシレーション対策**: codex と pr-review-toolkit の指摘が矛盾する場合（例: 「抽出しろ」vs「インライン化しろ」）、①プロジェクトの `CLAUDE.md` / `.claude/rules/*.md` に合致する方を採用する。②それでも決着しなければコードは変更せず、見送りリストに載せて人間の判断を仰ぐ。
4. **終了条件**（いずれかを満たしたら Step 5 へ）:
   - そのラウンドで新規の Critical / Important がゼロだった（収束）
   - ラウンド数が上限（デフォルト3、スキル引数で変更可）に達した（打ち切り）

達していなければ Step 3 に戻る。

### Step 5: 出力

以下を含む最終レポートを提示する。

- ラウンドごとの指摘数推移（Critical / Important / Suggestion）
- 修正した指摘の一覧（file:line 付き）
- 見送りリスト（Suggestion・タイブレーク未決・`code-simplifier` 提案・fixed の2回目再掲エスカレーションを理由付きで列挙）
- 収束して終わったか、上限で打ち切ったか

---

## 重要な制約

- codex コマンドのフラグは `codex exec --help`（codex-cli 0.53.0）で存在を確認できたものに限定する（`-s`/`-C`/`-o`/`--json`/`--output-schema`/`-m`/`--skip-git-repo-check`）。モデルは `-m` で固定せずデフォルトに任せる。
- `codex apply` は使わない。修正の書き手は常に Claude のみ（単一ライター原則）。
- `origin/master` のようなブランチ名のハードコードはしない。`origin/HEAD` から解決できない場合はユーザーに確認する。

## 関連スキル

| スキル / プラグイン | 用途 |
|--------|------|
| `arch--design-implementation-workflow` | 設計・実装フローの中の単発レビュー（本スキルは反復クロスレビュー） |
| `/pr-review-toolkit:review-pr`（プラグイン） | 単発の PR レビュー。小さな差分はこちらで十分 |
| `pr-review-toolkit:code-simplifier`（プラグインのエージェント） | 最終ラウンドの整理提案（自動適用はしない） |
