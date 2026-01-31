---
name: devcontainer-cli
description: devcontainer CLIを使用してDev Container環境の作成・起動・管理・実行などの操作を行うスキル
---

# Devcontainer CLI スキル

devcontainer CLIを使用してDev Container環境を操作するためのスキルです。

## 前提条件

```bash
# devcontainer CLIのインストール確認
which devcontainer
devcontainer --version

# インストールされていない場合
npm install -g @devcontainers/cli

# Dockerが起動していること
docker info
```

---

## 基本コマンド

### up - コンテナの起動

```bash
# 基本起動
devcontainer up --workspace-folder <project-path>

# 既存コンテナを削除して起動
devcontainer up --workspace-folder <project-path> --remove-existing-container

# 特定の設定ファイルを指定
devcontainer up --workspace-folder <project-path> --config <path-to-devcontainer.json>
```

### exec - コンテナ内でコマンド実行

```bash
# シェル起動
devcontainer exec --workspace-folder <project-path> bash

# 特定コマンド実行
devcontainer exec --workspace-folder <project-path> npm install
devcontainer exec --workspace-folder <project-path> npm run dev

# 複数コマンド
devcontainer exec --workspace-folder <project-path> sh -c "npm install && npm run build"
```

### build - イメージのビルド

```bash
# 基本ビルド
devcontainer build --workspace-folder <project-path>

# キャッシュなしでビルド
devcontainer build --workspace-folder <project-path> --no-cache

# イメージ名を指定
devcontainer build --workspace-folder <project-path> --image-name my-devcontainer:latest
```

### read-configuration - 設定の読み取り

```bash
# 設定内容をJSON形式で出力
devcontainer read-configuration --workspace-folder <project-path>

# jqで特定項目を抽出
devcontainer read-configuration --workspace-folder <project-path> | jq '.configuration.image'
```

### features - Feature情報

```bash
# 利用可能なFeature一覧
devcontainer features list

# Feature情報の詳細
devcontainer features info ghcr.io/devcontainers/features/node
```

---

## よくある操作パターン

### パターン1: 新規プロジェクトでDevcontainer起動

```bash
# 1. .devcontainerの存在確認
ls -la <project-path>/.devcontainer/

# 2. 設定確認
cat <project-path>/.devcontainer/devcontainer.json

# 3. 起動
devcontainer up --workspace-folder <project-path>

# 4. シェル接続
devcontainer exec --workspace-folder <project-path> bash
```

### パターン2: 開発サーバー起動

```bash
# コンテナ起動後、開発サーバーを実行
devcontainer exec --workspace-folder <project-path> npm run dev
```

### パターン3: リビルド

```bash
# 設定変更後のリビルド
devcontainer up --workspace-folder <project-path> --remove-existing-container --rebuild-if-exists
```

### パターン4: デバッグ

```bash
# 詳細ログ付きで起動
devcontainer up --workspace-folder <project-path> --log-level debug

# ビルドログ確認
devcontainer build --workspace-folder <project-path> 2>&1 | tee build.log
```

---

## トラブルシューティング

| 問題 | 原因 | 解決策 |
|------|------|--------|
| `Docker daemon not running` | Docker未起動 | `sudo systemctl start docker` |
| `No devcontainer.json found` | 設定ファイルなし | `.devcontainer/devcontainer.json` を作成 |
| `Port already in use` | ポート競合 | `docker ps` で確認、競合コンテナを停止 |
| `Build failed` | Dockerfile/Feature問題 | `--no-cache` でリビルド |
| `Permission denied` | 権限問題 | `sudo` またはdockerグループに追加 |

---

## devcontainer.json の基本構造

```jsonc
{
  // ベースイメージ
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",

  // または Dockerfile を使用
  // "build": { "dockerfile": "Dockerfile" },

  // 追加機能
  "features": {
    "ghcr.io/devcontainers/features/node:1": {},
    "ghcr.io/devcontainers/features/docker-in-docker:2": {}
  },

  // ポートフォワード
  "forwardPorts": [3000, 5432],

  // コンテナ作成後に実行
  "postCreateCommand": "npm install",

  // 起動時に実行
  "postStartCommand": "npm run dev",

  // VS Code 拡張機能
  "customizations": {
    "vscode": {
      "extensions": [
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode"
      ]
    }
  }
}
```

---

## CI/CDでの利用

```bash
# GitHub Actionsなどで利用
devcontainer up --workspace-folder . --skip-post-create
devcontainer exec --workspace-folder . npm test
devcontainer exec --workspace-folder . npm run build
```
