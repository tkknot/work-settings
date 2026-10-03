import { describe, expect, test } from 'claude-code/testing'
import type { On } from 'claude-code'

import { markDone, seconds } from '../hooks/agents'

function stub(on: On, opened: string[]): void {
  let n = 0
  on('agent.spawn', () => ({ model: 'sonnet', agentId: `a${++n}` }))
  on('clock.now', () => ({ value: 0 }))
  on('ui.open', (_$, e) => {
    opened.push(e.id)
    return { value: { isPlaced: true as const } }
  })
  on('turn.complete', (_$, e) => ({ text: e.answer }))
  on('session.usage', () => ({ value: { startedAt: 0, context: { window: 1 }, rateLimits: [] } }))
  on('ui.log', () => ({ value: undefined }))
}

const spawn = (description: string, subagentType: string) => ({
  tool_use_id: `t-${description}`,
  prompt: description,
  description,
  subagentType,
  provider: { plugin: 'engine', tier: 'core' as const },
  parentModel: 'opus',
  background: true,
  fork: false,
})

const command = (name: string) => ({
  command: name,
  args: '',
  origin: { kind: 'composer' as const },
  presentation: { isFullscreen: true, columns: 160 },
})

const PANE = {
  component: 'Pane',
  requestId: 'agent-pane',
  props: {
    title: 'Agents',
    isFocused: false,
    bodyColumns: 80,
    placement: 'dock',
    scroll: { offset: 0, bodyRows: 20 },
    view: {},
  },
} as const

describe('純粋関数', () => {
  test('seconds は分を跨ぐと m/s 表記', () => {
    expect(seconds(4_400)).toBe('4s')
    expect(seconds(125_000)).toBe('2m05s')
  })

  test('markDone は該当 id だけを完了にする', () => {
    const rows = markDone(
      [
        { id: 'a', type: 'Explore', description: 'x', startedAt: 0, status: 'running' },
        { id: 'b', type: 'Explore', description: 'y', startedAt: 0, status: 'running' },
      ],
      'b',
      true,
      3000,
    )
    expect(rows.map(r => r.status)).toEqual(['running', 'aborted'])
    expect(rows[1]?.durationMs).toBe(3000)
  })
})

describe('エージェント監視ペイン', () => {
  test('spawn で自動で開き、完了を反映し、完了分を消せる', async ($, on) => {
    const opened: string[] = []
    stub(on, opened)

    await $.agent.spawn(spawn('調査', 'Explore'))
    await $.agent.spawn(spawn('レビュー', 'general-purpose'))
    expect(opened).toEqual(['agent-pane'])

    await $.turn.complete({
      answer: '',
      durationMs: 65_000,
      isAborted: false,
      turnId: 't',
      reason: 'answer',
      agentId: 'a1',
    })

    for (const surface of ['terminal', 'desktop'] as const) {
      const ui = await $.ui.mount({ plugin: 'work-settings', surface, ...PANE })
      expect(await ui.find({ type: 'Text', text: /実行中 1 \/ 全 2/ })).toBeDefined()
      expect(await ui.find({ type: 'Text', text: /✓.*Explore.*調査.*1m05s/ })).toBeDefined()
      expect(await ui.find({ type: 'Text', text: /●.*general-purpose.*レビュー/ })).toBeDefined()
      await ui.unmount()
    }

    const ui = await $.ui.mount({ plugin: 'work-settings', surface: 'terminal', ...PANE })
    await ui.press({ key: 'clear' })
    expect(await ui.find({ type: 'Text', text: /実行中 1 \/ 全 1/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /調査/ })).toBeUndefined()
    await ui.unmount()
  })

  test('/agent-pane で開く', async ($, on) => {
    const opened: string[] = []
    stub(on, opened)
    const ran = await $.command.run(command('agent-pane'))
    expect(ran.text).toContain('開きました')
    expect(opened).toEqual(['agent-pane'])
  })
})
