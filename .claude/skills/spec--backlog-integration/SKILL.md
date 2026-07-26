---
name: spec--backlog-integration
description: Backlog MCPツールの使い方リファレンスとテンプレート集
---

# Backlog MCP連携スキル

Backlog MCPツールを使って課題の検索・取得・作成・更新・コメント操作を行うためのリファレンスです。

## 概要

Backlog MCPツールは、BacklogのAPIをMCPプロトコル経由で呼び出すためのインターフェースです。課題の一覧取得から詳細確認、コメント追加、新規作成まで一連の操作をエージェントから直接実行できます。

主なユースケース:
- 特定キーワードや担当者で課題を検索する
- 課題の詳細情報やコメント履歴を取得して要約する
- 課題の内容を整理してBacklogに清書として投稿する
- 担当課題の進捗状況を確認する

---

## 利用可能なMCPツール一覧

### get_issues - 課題一覧取得

条件を指定して複数の課題を一覧取得します。

```json
{
  "keyword": "ログイン",
  "projectId": [12345],
  "statusId": [1, 2],
  "assigneeId": [67890],
  "count": 20,
  "order": "desc"
}
```

| パラメータ | 型 | 説明 |
|---|---|---|
| keyword | string | 件名・説明文のキーワード検索 |
| projectId | number[] | 絞り込むプロジェクトIDのリスト |
| statusId | number[] | ステータスIDのリスト（後述） |
| assigneeId | number[] | 担当者のユーザーIDリスト |
| issueTypeId | number[] | 課題種別IDのリスト |
| priorityId | number[] | 優先度IDのリスト |
| count | number | 取得件数（最大100、デフォルト20） |
| offset | number | ページネーション用オフセット |
| order | "asc" / "desc" | ソート順 |

---

### get_issue - 特定課題の詳細取得

課題キーまたはIDを指定して詳細を取得します。

```json
{
  "issueKey": "PROJECT-123"
}
```

```json
{
  "issueId": 12345
}
```

---

### get_issue_comments - 課題のコメント取得

課題に付いたコメントの一覧を取得します。

```json
{
  "issueKey": "PROJECT-123",
  "count": 50,
  "order": "asc"
}
```

| パラメータ | 型 | 説明 |
|---|---|---|
| issueKey | string | 課題キー（例: PROJECT-123） |
| issueId | number | 課題ID |
| count | number | 取得件数（最大100） |
| order | "asc" / "desc" | 古い順 / 新しい順 |
| minId | number | 指定ID以降のコメントのみ |
| maxId | number | 指定ID以前のコメントのみ |

---

### add_issue_comment - 課題へのコメント追加

課題にコメントを投稿します。

```json
{
  "issueKey": "PROJECT-123",
  "content": "確認しました。対応を開始します。"
}
```

```json
{
  "issueKey": "PROJECT-123",
  "content": "## 調査結果\n\n原因を特定しました。詳細は以下の通りです。",
  "notifiedUserId": [67890]
}
```

---

### add_issue - 新規課題作成

新しい課題を作成します。`projectId`、`issueTypeId`、`priorityId` は必須です。

```json
{
  "projectId": 12345,
  "summary": "ログイン画面のバリデーション改善",
  "issueTypeId": 1,
  "priorityId": 3,
  "description": "## 背景\n\n現状のバリデーションでは...",
  "assigneeId": 67890,
  "dueDate": "2026-03-31"
}
```

| パラメータ | 型 | 説明 |
|---|---|---|
| projectId | number | 作成先プロジェクトID（必須） |
| summary | string | 課題の件名（必須） |
| issueTypeId | number | 課題種別ID（必須） |
| priorityId | number | 優先度ID（必須） |
| description | string | 課題の詳細説明 |
| assigneeId | number | 担当者のユーザーID |
| startDate | string | 開始日（yyyy-MM-dd） |
| dueDate | string | 期限日（yyyy-MM-dd） |
| milestoneId | number[] | マイルストーンIDのリスト |

---

### update_issue - 課題更新

既存の課題のステータス・担当者・内容などを更新します。

```json
{
  "issueKey": "PROJECT-123",
  "statusId": 2,
  "assigneeId": 67890,
  "comment": "担当を変更しました。"
}
```

```json
{
  "issueKey": "PROJECT-123",
  "statusId": 3,
  "resolutionId": 0,
  "comment": "修正完了。レビュー依頼します。"
}
```

---

## 課題検索パターン

### キーワード検索

`keyword` パラメータを使うと、課題の件名と説明文を対象に全文検索できます。

```json
{ "keyword": "認証エラー" }
{ "keyword": "タイムアウト 本番" }
{ "keyword": "リファクタリング API" }
```

ヒント: 複数単語はスペース区切りで指定します。AND検索として動作します。

---

### ステータス検索

`statusId` に数値の配列を指定します。

| statusId | ステータス名 |
|---|---|
| 1 | 未対応 |
| 2 | 処理中 |
| 3 | 処理済み |
| 4 | 完了 |

```json
{ "statusId": [1, 2] }
```

未完了の課題（未対応・処理中）を取得する例です。

---

### 担当者検索

`assigneeId` にユーザーIDの配列を指定します。ユーザーIDは `get_users` や `get_myself` で確認できます。

```json
{ "assigneeId": [67890] }
```

自分が担当している課題を検索する場合:
1. `get_myself` で自分のユーザーIDを取得する
2. そのIDを `assigneeId` に指定する

---

### プロジェクト絞り込み

`projectId` にプロジェクトIDの配列を指定します。プロジェクト一覧は `get_project_list` で確認できます。

```json
{ "projectId": [12345, 67890] }
```

---

### 複合条件の例

```json
{
  "projectId": [12345],
  "statusId": [1, 2],
  "assigneeId": [67890],
  "keyword": "バグ",
  "count": 50,
  "order": "desc"
}
```

---

## 課題要約テンプレート

`get_issue` と `get_issue_comments` で取得した情報を以下の構成で要約します。

```
## 課題要約: {課題キー} {課題タイトル}

### 背景・経緯
- いつ、どのような状況で発生・起票されたか
- 関連する過去の課題や経緯があれば記載

### 目的・解決したい課題
- この課題で何を達成したいか
- 現状の問題点や不満点

### 要件・仕様
- 具体的に何をする必要があるか
- 完了条件（Acceptance Criteria）

### 影響範囲
- 影響するシステム・機能・チーム
- ユーザーへの影響

### 懸念点・リスク
- 技術的な課題や不明点
- 対応によって生じうる副作用
- 依存関係・前提条件

### 現在のステータス
- ステータス: {ステータス名}
- 担当者: {担当者名}
- コメント数: {件数}
- 最終更新: {日時}
```

---

## Backlog清書テンプレート（Markdownフォーマット）

以下はBacklogに貼り付け可能なMarkdown形式のテンプレートです。BacklogはMarkdown記法に対応しています。

### 機能要求・改善提案

```markdown
## 背景

<!-- なぜこの機能が必要か、現状の課題を説明する -->

## 目的

<!-- この課題で達成したいことを簡潔に記述する -->

## 要件

-
-
-

## 完了条件

- [ ]
- [ ]
- [ ]

## 影響範囲

- 影響するシステム:
- 影響するユーザー:

## 備考

<!-- 関連課題、参考リンクなど -->
```

---

### バグ報告

```markdown
## 概要

<!-- バグの概要を1〜2文で説明する -->

## 再現手順

1.
2.
3.

## 期待する動作

<!-- 本来はどう動作すべきか -->

## 実際の動作

<!-- 実際に起きていること -->

## 環境情報

- 環境: （本番 / ステージング / 開発）
- ブラウザ/OS:
- バージョン:

## 影響度

- 影響ユーザー数:
- 回避策の有無:

## ログ・スクリーンショット

<!-- 必要に応じて添付 -->
```

---

### 調査・技術検討

```markdown
## 調査背景

<!-- なぜ調査が必要か -->

## 調査内容

<!-- 何を調査するか -->

## 調査結果

<!-- 調査後に記入 -->

## 結論・推奨事項

<!-- 調査結果を踏まえた提案 -->

## 参考資料

-
```

---

## 使い方のヒント

### 課題が見つからない時の対処法

1. **キーワードを変える**: 別の表現や略語を試す（例: 「ログ」→「ログイン」「ログアウト」）
2. **キーワードを短くする**: 複合語より単語単位で検索する（例: 「エラーハンドリング改善」→「エラー」）
3. **プロジェクトを指定する**: 複数プロジェクトがある場合は `projectId` を絞り込む
4. **ステータスを広げる**: 完了済み（statusId: 4）を含めて検索する
5. **件数を増やす**: `count: 100` で最大件数を取得する
6. **キーワードなしで一覧取得**: `keyword` を省略してプロジェクト全体の最新課題を確認する

---

### コメントが多い場合の対処法

1. **新しいコメントから確認**: `order: "desc"` で最新コメントを先に取得する
2. **件数を絞る**: `count: 10` で直近のコメントのみ取得し、概要を把握してから追加取得する
3. **古いコメントを遡る**: `maxId` を指定して特定の時点以前のコメントを取得する
4. **課題本文と最新コメントを組み合わせる**: `get_issue` で本文を取得し、`get_issue_comments` で最新10件を取得して全体像を把握する

---

### よくある操作パターン

**課題の内容を調べて清書する場合:**
1. `get_issue` で課題本文を取得
2. `get_issue_comments` でコメント履歴を取得（`order: "asc"` で時系列順）
3. 上記テンプレートに沿って要約・清書
4. `add_issue_comment` または `update_issue` で清書内容を投稿

**担当課題の進捗確認:**
1. `get_myself` で自分のユーザーIDを取得
2. `get_issues` で `assigneeId` と `statusId: [1, 2]` を指定して一覧取得
3. 各課題の詳細は `get_issue` で確認
