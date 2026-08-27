---
name: docs--lua-config-guide
description: 配布済みの nvim(LazyVim) と wezterm の Lua 設定をすべて読み解いて日本語で解説するスキル
---

# Lua 設定の解説

自分で書いた nvim（LazyVim 構成）と wezterm の Lua 設定が「何をしているのか」「なぜそう
書いてあるのか」を読み解いて日本語で解説するスキルです。久しぶりに触るとき、キーバインドを
忘れたとき、他人に説明するとき、設定を壊さずに手を入れたいときに使います。

**引数は取りません。毎回 nvim と wezterm の両方を、設定ファイル全体について解説します。**
一部だけ読んで済ませたり、ユーザーに対象を尋ねたりしないこと。

## 対象は必ず「配布先」を見る

このスキルは `work-settings` から各リポジトリへ配布されるため、**実行先のリポジトリに
`nvim/` や `wezterm/` のソースが存在するとは限りません**。解説の対象は常に、
`sync_editor.sh` が実際に配布したパス（＝いま動いている設定そのもの）とします。

| 対象 | 配布先 |
|---|---|
| nvim | `$HOME/.config/nvim/` |
| wezterm | `$HOME/.config/wezterm/` |
| wezterm（WSL のみ・Windows 側） | `/mnt/c/Users/{user}/.config/wezterm/` と `/mnt/c/Users/{user}/.wezterm.lua` |

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
- **片方だけ見つかった場合**は、見つかった方だけを解説し、もう片方が未配布であることを明記する。
- WSL では Linux 側と Windows 側の 2 か所に同じ内容が配布される。**解説は Linux 側
  （`$HOME/.config/wezterm`）を正とし**、Windows 側は Phase 4 の差分チェックにのみ使う。

### Phase 2: 設定ファイルを全部読む

配布先にあるファイルを次の順で読む。順序は「読み込み順」と「自分で書いた度合い」に対応しており、
この順に読むと依存関係が理解しやすい。

**wezterm**

1. `wezterm.lua` — 設定の全体。この 1 ファイルに外観・キーバインド・イベントハンドラが同居する
2. 同ディレクトリの他の `*.lua`（あれば）
3. `*.sh`（`wezterm-split.sh` など。CLI 側からの補助スクリプト）

**nvim（LazyVim 構成）**

1. `init.lua` → `lua/config/lazy.lua` — ブートストラップ、プラグインの読み込み順、LazyVim の取り込み方
2. `lua/config/options.lua` / `keymaps.lua` / `autocmds.lua` — 自分で書いた設定の本体
3. `lua/plugins/*.lua` — 各プラグインの spec（全ファイル読む）
4. `lazyvim.json` — 有効にしている LazyVim extras
5. `.neoconf.json` / `stylua.toml` — LSP 設定と整形規約

`lazy-lock.json` はバージョン固定の記録なので通読しない。バージョンに言及する必要が出たときだけ引く。

ファイル数が多くても省略しない。読み飛ばした場合はその旨を出力に明記すること。

### Phase 3: 解説の生成

読んだ内容から、**日本語で**以下を出力する。コードをそのまま貼り直すのではなく、
「何のために」「どう動くか」「触るとどこが壊れるか」を書く。wezterm → nvim の順で
2 部構成にし、最後に共通の注意点をまとめる。

````markdown
# 🖥️ 設定解説

**読んだファイル**: `~/.config/wezterm/`（N ファイル）、`~/.config/nvim/`（M ファイル）

---

## 1. wezterm

### 全体像
このファイルが何を担当しているか、どういう順で処理が走るかを 3〜5 行で。

### ⌨️ キーバインド
リーダーキーがあれば表の前に明記する。

| キー | 動作 | 備考 |
|---|---|---|
| `Ctrl+Shift+2` | ペインを左右 2 分割 | 数字キーは `phys:` 表記（レイアウト非依存のため） |
| `LEADER+z` | 直前のコマンドと出力をコピー | OSC 133 シェル統合が前提 |

### 🔧 カスタム関数・イベントハンドラ
- **`関数名`** — 何をするか。どこから呼ばれるか。
- **`wezterm.on("イベント名")`** — いつ発火し、何を返すと何が起きるか。

### 🎨 外観・パレット
配色、フォント、透明度、タブバー。パレットに規約（コントラスト比・並び順など）が
コメントで書かれていれば拾う。

### 🖥️ プラットフォーム分岐
`wezterm.target_triple` による分岐を、条件と結果の対で列挙する。

---

## 2. nvim (LazyVim)

### 全体像
LazyVim をどう取り込んでいるか、`lua/config/` と `lua/plugins/` の役割分担。

### 📦 有効な LazyVim extras
`lazyvim.json` から列挙し、それぞれ何が入るかを一言で。

### ⌨️ キーバインド
`vim.keymap.set` を拾って表にする。**LazyVim のデフォルトを上書きしている箇所は
必ず明示する**（後から「効かない」と混乱しやすいため）。

| キー | モード | 動作 | 備考 |
|---|---|---|---|
| `jj` | insert | Esc | |
| `H` / `L` | n, v | 行頭 / 行末 | LazyVim 標準のバッファ切り替えを上書き |

### 🔌 プラグイン
`lua/plugins/*.lua` のファイルごとに、何を入れて何を設定しているか。
`opts` で上書きしているのか `config` で差し替えているのかを区別する。

### ⚙️ オプション・autocmd
`options.lua` / `autocmds.lua` のうち、挙動が目に見えて変わるものを中心に。

---

## ⚠️ 触るときの注意

コード中のコメントに書かれた「なぜ」を拾って明示する。例：
- `config.keys` は空テーブル＋`table.insert` で構築している。テーブルリテラルで
  書き直すと既存バインドが消える
- `set_config_overrides` は `window-config-reloaded` を再発火させるため、
  同値なら早期 return して無限ループを防いでいる
- タブ色パレットは末尾追加のみ。並べ替えると選択位置がズレる

## 🔗 外部への依存

シェル統合スクリプト、外部コマンド、フォント、プラグインマネージャなど、
「これが無いと動かない」ものを nvim / wezterm 横断で列挙する。
````

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

WSL で Windows 側（`/mnt/c/Users/{user}/`）にもズレがあれば同様に報告する。
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
