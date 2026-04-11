---
description: Dependabotアラートを取得し、指定した重要度の脆弱性を修正する
model: inherit
subtask: true
---

# Dependabotアラート対応コマンド

## 概要

リポジトリのDependabotセキュリティアラートを取得し、ユーザーが選択した重要度の脆弱性を修正します。

---

## Phase 1: 情報収集

1. `git remote get-url origin` でリポジトリのowner/repoを特定
2. Dependabotアラートを取得:
   ```bash
   # gh CLIが使える場合
   PAGER=cat gh api /repos/{owner}/{repo}/dependabot/alerts?state=open

   # gh CLIが使えない場合
   curl -L \
     -H "Accept: application/vnd.github+json" \
     -H "Authorization: Bearer $GITHUB_TOKEN" \
     -H "X-GitHub-Api-Version: 2022-11-28" \
     https://api.github.com/repos/{owner}/{repo}/dependabot/alerts?state=open
   ```
3. 取得したアラートを重要度別に集計・一覧表示:

```markdown
| 重要度 | 件数 | パッケージ例 |
|--------|------|-------------|
| 🔴 critical | X件 | package-name (CVE-XXXX-XXXX) |
| 🟠 high | X件 | ... |
| 🟡 medium | X件 | ... |
| 🔵 low | X件 | ... |
```

各アラートについて以下も表示:
- パッケージ名・エコシステム
- 脆弱なバージョン範囲
- 修正バージョン（first_patched_version）
- スコープ（runtime / development）

---

## Phase 2: 重要度の選択（ヒアリング）

ユーザーに対応する重要度を質問する:

> どの重要度のアラートに対応しますか？（複数選択可）
> 1. critical のみ
> 2. critical + high
> 3. critical + high + medium
> 4. すべて（low含む）
> 5. 個別選択（アラート番号指定）

**ユーザーの回答を待ってから Phase 3 に進む。**

---

## Phase 3: 脆弱性の分析と修正

選択された各アラートについて:

1. アラートの詳細を取得:
   ```bash
   PAGER=cat gh api /repos/{owner}/{repo}/dependabot/alerts/{alert_number}
   ```
2. 脆弱性情報を分析:
   - 影響を受けるパッケージとバージョン
   - 修正バージョン（first_patched_version）
   - 影響範囲（development / runtime）
   - CVE/GHSA情報
3. パッケージマネージャーを特定（manifest_path から判定）:

   | マニフェスト | エコシステム | 更新コマンド |
   |------------|------------|-------------|
   | `package.json` | npm | `npm update {pkg}` / `npm install {pkg}@{ver}` |
   | `package.json` (yarn) | yarn | `yarn upgrade {pkg}@{ver}` |
   | `requirements.txt` | pip | `pip install {pkg}=={ver}` → requirements.txt更新 |
   | `Pipfile` | pipenv | `pipenv update {pkg}` |
   | `pom.xml` | maven | pom.xmlのversion要素を手動更新 |
   | `go.mod` | go | `go get {pkg}@v{ver}` |
   | `Gemfile` | bundler | `bundle update {pkg}` |
   | `composer.json` | composer | `composer update {pkg}` |

4. 修正を実行:
   - パッチバージョンがある場合: パッケージを更新
   - パッチバージョンがない場合: ユーザーに代替案を提示（代替パッケージ、設定による緩和、dismiss等）
5. 修正後、テストが実行可能であれば実行して結果を確認

---

## Phase 4: 確認と報告

1. 修正結果をまとめて報告:

```markdown
| アラート | パッケージ | 修正前 | 修正後 | 状態 |
|---------|----------|--------|--------|------|
| #1 | lodash | 4.17.19 | 4.17.21 | ✅ 修正済 |
| #2 | express | 4.17.1 | - | ⚠️ パッチなし |
```

2. テスト実行を推奨（未実行の場合）
3. 修正をコミット・PRにするかユーザーに確認

---

## 注意事項

- `gh` CLIがインストールされ、認証済みである必要がある
- Dependabot Alertsが有効化されているリポジトリでのみ動作
- runtime依存とdevelopment依存で対応の緊急度が異なることをユーザーに伝える
- メジャーバージョンアップが必要な場合は、Breaking Changesの確認をユーザーに促す

---

## gh CLI が存在しない場合

- `which gh` の結果が空の場合、`curl` + `GITHUB_TOKEN` を使う
- `GITHUB_TOKEN` も未設定の場合は、設定方法を案内して中断する:
  ```
  export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
  ```
