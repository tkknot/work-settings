// 機能4: サブエージェントの起動と完了をペインに並べる。
//
// team--session / review--cross-review などの多エージェント運用で、今どれが走っているかを見る用途。
// 最初の spawn で自動で開く（unasked なので 144 桁以上の端末でのみ表示される）。
// 狭い端末では /agent-pane で開く。組み込みの /agents と衝突しないよう名前を分けている。
import { atom, read, update } from 'claude-code'
import type { On } from 'claude-code'

import type { AgentRow } from '../types'

export const AGENT_PANE = 'agent-pane'
const PANE = AGENT_PANE
const agents = atom({ plugin: 'work-settings', key: 'agents' } as const, [])

export function seconds(ms: number): string {
  const s = Math.round(ms / 1000)
  return s < 60 ? `${s}s` : `${Math.floor(s / 60)}m${String(s % 60).padStart(2, '0')}s`
}

export function clock(ms: number): string {
  const d = new Date(ms)
  return [d.getHours(), d.getMinutes(), d.getSeconds()].map(n => String(n).padStart(2, '0')).join(':')
}

const MARK: Record<AgentRow['status'], string> = { running: '●', completed: '✓', aborted: '✗' }
const COLOR: Record<AgentRow['status'], string | undefined> = {
  running: 'yellow',
  completed: 'green',
  aborted: 'red',
}

// モジュール変数なので reload で落ちるが、落ちても再度1回自動で開くだけで害は無い
let isAutoOpened = false

// サブエージェントのループは1回の実行が1ターン。その完了で done にする（呼び出しは register.ts）
export function markDone(list: readonly AgentRow[], id: string, isAborted: boolean, durationMs: number): AgentRow[] {
  return list.map(a =>
    a.id === id ? { ...a, status: isAborted ? ('aborted' as const) : ('completed' as const), durationMs } : a,
  )
}

export function installAgents(on: On): void {
  on('command.run', { command: PANE }, async $ => {
    await $.ui.open({ id: PANE, title: 'Agents' })
    return { text: 'エージェント監視ペインを開きました。' }
  })

  on('agent.spawn', async ($, e, next) => {
    const ran = await next(e)
    if (ran.agentId !== undefined) {
      const row: AgentRow = {
        id: ran.agentId,
        type: e.subagentType,
        description: e.description,
        startedAt: await $.clock.now(),
        status: 'running',
      }
      await update($, agents, list => [...list.filter(a => a.id !== row.id), row].slice(-50))
      if (!isAutoOpened) {
        isAutoOpened = true
        void $.ui.open({ id: PANE, title: 'Agents' })
      }
    }
    return ran
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Button, Text } = $.ui.resolve(e)
    const list = await read($, agents)
    const room = Math.max(1, (e.viewport?.rows ?? 24) - 6)
    const running = list.filter(a => a.status === 'running').length

    return (
      <Box flexDirection="column">
        <Box>
          <Text dimColor>
            実行中 {running} / 全 {list.length}{' '}
          </Text>
          {list.length > running && (
            <Button
              key="clear"
              label="完了分を消す"
              onPress={() => update($, agents, l => l.filter(a => a.status === 'running'))}
            />
          )}
        </Box>
        {list.length === 0 && <Text dimColor>まだサブエージェントは起動していません。</Text>}
        {list.slice(-room).map(a => (
          <Box key={`a:${a.id}`}>
            <Text wrap="truncate">
              <Text color={COLOR[a.status]}>{MARK[a.status]}</Text> <Text dimColor>{clock(a.startedAt)}</Text>{' '}
              <Text bold>{a.type}</Text> {a.description}
              {a.durationMs !== undefined && <Text dimColor> ({seconds(a.durationMs)})</Text>}
            </Text>
          </Box>
        ))}
      </Box>
    )
  })
}
