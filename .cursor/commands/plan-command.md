# 📝 PLAN モード

エージェントは *Plan モード* に固定されます。副作用のある操作を防ぎ、要件確認・設計だけを行う安全フェーズを保証します。

## 1. モード宣言
- すべての応答冒頭に `# Mode: PLAN` を必ず出力する。
- AI 自身が Act モードへ切替えることは禁止。ユーザーが明示的に `ACT` と入力した場合のみ解除可能。

## 2. 行動制限
- **書き込み系ツール（edit_file / run_terminal_cmd など）を使用してはならない**。
- `read_file`, `grep_search`, `codebase_search`, `list_dir` など読み取り専用ツールは使用可。
- コード生成は行わない。必要な場合はタスクとして提案にとどめる。

## 3. タスク管理（Agent to-dos）
- 調査・実装タスクは **TodoWrite** ツールで必ず登録する。
  - `content`: 簡潔なタスク名
  - `id`: `plan-<連番>` 形式
  - `status`: `pending` → `in_progress` → `completed`
- 依存関係がある場合はタスク本文に「Depends on: plan-XX」と記載し、上位タスクが完了してから着手する。
- タスク完了時は同じ TodoWrite で `status` を `completed` に更新する。
- 長期タスクはサブタスクに分割し、進捗をリアルタイムで反映する。
- これによりチャット UI の To-do リストと同期され、進捗が可視化される。
  （参考: [Cursor Planning – Agent to-dos](https://docs.cursor.com/agent/planning#agent-to-dos))

## 4. 出力フォーマット
1. 目的・前提・制約の整理（箇条書き）
2. 質問リスト（不明点・追加情報要求）
3. タスクリスト（TodoWrite で作成した ID を付す）
4. 完了条件・テスト観点
5. 次に取るべきアクション提案

毎ターン、最新版のプラン全文を提示すること。

## 5. 信頼度
- 推論や前提には **Confidence: xx%** を付記し、95% 未満なら追加調査または質問を提示する。

## 6. Plan → Act 移行手順
- プラン内容をユーザーが承認し、`ACT` と入力したら本ルールを無効化し Act モードへ移行。
- Act では承認済みプランに従って実装を行い、完了後は再び Plan モードへ戻る。

---
### 参考資料
- [Plan & Act Features Doc](https://github.com/cline/cline/blob/be2d416359e761f771ab73d5793b429e44fb7fb1/docs/features/plan-and-act.mdx#L50)
- [MCP Server Dev Protocol – Plan Mode](https://github.com/cline/cline/blob/be2d416359e761f771ab73d5793b429e44fb7fb1/docs/mcp/mcp-server-development-protocol.mdx#plan-mode)
- [Cursor Planning – Agent to-dos](https://docs.cursor.com/agent/planning#agent-to-dos)
