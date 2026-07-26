---
name: update-docs
description: コード変更に伴うドキュメント更新を行うためのスキル
---

# ドキュメント更新スキル

コード変更に伴うドキュメントを正確に更新するためのスキルです。

## 対象ドキュメント

| 優先度 | ドキュメント |
|--------|-------------|
| 高 | README.md, CHANGELOG.md, API仕様書, CONTRIBUTING.md |
| 中 | アーキテクチャ図, コードコメント, 設定説明 |
| 低 | 内部Wiki, チュートリアル |

## 変更種別と更新対象

| 変更種別 | 更新対象 |
|---------|---------|
| 新機能追加 | README, CHANGELOG, API仕様書 |
| 破壊的変更 | README, CHANGELOG, マイグレーションガイド |
| API変更 | API仕様書, CHANGELOG |
| 依存関係変更 | README（セットアップ手順） |
| バグ修正 | CHANGELOG |

## CHANGELOG形式（Keep a Changelog）

```markdown
## [Unreleased]

### Added
- 新機能の説明

### Changed
- 変更された機能

### Deprecated
- 非推奨になった機能

### Removed
- 削除された機能

### Fixed
- バグ修正

### Security
- セキュリティ修正
```

## コードコメント

### JSDoc

```javascript
/**
 * ユーザーを作成する
 * @param {Object} userData - ユーザーデータ
 * @param {string} userData.name - ユーザー名
 * @returns {Promise<User>} 作成されたユーザー
 * @throws {ValidationError} バリデーションエラー時
 */
```

### Python docstring

```python
def create_user(user_data: dict) -> User:
    """
    新規ユーザーを作成する。

    Args:
        user_data: ユーザー情報
            - name (str): ユーザー名
            - email (str): メールアドレス

    Returns:
        User: 作成されたユーザー

    Raises:
        ValidationError: バリデーションエラー時
    """
```

## 自動化ツール

```bash
# TypeDoc
npx typedoc --out docs src/

# conventional-changelog
npx conventional-changelog -p angular -i CHANGELOG.md -s

# git-cliff
git cliff -o CHANGELOG.md
```

## 破壊的変更の告知

```markdown
## ⚠️ 破壊的変更

### 変更内容
[v2.0.0] `oldFunction()` → `newFunction()`

### マイグレーション手順
1. `oldFunction()` を検索
2. `newFunction()` に置換
3. パラメータを更新

### Before
```javascript
oldFunction({ legacy: true });
```

### After
```javascript
newFunction({ modern: true });
```
```

## チェックリスト

```markdown
□ 変更内容がドキュメントに反映されている
□ コード例が動作する
□ リンクが有効である
□ スペルミスがない
□ 一貫したフォーマット
□ バージョン番号が正しい
```

## ベストプラクティス

### やるべきこと

- コード変更と同時にドキュメント更新
- 具体的なコード例を含める
- 既存スタイルに従う
- CHANGELOGを常に更新

### 避けるべきこと

- 古い情報を残す
- 曖昧な表現
- 更新を後回しにする
