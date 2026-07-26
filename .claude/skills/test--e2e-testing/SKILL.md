---
name: e2e-testing
description: E2E（エンドツーエンド）テストの実行・作成・トラブルシューティングのスキル
---

# E2Eテストスキル

Playwright/Cypressなどを使用したE2Eテストの実行と作成のスキルです。

## テスト実行コマンド

### Playwright

```bash
# 全テスト実行
npx playwright test

# 特定ファイル
npx playwright test tests/login.spec.ts

# ブラウザ表示（headed）
npx playwright test --headed

# 特定ブラウザ
npx playwright test --project=chromium

# デバッグモード
npx playwright test --debug

# UIモード
npx playwright test --ui

# レポート表示
npx playwright show-report
```

### Cypress

```bash
# GUIモード
npx cypress open

# ヘッドレス（CI向け）
npx cypress run

# 特定ファイル
npx cypress run --spec "cypress/e2e/login.cy.ts"

# 特定ブラウザ
npx cypress run --browser chrome
```

## テスト実行前チェック

```markdown
□ 開発サーバーが起動している
□ テストDBがリセットされている
□ 環境変数が設定されている
□ テストユーザーが準備されている
```

```bash
# サーバー起動確認
lsof -i :3000

# 環境変数確認
echo $BASE_URL
```

## ページオブジェクトモデル（POM）

```typescript
// pages/LoginPage.ts
export class LoginPage {
  constructor(private page: Page) {}
  
  async goto() {
    await this.page.goto('/login');
  }
  
  async login(email: string, password: string) {
    await this.page.fill('[data-testid="email"]', email);
    await this.page.fill('[data-testid="password"]', password);
    await this.page.click('[data-testid="login-button"]');
  }
}

// tests/login.spec.ts
test('ログイン成功', async ({ page }) => {
  const loginPage = new LoginPage(page);
  await loginPage.goto();
  await loginPage.login('user@example.com', 'password');
  await expect(page).toHaveURL('/dashboard');
});
```

## セレクタのベストプラクティス

| 種別 | 推奨度 | 例 |
|------|-------|-----|
| data-testid | ⭐⭐⭐ | `[data-testid="submit"]` |
| Role | ⭐⭐⭐ | `getByRole('button')` |
| Text | ⭐⭐ | `getByText('送信')` |
| CSS class | ⭐ | `.submit-btn`（脆弱） |

## トラブルシューティング

| 問題 | 原因 | 解決策 |
|------|------|--------|
| タイムアウト | 要素が見つからない | 待機時間増加 / セレクタ確認 |
| クリック失敗 | 要素が隠れている | `force: true` / スクロール |
| フレーキー | 非同期処理競合 | 適切な待機処理 |

## CI/CD統合（GitHub Actions）

```yaml
- name: Install Playwright
  run: npx playwright install --with-deps

- name: Start server
  run: npm run dev &

- name: Wait for server
  run: npx wait-on http://localhost:3000

- name: Run E2E tests
  run: npx playwright test
```

## ベストプラクティス

### やるべきこと
- `data-testid`属性を使用
- 明示的な待機処理
- 独立したテスト
- 並列実行の活用

### 避けるべきこと
- ハードコードされたsleep
- 脆弱なCSSセレクタ
- テスト間の依存
- 本番環境での実行
