---
name: security--dependabot-workflow
description: Dependabotアラート対応の進め方ガイドとGitHub APIリファレンス
---

# Dependabotアラート対応ワークフロー

GitHub Dependabotセキュリティアラートの確認・分析・修正を行うためのワークフローガイドです。

## 人間 / AI 役割分担

| 役割 | 担当 |
|------|------|
| **対応する重要度の判断**: どのseverityまで対応するかを決定する | 人間 |
| **修正方針の承認**: メジャーバージョンアップ等のリスクを伴う修正を承認する | 人間 |
| **テスト実行の判断**: 修正後にどのテストを実行するかを決定する | 人間 |
| **アラート取得・集計**: GitHub APIからアラートを取得し重要度別に整理する | AI |
| **脆弱性の分析**: CVE/GHSA情報と利用箇所から実際のリスクを評価する | AI |
| **修正の実行**: パッケージのアップデートと動作確認を実施する | AI |
| **結果の報告**: 修正結果をまとめて報告する | AI |

---

## GitHub Dependabot API リファレンス

### エンドポイント一覧

| メソッド | エンドポイント | 説明 |
|---------|-------------|------|
| GET | `/repos/{owner}/{repo}/dependabot/alerts` | アラート一覧取得 |
| GET | `/repos/{owner}/{repo}/dependabot/alerts/{alert_number}` | 個別アラート取得 |
| PATCH | `/repos/{owner}/{repo}/dependabot/alerts/{alert_number}` | アラート更新 |

### アラート取得の例

```bash
# 全てのオープンアラートを取得
PAGER=cat gh api /repos/{owner}/{repo}/dependabot/alerts?state=open

# 重要度でフィルタ
PAGER=cat gh api "/repos/{owner}/{repo}/dependabot/alerts?state=open&severity=critical,high"

# エコシステムでフィルタ
PAGER=cat gh api "/repos/{owner}/{repo}/dependabot/alerts?state=open&ecosystem=npm"

# スコープでフィルタ（runtime/development）
PAGER=cat gh api "/repos/{owner}/{repo}/dependabot/alerts?state=open&scope=runtime"
```

### フィルタパラメータ

| パラメータ | 値 | 説明 |
|-----------|-----|------|
| `state` | open, dismissed, fixed, auto_dismissed | アラートの状態 |
| `severity` | critical, high, medium, low | 重要度 |
| `ecosystem` | npm, pip, maven, rubygems, composer, go, nuget, rust, pub | エコシステム |
| `scope` | development, runtime | 依存スコープ |
| `sort` | created, updated | ソート順 |
| `direction` | asc, desc | ソート方向 |

### レスポンスの主要フィールド

| フィールド | 説明 |
|-----------|------|
| `number` | アラート番号 |
| `state` | 状態（open/dismissed/fixed/auto_dismissed） |
| `dependency.package.name` | パッケージ名 |
| `dependency.package.ecosystem` | エコシステム（npm/pip/maven等） |
| `dependency.manifest_path` | マニフェストファイルのパス |
| `dependency.scope` | スコープ（development/runtime） |
| `security_advisory.ghsa_id` | GHSA ID |
| `security_advisory.cve_id` | CVE ID |
| `security_advisory.severity` | 重要度（critical/high/medium/low） |
| `security_advisory.summary` | 脆弱性の概要 |
| `security_advisory.description` | 脆弱性の詳細 |
| `security_vulnerability.vulnerable_version_range` | 脆弱なバージョン範囲 |
| `security_vulnerability.first_patched_version.identifier` | 修正バージョン |

### アラートの更新（dismiss等）

```bash
gh api --method PATCH /repos/{owner}/{repo}/dependabot/alerts/{alert_number} \
  -f state=dismissed \
  -f dismissed_reason=tolerable_risk \
  -f dismissed_comment="開発依存のみで本番影響なし"
```

| dismissed_reason | 意味 |
|-----------------|------|
| fix_started | 修正を開始済み |
| inaccurate | 誤検知 |
| no_bandwidth | 対応リソースなし |
| not_used | 脆弱な機能を使用していない |
| tolerable_risk | 許容可能なリスク |

---

## curlでの利用（gh CLIが使えない場合）

```bash
# GITHUB_TOKEN環境変数が必要
curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/{owner}/{repo}/dependabot/alerts?state=open
```

---

## パッケージマネージャー別の修正コマンド

| エコシステム | マニフェスト | 更新コマンド |
|------------|------------|-------------|
| npm | package.json | `npm update {package}` / `npm install {package}@{version}` |
| yarn | package.json | `yarn upgrade {package}@{version}` |
| pip | requirements.txt | `pip install {package}=={version}` → requirements.txt更新 |
| pipenv | Pipfile | `pipenv update {package}` |
| maven | pom.xml | pom.xmlのversion要素を手動更新 |
| go | go.mod | `go get {package}@v{version}` |
| bundler | Gemfile | `bundle update {package}` |
| composer | composer.json | `composer update {package}` |

---

## Step by Step ガイド

### Step 1: アラートの確認

**AIのタスク**: `/security--dependabot-fix-command` でアラートを取得・集計
```
例: 「このリポジトリのDependabotアラートを確認してください」
```

**出力**: 重要度別のアラート一覧表

---

### Step 2: 対応範囲の決定

**人間のタスク**: どの重要度まで対応するか判断

判断基準:
| 状況 | 推奨対応範囲 |
|------|------------|
| リリース前 | critical + high |
| 定期メンテナンス | critical + high + medium |
| セキュリティ監査対応 | すべて |
| 緊急対応 | critical のみ |

---

### Step 3: 脆弱性の分析と修正

**AIのタスク**: `security--dependabot-analyst` エージェントで各アラートを分析・修正

**人間のタスク**: メジャーバージョンアップ等のリスクがある修正を承認

---

### Step 4: テストと確認

**AIのタスク**: 修正結果を報告
**人間のタスク**: テスト実行・動作確認

---

## 関連ツール

| ツール | 用途 |
|--------|------|
| `/security--dependabot-fix-command` | Dependabotアラートの取得・集計・修正実行 |
| `security--dependabot-analyst` エージェント | 個別脆弱性の分析・修正方針提案 |
