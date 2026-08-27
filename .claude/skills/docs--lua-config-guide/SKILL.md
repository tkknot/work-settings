---
name: docs--lua-config-guide
description: 配布済みの nvim / wezterm の Lua 設定を読み解いて日本語で解説するスキル
argument-hint: "[nvim|wezterm|ファイルパス]"
---

# Lua 設定の解説

自分で書いた nvim / wezterm の Lua 設定が「何をしているのか」「なぜそう書いてあるのか」を
読み解いて日本語で解説するスキルです。久しぶりに触るとき、キーバインドを忘れたとき、
他人に説明するとき、設定を壊さずに手を入れたいときに使います。

## 対象は必ず「配布先」を見る

このスキルは `work-settings` から各リポジトリへ配布されるため、**実行先のリポジトリに
`nvim/` や `wezterm/` のソースが存在するとは限りません**。解説の対象は常に、
`sync_editor.sh` が実際に配布したパス（＝いま動いている設定そのもの）とします。

| 対象 | 配布先 |
|---|---|
| nvim | `$HOME/.config/nvim/` |
| wezterm | `$HOME/.config/wezterm/` |
| wezterm（WSL のみ・Windows 側） | `/mnt/c/Users/<user>/.config/wezterm/` と `/mnt/c/Users/<user>/.wezterm.lua` |

リポジトリ相対の `nvim/` `wezterm/` を最初から読みにいかないこと。あれはソースであって、
実際に読み込まれている設定とはズレている可能性がある（Phase 4 で扱う）。

---

## 実行フロー

### Phase 1: 配布先の解決

存在する配布先だけを列挙する。Windows ユーザー名はハードコードせず走査で見つける。

```bash
for p in "$HOME/.config/nvim" "$HOME/.config/wezterm"; do
  [ -d "$p" ] && echo "DIR  $p"
done
if grep -qi microsoft /proc/version 2>/dev/null; then
  for u in /mnt/c/Users/*/; do
    [ -d "$u.config/wezterm" ] && echo "DIR  ${u}.config/wezterm"
    [ -f "$u.wezterm.lua" ] && echo "FILE ${u}.wezterm.lua"
  done
fi
```

- **1つも見つからない場合**は、設定がまだ配布されていない。ユーザーにそう伝え、
  カレントリポジトリが `work-settings`（`sync_editor.sh` がある）なら `./sync_editor.sh` の
  実行を提案する。ソースを勝手に読んで代用しない。
- WSL では Linux 側と Windows 側の 2 か所に同じ内容が配布される。**解説は Linux 側
  （`$HOME/.config/wezterm`）を正とし**、Windows 側は Phase 4 の差分チェックにのみ使う。

### Phase 2: 解説対象の絞り込み

引数 `$ARGUMENTS` で対象を決める。

| 引数 | 対象 |
|---|---|
| `wezterm` | `$HOME/.config/wezterm/wezterm.lua` |
| `nvim` | nvim の設定一式（下記の順で読む） |
| ファイルパス | そのファイル1つ |
| 引数なし | 配布先の `*.lua` を列挙して提示し、どれを解説するかユーザーに確認する |

全ファイルを無条件に読み込まない。nvim は LazyVim 構成でファイル数が多いため、
引数が `nvim` の場合は次の順で読み、プラグイン定義は「何を入れているか」の粒度に留める。

1. `init.lua` → `lua/config/lazy.lua`（ブートストラップと読み込み順）
2. `lua/config/options.lua` / `keymaps.lua` / `autocmds.lua`（自分で書いた設定の本体）
3. `lua/plugins/*.lua`（各プラグインの spec）
4. `lazyvim.json` / `.neoconf.json` / `stylua.toml`（有効な extras・整形規約）

### Phase 3: 解説の生成

読んだ内容から、**日本語で**以下を出力する。コードをそのまま貼り直すのではなく、
「何のために」「どう動くか」「触るとどこが壊れるか」を書く。

````markdown
## 🧩 <対象名> の設定解説

**読んだファイル**: `~/.config/wezterm/wezterm.lua`（<行数> 行）

### 全体像
このファイルが何を担当しているか、どういう順で処理が走るかを 3〜5 行で。

### ⌨️ キーバインド
| キー | 動作 | 備考 |
|---|---|---|
| `Ctrl+Shift+2` | ペインを左右 2 分割 | 数字キーは `phys:` 表記（レイアウト非依存のため） |
| `LEADER+z` | 直前のコマンドと出力をコピー | OSC 133 シェル統合が前提 |

リーダーキー・プレフィックスがある場合は表の前に明記する。

### 🔧 カスタム関数・イベントハンドラ
- **`関数名`** — 何をするか。どこから呼ばれるか。
- **`wezterm.on("イベント名")`** — いつ発火し、何を返すと何が起きるか。

### 🖥️ プラットフォーム分岐
`wezterm.target_triple` / OS 判定で挙動が変わる箇所を、条件と結果の対で列挙する。

### 🔗 外部への依存
シェル統合スクリプト、外部コマンド、フォント、プラグインマネージャなど、
「これが無いと動かない」ものを列挙する。

### ⚠️ 触るときの注意
コード中のコメントに書かれた「なぜ」を拾って明示する。例：
- `config.keys` は空テーブル＋`table.insert` で構築している。テーブルリテラルで
  書き直すと既存バインドが消える
- `set_config_overrides` は `window-config-reloaded` を再発火させるため、
  同値なら早期 return して無限ループを防いでいる
- タブ色パレットは末尾追加のみ。並べ替えると選択位置がズレる
````

nvim を対象にした場合は「キーバインド」を `vim.keymap.set` から、「プラグイン」を
`lua/plugins/*.lua` の spec から拾い、**LazyVim のデフォルトを上書きしている箇所**を
特に明示する（後から「効かない」と混乱しやすいため）。

### Phase 4: ソースとのズレの検出（副次的に実施）

カレントリポジトリに配布元（`sync_editor.sh` と `nvim/` `wezterm/`）が**ある場合のみ**、
配布先とのズレを確認して報告する。無ければこの Phase は丸ごとスキップする。

```bash
diff -rq nvim "$HOME/.config/nvim" 2>/dev/null
diff -rq wezterm "$HOME/.config/wezterm" 2>/dev/null
```

差分があれば解説の末尾に警告として添える。**解説の内容は配布先ベースのまま変えない。**

```markdown
### 🔄 ソースとのズレ
`wezterm/wezterm.lua` がリポジトリと配布先で異なる。上の解説は**配布先（実際に動いている設定）**
の内容。リポジトリ側の変更を反映するには `./sync_editor.sh` を実行する。
```

WSL で Windows 側（`/mnt/c/Users/<user>/`）にもズレがあれば同様に報告する。
`.wezterm.lua` は `sync_editor.sh` が単体コピーするファイルなので、
`.config/wezterm/wezterm.lua` と食い違うことがある。

---

## 注意事項

- **解説だけを行い、設定は書き換えない。** 改善案を思いついた場合は提案に留め、
  実際の編集はユーザーの指示を待つ。編集するときは配布先ではなく
  `work-settings` のソースを直し、`./sync_editor.sh` で配布する。
- 行番号を引くときは配布先のファイルを基準にする。ソースと行がズレている場合がある。
- コード中の日本語コメントは「なぜそう書いたか」の一次情報。憶測で上書きせず、
  コメントが無い箇所だけ推測であることを明示して補う。
- nvim は LazyVim 前提。`lua/plugins/` に無い挙動は LazyVim 側のデフォルトなので、
  「この設定ファイルには書かれていない」ことを明示する。
