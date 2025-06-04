# プロジェクト タスク割り振り・スケジュール

このファイルはプロジェクトのタスク割り振りとスケジュールをMermaid Gantt形式で管理します。

## 📅 プロジェクト全体スケジュール

```mermaid
gantt
    title プロジェクトスケジュール（要件定義～検証）
    dateFormat  YYYY-MM-DD
    axisFormat  %m/%d
    
    section 要件定義・設計
    要求収集・分析 PM担当             :active, req_analysis, 2024-01-15, 7d
    要件定義書作成 PM担当             :crit, req_doc, after req_analysis, 7d
    システム設計 リードエンジニア担当   :crit, sys_design, after req_doc, 10d
    詳細設計 リードエンジニア担当       :detail_design, after sys_design, 8d
    
    section 開発・実装
    開発環境構築 リードエンジニア担当   :env_setup, after detail_design, 3d
    フロントエンド開発 FEエンジニア担当 :fe_dev, after env_setup, 15d
    バックエンド開発 BEエンジニア担当   :be_dev, after env_setup, 20d
    単体テスト 各エンジニア担当        :unit_test, after be_dev, 5d
    結合テスト 全エンジニア担当        :integration_test, after fe_dev, 7d
    
    section テスト・検証
    システムテスト QAエンジニア担当     :system_test, after integration_test, 7d
    ユーザー受入テスト PM担当          :uat, after system_test, 5d
    性能テスト QAエンジニア担当        :perf_test, after uat, 3d
    セキュリティテスト QAエンジニア担当 :security_test, after perf_test, 3d
    
    section マイルストーン
    要件定義完了     :milestone, m1, after req_doc, 1d
    設計完了        :milestone, m2, after detail_design, 1d
    開発完了        :milestone, m3, after integration_test, 1d
    検証完了        :milestone, m4, after security_test, 1d
```

## 📊 今週のタスク詳細

```mermaid
gantt
    title 今週のタスクスケジュール
    dateFormat  YYYY-MM-DD
    
    section 要件定義
    要求収集・分析 PM担当           :active, req_analysis_week, 2024-01-15, 4d
    ステークホルダー確認 PM担当      :stakeholder, after req_analysis_week, 2d
    
    section 設計準備
    技術調査 リードエンジニア担当     :tech_research, 2024-01-16, 3d
    アーキテクチャ検討 リードエンジニア担当 :arch_study, after tech_research, 2d
    
    section マイルストーン
    週次目標達成 :milestone, week_goal, 2024-01-19, 1d
```

## 📝 タスク詳細情報

### 今週のタスク
- **要求収集・分析**: ステークホルダーへのヒアリング実施、要求の整理・分析
- **ステークホルダー確認**: 収集した要求の妥当性確認とフィードバック収集
- **技術調査**: システム実現のための技術要素の調査・比較検討
- **アーキテクチャ検討**: システム全体構成とアーキテクチャの方向性検討

### 来週の予定
- **要件定義書作成**: 分析結果をもとに要件定義書の作成開始
- **システム設計準備**: 基本設計に向けた準備作業

## 📋 タスク管理ルール

### 状態の定義
- `active`: 現在進行中のタスク
- `done`: 完了済みタスク
- `crit`: クリティカルパス上のタスク
- `milestone`: マイルストーン

### 更新手順
1. 毎日の進捗に合わせてタスクの状態を更新
2. 遅延が発生した場合は依存するタスクの日程も調整
3. 新しいタスクが追加される場合は適切なセクションに配置
4. 完了したタスクは`done`状態に変更

### 担当者表記
タスク名に担当者を必ず含めること: `[タスク名] (担当: [氏名])`

---
**最終更新**: 2024-01-15  
**更新者**: Project Manager
