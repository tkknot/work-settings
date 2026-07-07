# Claude Code プラグイン化候補の分析レポート

本リポジトリの `.ai/` 配下の資産のうち、Claude Code のプラグイン機構(`/plugin`)として提供したほうがよいものを整理する。

**結論(TL;DR)**: 現在 `sync_claude_settings.sh` + GitHub Actions で行っている配布は、プラグイン機構の手作り版に相当する。スキル19個・Stop通知フック・MCP設定はすべてプラグインに移植可能であり、**汎用の `dev-workflow` と会社固有の `backlog-suite` の2プラグインに分割し、このリポジトリ自体をマーケットプレイス化する**構成を推奨する。一方、`.claude/settings.json` の `env`・`language`・`advisorModel` と `.ai/rules/` はプラグインのスコープ外なので、既存の配布機構を完全には廃止できない。

## 1. 現状インベントリ

| 資産 | 内容 | プラグイン適性 |
|---|---|---|
| `.ai/skills/` | スキル19個(`{prefix}--{name}/SKILL.md`、frontmatter は name/description のみ) | ◎ そのまま `skills/` に移植可能 |
| `.ai/hooks/claude-notify.sh` | Stop時のOS通知(macOS/WSL/Linux対応、秘密情報なし) | ◎ `hooks/hooks.json` + スクリプト同梱 |
| `.ai/mcp.json` | MCPサーバー5個(github / Playwright / context7 / backlog / codegraph) | ○ プラグインルートの `.mcp.json` に移植(認証情報の外部化が必要) |
| `.ai/rules/` | commit-convention / file-naming-convention | △ プラグインに規約専用のスロットはない(後述) |
| `.claude/settings.json` | env(実験フラグ・subagentモデル)、language、advisorModel、Stopフック | × フック以外はプラグインのスコープ外 |
| `sync_*.sh` + `.github/workflows/distribute-settings.yml` | `~/.claude` および全リポジトリへの手動配布 | — プラグイン化で大部分が代替される対象 |

### 現行配布の課題(プラグイン化の動機)

- 配布先リポジトリごとに sync PR が作られ、更新のたびに全リポジトリでマージ作業が発生する
- 配布先でファイルがコピーとして分散するため、バージョンの一貫性を保証できない
- プラグインなら `/plugin install` 一回で導入でき、`version` を省略すれば git のコミットSHA基準で `/plugin update` により常に最新へ追従できる(開発中の内部プラグインに適したモード)

## 2. 推奨構成: 2プラグイン + マーケットプレイス

このリポジトリのルートに `.claude-plugin/marketplace.json` を置き、リポジトリ自体をマーケットプレイスにする。利用者(自分・チーム)は次の2コマンドで導入できる。

```
/plugin marketplace add tkknot/work-settings
/plugin install dev-workflow@work-settings
```

### 2.1 `dev-workflow` プラグイン(汎用・最優先候補)

社外・他チームにも共有できる汎用ワークフロー集。

- **スキル13個**: `arch--design-implementation-workflow`, `devenv--devcontainer-cli`, `docs--update-docs`, `git--branch-summary`, `git--create-pull-request`, `git--git-worktree`, `quality--refactor`, `research--spec-search`, `review--code-review`, `security--dependabot-workflow`, `test--e2e-testing`, `test--tdd`, `test--test-case-design`
- **フック**: `claude-notify.sh` を同梱し、`hooks/hooks.json` でパスを `"${CLAUDE_PLUGIN_ROOT}"/hooks/claude-notify.sh` に書き換える(現状の `$HOME/.ai/hooks/...` というホーム絶対パス依存が解消される)
- **MCP**: `context7` / `codegraph` は秘密情報なしで `.mcp.json` に同梱可。`Playwright` は `--config` を `${CLAUDE_PLUGIN_ROOT}/playwright-config.json` に書き換えれば同梱可(現状の `.claude/playwright-config.json` という相対パスはカレントディレクトリ依存で壊れやすい)

### 2.2 `backlog-suite` プラグイン(会社固有)

Backlog に言及するスキルは19個中5個に限られ、きれいに分離できる。

- **スキル5個**: `spec--backlog-integration`, `spec--requirements-workflow`, `debug--bug-investigation-workflow`, `format--backlog-notation`, `test--verification-workflow`
- **MCP**: `backlog-mcp-server` を `.mcp.json` に同梱。`BACKLOG_DOMAIN` / `BACKLOG_API_KEY` は現在 `.ai/mcp.json` にプレースホルダ直書きだが、プラグインの `userConfig` 機構(`plugin.json` に定義し `${user_config.KEY}` で参照、`sensitive: true` でOSキーチェーン保存)に置き換えられる。**認証情報管理は手動編集からUI入力+安全な保存に改善される**

なお `github` MCP サーバーはどちらにも入れない(Claude Code 本体の GitHub 連携や `gh` CLI と重複し、PAT 管理の手間だけが残るため。必要ならユーザースコープで個別登録)。

### 2.3 ディレクトリ構成案

```
work-settings/
├── .claude-plugin/
│   └── marketplace.json          # name, owner, plugins: [{name, source: "./plugins/..."}]
└── plugins/
    ├── dev-workflow/
    │   ├── .claude-plugin/plugin.json   # version は省略(コミットSHA追従)
    │   ├── skills/                      # 13スキルを移動(SKILL.md はそのまま)
    │   ├── hooks/
    │   │   ├── hooks.json               # settings.json の hooks オブジェクトと同形式
    │   │   └── claude-notify.sh
    │   ├── .mcp.json                    # context7 / codegraph / Playwright
    │   └── playwright-config.json
    └── backlog-suite/
        ├── .claude-plugin/plugin.json   # userConfig: backlog_domain, backlog_api_key(sensitive)
        ├── skills/                      # 5スキルを移動
        └── .mcp.json                    # backlog(${user_config.*} 参照)
```

注意点:

- `commands/` `skills/` `hooks/` は**プラグインルート直下**に置く(`.claude-plugin/` の中に入れるのはよくある誤り。中に入れてよいのは `plugin.json` のみ)
- スキル名は `/dev-workflow:test--tdd` のように名前空間付きになる。`{prefix}--{name}` 命名(`.ai/rules/file-naming-convention.md`)とプラグイン名前空間が二重になるため、移行時に prefix をディレクトリ名から外す(例: `skills/tdd/`)ことも検討の余地がある
- 開発中は `claude --plugin-dir ./plugins/dev-workflow` でインストール不要のまま動作確認でき、`/reload-plugins` で変更を即反映できる

## 3. プラグイン化に向かないもの

| 資産 | 理由 | 代替案 |
|---|---|---|
| `.claude/settings.json` の `env` / `language` / `advisorModel` / `enableWorkflows` | プラグインの `settings.json` は現状 `agent` / `subagentStatusLine` キーのみ対応 | 現行の sync 配布を継続 |
| `.ai/rules/`(規約) | プラグインに「常時読み込まれるルール」のスロットがない | AGENTS.md 経由の配布を継続。またはスキル化(ただし常時適用の保証はなくなる) |
| `team--session` スキル | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` が前提で、プラグインから env を設定できない | settings 配布とセットで残す(プラグインに入れると env なしの環境で機能しない) |
| `AGENTS.md` 本体 | プラグインのコンポーネントではない | 現行配布を継続 |
| `nvim/` `wezterm/` `shell/` | AI 無関係の dotfiles | 対象外 |

## 4. 移行ステップ案

1. `plugins/dev-workflow/` を作成し、汎用スキル13個を移動、`hooks/hooks.json` + `claude-notify.sh` を同梱(`claude plugin validate` で検証)
2. `plugins/backlog-suite/` を作成し、Backlog系スキル5個と `userConfig` 化した MCP 設定を移植
3. ルートに `.claude-plugin/marketplace.json` を作成
4. `claude --plugin-dir` でローカル検証後、`/plugin marketplace add tkknot/work-settings` で実運用開始
5. **併存期間**: `sync_claude_settings.sh` と `distribute-settings.yml` はスキル・フック配布部分を止めず並行運用し、プラグイン運用が安定したらスキル/フック/MCP の配布のみ削る(settings.json と AGENTS.md の配布は残す)
6. 廃止判断の基準: 全利用環境でプラグインインストールが完了し、`~/.claude/skills` 等のコピーと二重定義になっていないこと(同名スキルはローカル側が優先されるため、旧コピーの削除が必要)

## 5. 調査中に見つかった修正候補(プラグイン化とは独立)

- `AGENTS.md` と `.ai/rules/commit-convention.md` が参照する **`.ai/rules/security-baseline.md` が存在しない**(リンク切れ)
- `.ai/mcp.json` の Playwright `--config .claude/playwright-config.json` は相対パスのため、リポジトリルート以外から起動すると解決できない(sync スクリプトが絶対パスに書き換えて回避している——プラグイン化で根本解決する)

## 6. 人間の判断が必要な事項

1. **分割粒度**: 推奨は2分割(dev-workflow / backlog-suite)。MCP サーバーだけ第3のプラグインに分ける案もあるが、スキルとの結合(backlog スキルは backlog MCP 前提)を考えると2分割が管理しやすい
2. **スキル命名**: プラグイン名前空間の導入に伴い、`{prefix}--` をディレクトリ名から外すか(`file-naming-convention.md` の改訂を伴う)
3. **backlog 認証情報**: `userConfig`(キーチェーン保存)方式でよいか、従来どおり環境変数方式にするか
4. **既存配布機構の廃止時期**: 併存期間をどの程度取るか、`distribute-settings.yml` の全リポジトリ PR 配布をいつ止めるか
5. **公開範囲**: `dev-workflow` を社外公開(コミュニティマーケットプレイス申請)まで視野に入れるか、tkknot 内部限定か
