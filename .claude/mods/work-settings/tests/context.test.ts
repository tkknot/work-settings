import { describe, expect, test } from 'claude-code/testing'
import type { On } from 'claude-code'

import { nudgeText, usageLine } from '../hooks/context'

// session.usage / prompt.submit の bottom をテストが受け持つ。
// prompt.submit の bottom には plugin が付けた context（モデルだけが読むブロック）が届くので、それを記録する。
function stub(on: On, usage: { pct: number | undefined }, nudges: string[], logs: string[] = []): void {
  on('session.usage', () => ({
    value: {
      startedAt: 0,
      context: { window: 200000, percent: usage.pct },
      rateLimits: [
        { kind: 'five_hour', percentUsed: 10.4 },
        { kind: 'seven_day', percentUsed: 20 },
      ],
      cost: { usd: 1.234 },
    },
  }))
  on('ui.log', (_$, e) => {
    if (e.to !== 'debug') logs.push(e.text)
    return { value: undefined }
  })
  on('prompt.submit', (_$, e) => {
    nudges.push(...(e.context ?? []))
    return { text: e.text, context: e.context }
  })
}

const prompt = (text: string) => ({ text, wait: false, origin: { kind: 'composer' as const } })

describe('context 通知', () => {
  test('閾値を超えた最初の1回だけ伝え、下回ったら再び伝えられる', async ($, on) => {
    const usage = { pct: 80 as number | undefined }
    const nudges: string[] = []
    stub(on, usage, nudges)

    await $.prompt.submit(prompt('a'))
    await $.prompt.submit(prompt('b'))
    expect(nudges).toHaveLength(1)
    expect(nudges[0]).toContain('80%')
    expect(nudges[0]).toContain('閾値 70%')

    usage.pct = 40
    await $.prompt.submit(prompt('c'))
    expect(nudges).toHaveLength(1)

    usage.pct = 75
    await $.prompt.submit(prompt('d'))
    expect(nudges).toHaveLength(2)
  })

  test('閾値は userConfig で変えられる', { options: { contextNudgePct: 90 } }, async ($, on) => {
    const nudges: string[] = []
    stub(on, { pct: 85 }, nudges)
    await $.prompt.submit(prompt('a'))
    expect(nudges).toHaveLength(0)
  })

  test('percent が無い（初回応答前）なら何もしない', async ($, on) => {
    const nudges: string[] = []
    stub(on, { pct: undefined }, nudges)
    await $.prompt.submit(prompt('a'))
    expect(nudges).toHaveLength(0)
  })

  test('メインのターン終了で使用量を1行出す', async ($, on) => {
    const logs: string[] = []
    stub(on, { pct: 42 }, [], logs)
    on('process.run', () => ({
      value: { exitCode: 128, stdout: '', stderr: '', isStdoutTruncated: false, isStderrTruncated: false },
    }))
    on('turn.complete', (_$, e) => ({ text: e.answer }))

    await $.turn.complete({ answer: '', durationMs: 1, isAborted: false, turnId: 't1', reason: 'answer' })
    expect(logs).toEqual(['ctx 42% | 5h 10% | 週 20% | $1.23'])
  })

  test('サブエージェントのターン終了では出さない', async ($, on) => {
    const logs: string[] = []
    stub(on, { pct: 42 }, [], logs)
    on('turn.complete', (_$, e) => ({ text: e.answer }))

    await $.turn.complete({
      answer: '',
      durationMs: 1,
      isAborted: false,
      turnId: 't1',
      reason: 'answer',
      agentId: 'a1',
    })
    expect(logs).toEqual([])
  })
})

describe('純粋関数', () => {
  test('usageLine は値の無い項目を落とす', () => {
    expect(usageLine(undefined, [], undefined)).toBeUndefined()
    expect(usageLine(12.6, [], undefined)).toBe('ctx 13%')
  })

  test('nudgeText は使用率・閾値・/compact の提案を含む', () => {
    const text = nudgeText(80, 70)
    expect(text).toContain('80%')
    expect(text).toContain('閾値 70%')
    expect(text).toContain('/compact')
  })
})
