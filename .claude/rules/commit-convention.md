# コミットメッセージ規約

`work-settings` および配布先リポジトリで共通。

```
<type>(<scope>): <日本語の要約>

<本文：何を・なぜ変えたかを日本語で説明（任意だが推奨）>

Co-Authored-By: Claude <noreply@anthropic.com>
```

- **subject**: `type(scope):` に続けて**日本語**で簡潔に。`why` は本文に書く。
  単純な雑務で type が馴染まなければ日本語の要約のみでもよい
  （例: `sync_*.sh を一括実行する sync_all.sh を追加`）。
- **本文**: 箇条書き可。「なぜ」を含めると後から追いやすい。
- **フッター**: AI が作成したコミットは `Co-Authored-By` を付ける。
  ただし**PR 本文には AI 署名を付けない**（`git--create-pull-request` スキル参照）。

| type | 用途 |
|---|---|
| `feat` | 新機能・新しい設定の追加 |
| `fix` | 不具合修正 |
| `chore` | 雑務・設定同期・依存更新 |
| `docs` | ドキュメント・rules・skills の変更 |
| `refactor` | 挙動を変えないリファクタリング |
| `test` | テストの追加・修正 |

scope の例: `wezterm` / `nvim` / `claude` / `sync` / `rules` / `skills` / `ci`
