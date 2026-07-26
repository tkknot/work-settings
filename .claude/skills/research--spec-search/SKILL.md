---
name: spec-search
description: リポジトリ内から仕様・機能を検索するためのコマンドとテクニック
---

# 仕様検索スキル

リポジトリ内から特定の仕様や機能の実装箇所を効率的に検索するスキルです。

## 検索コマンド

### ripgrep (rg)

```bash
# 基本検索
rg "<keyword>"

# 大文字小文字無視
rg -i "<keyword>"

# ファイルタイプ指定
rg "<keyword>" -t ts -t js -t py

# 除外パターン
rg "<keyword>" -g "!node_modules" -g "!dist"

# コンテキスト表示（前後3行）
rg "<keyword>" -C 3

# ファイル名のみ
rg -l "<keyword>"

# 正規表現
rg "(function|class).*<keyword>"
```

### fd（ファイル検索）

```bash
# ファイル名検索
fd "<keyword>"

# 拡張子指定
fd -e ts -e js "<keyword>"

# 隠しファイル含む
fd -H "<keyword>"
```

### Git履歴検索

```bash
# コミットメッセージ検索
git log --oneline --all --grep="<keyword>"

# 変更内容から検索（pickaxe）
git log -p --all -S "<keyword>" --oneline

# ファイル変更履歴
git log --oneline --all -- "*<keyword>*"

# 特定期間
git log --since="2024-01-01" --grep="<keyword>"
```

## キーワード展開パターン

| 概念 | 関連キーワード |
|------|---------------|
| 認証 | `auth`, `login`, `signin`, `session`, `token`, `jwt` |
| ユーザー | `user`, `account`, `member`, `profile`, `customer` |
| 決済 | `payment`, `checkout`, `billing`, `charge`, `invoice` |
| 通知 | `notification`, `notify`, `alert`, `push`, `email` |
| API | `endpoint`, `route`, `handler`, `controller` |
| DB | `model`, `schema`, `migration`, `query`, `repository` |

## 検索対象別コマンド

### 関数・クラス定義

```bash
# TypeScript/JavaScript
rg "(function|class|interface|type|const).*<keyword>"

# Python
rg "(def|class).*<keyword>"

# Go
rg "(func|type).*<keyword>"
```

### テストファイル

```bash
rg "<keyword>" -g "*.test.*" -g "*.spec.*"
```

### ドキュメント

```bash
rg "<keyword>" -t md -t txt -g "README*"
```

### API仕様

```bash
rg "<keyword>" -g "*.yaml" -g "*.json" -g "openapi*" -g "swagger*"
```

### 設定ファイル

```bash
rg "<keyword>" -g "*.config.*" -g "*.env*" -g "*.json"
```

## 依存関係追跡

```bash
# import元を検索
rg "import.*from.*<file>"
rg "require\(.*<file>\)"

# 呼び出し元を検索
rg "<functionName>\("
```

## 除外すべきディレクトリ

```
node_modules/
.git/
dist/
build/
.next/
coverage/
*.min.js
*.lock
```

## 検索のコツ

1. **複数キーワードで検索** - 1つで見つからなければ類義語で
2. **パターン検索** - 関数定義・クラス定義を正規表現で
3. **Git履歴も活用** - 削除されたコードも見つかる
4. **除外フィルタ** - 不要な結果を除外
5. **段階的に絞り込み** - 広く検索→条件追加
