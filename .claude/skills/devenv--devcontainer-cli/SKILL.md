---
name: devenv--devcontainer-cli
description: devcontainer CLIを使用してDev Container環境の作成・起動・管理・実行などの操作を行うスキル
---

# Devcontainer CLI スキル

devcontainer CLIを使用してDev Container環境を操作するためのスキルです。

## 前提条件

```bash
which devcontainer || npm install -g @devcontainers/cli
docker info
```

## 基本コマンド

```bash
# 起動
devcontainer up --workspace-folder <project-path>

# 既存コンテナを削除して起動
devcontainer up --workspace-folder <project-path> --remove-existing-container

# コンテナ内でコマンド実行
devcontainer exec --workspace-folder <project-path> bash
devcontainer exec --workspace-folder <project-path> npm run dev
```

## よくある操作パターン

```bash
# 1. .devcontainer の存在確認
ls -la <project-path>/.devcontainer/

# 2. 起動してシェル接続
devcontainer up --workspace-folder <project-path>
devcontainer exec --workspace-folder <project-path> bash

# 3. 設定変更後のリビルド
devcontainer up --workspace-folder <project-path> --remove-existing-container --rebuild-if-exists
```

## トラブルシューティング

| 問題 | 原因 | 解決策 |
|------|------|--------|
| `Docker daemon not running` | Docker未起動 | `sudo systemctl start docker` |
| `No devcontainer.json found` | 設定ファイルなし | `.devcontainer/devcontainer.json` を作成 |
| `Port already in use` | ポート競合 | `docker ps` で確認、競合コンテナを停止 |
| `Build failed` | Dockerfile/Feature問題 | `devcontainer build --workspace-folder <path> --no-cache` |
| `Permission denied` | 権限問題 | `sudo` またはdockerグループに追加 |

その他のサブコマンド（`build` / `read-configuration` / `features`）やオプションは `devcontainer --help` を参照。
