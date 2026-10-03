// 機能1: context 使用量の通知（旧 context-nudge.sh / usage-report.sh / state-prune.sh の置き換え）
//
// 旧構成は context_window と rate_limits が statusLine の payload にしか無かったため、
// statusline.sh が XDG state へ書き出し、各 hook がそれを読む2段構えだった。mod は
// $.session.usage() で直接読めるので state ファイルも掃除も要らない。
// $ を使う処理は register.ts（validator が $ を import 越しに渡すのを許さないため）。
import type { SessionRateLimit } from 'claude-code'

export const DEFAULT_NUDGE_PCT = 70

export function nudgeText(pct: number, threshold: number): string {
  return [
    '## context 使用量の通知（work-settings mod）',
    '',
    `コンテキストウィンドウの使用率が ${pct}% に達している（閾値 ${threshold}%）。`,
    '作業の区切りがついたタイミングで `/compact` を提案すること。自動 compact を待つと',
    '会話の途中で走り、文脈が落ちる可能性がある。',
  ].join('\n')
}

// 旧 usage-report.sh と同じ並び: ctx / 5h / 週 / cost。値の無いものは落とす
export function usageLine(
  pct: number | undefined,
  rateLimits: readonly SessionRateLimit[],
  usd: number | undefined,
): string | undefined {
  const parts: string[] = []
  if (pct !== undefined) parts.push(`ctx ${Math.round(pct)}%`)
  const h5 = rateLimits.find(r => r.kind === 'five_hour')
  const d7 = rateLimits.find(r => r.kind === 'seven_day')
  if (h5) parts.push(`5h ${Math.round(h5.percentUsed)}%`)
  if (d7) parts.push(`週 ${Math.round(d7.percentUsed)}%`)
  if (usd !== undefined) parts.push(`$${usd.toFixed(2)}`)
  return parts.length > 0 ? parts.join(' | ') : undefined
}
