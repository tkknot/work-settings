// work-settings の Claude Code mod（function hooks プラグイン）。
//
// 配布: sync_claude_settings.sh が ~/.claude/mods/work-settings へ同期し、settings.json の
// env.CLAUDE_CODE_PLUGIN_DIRS で読み込む。機能ごとにファイルを分け、ここで束ねる。
//
// ここに集めている理由（どちらも engine / validator の制約）:
// - 同じイベントを matcher なしで2度 on() できない。複数の機能が使う session.start /
//   prompt.submit / turn.complete はここで1本にまとめる。
// - $ は同じファイル内の関数にしか渡せない（import 越しは不可）。$ を使う共有処理はここに書き、
//   機能ファイルからは純粋関数と定数だけを import する。
// 機能固有のイベント（matcher 付きの ui.render など）は各機能の install*(on) が登録する。
import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register, TurnCompleteInput } from 'claude-code'

import { AGENT_PANE, installAgents, markDone } from './agents'
import { installBranch, readBranch } from './branch'
import { DEFAULT_NUDGE_PCT, nudgeText, usageLine } from './context'
import { installSkills, SKILL_PANE } from './skills'

// validator は state の参照元を「このファイルの const」でしか追えないため、機能ファイルと同じ
// ref（plugin + key が同じ＝同じ値）をここでも宣言する。型は types/index.d.ts の契約が揃える。
const nudged = atom({ plugin: 'work-settings', key: 'nudged' } as const, false)
const branch = atom({ plugin: 'work-settings', key: 'branch' } as const, null)
const agents = atom({ plugin: 'work-settings', key: 'agents' } as const, [])

// 1機能の失敗で他の機能やセッション本体を止めない。理由は debug log へ
function report($: EngineInterface, where: string, err: unknown): void {
  $.ui.log(`work-settings: ${where} で失敗: ${String(err)}`, { to: 'debug' })
}

// --- 機能1: context 通知 ---

// 閾値を跨いだ最初の1回だけ、Claude に伝える文面を返す。毎ターン書くとコンテキストを汚すため。
// 返した文面は prompt.submit の context（モデルだけが読むブロック）に載せる。旧 context-nudge.sh の
// UserPromptSubmit stdout 注入と同じ経路。
async function nudgeOnPrompt($: EngineInterface, threshold: number): Promise<string | undefined> {
  const { context } = await $.session.usage()
  const pct = context.percent
  if (pct === undefined) return undefined
  if (pct < threshold) {
    // /compact で下がったら再通知できるようフラグを落とす
    if (await read($, nudged)) await update($, nudged, () => false)
    return undefined
  }
  if (await read($, nudged)) return undefined
  await update($, nudged, () => true)
  return nudgeText(Math.round(pct), threshold)
}

// ターン終了時に使用量を transcript へ1行（dim・モデルには送られない）
async function logUsage($: EngineInterface): Promise<void> {
  const usage = await $.session.usage()
  const line = usageLine(usage.context.percent, usage.rateLimits, usage.cost?.usd)
  if (line) $.ui.log(line)
}

// --- 機能2: ブランチバンドの更新 ---

async function refreshBranch($: EngineInterface): Promise<void> {
  try {
    const info = await readBranch(async args => {
      const r = await $.process.run(['git', ...args], { timeoutMs: 5000 })
      return { exitCode: r.exitCode, stdout: r.stdout }
    })
    await update($, branch, () => info)
  } catch (err) {
    report($, 'branch.refresh', err)
  }
}

// --- 共有イベント ---

async function onSessionStart($: EngineInterface): Promise<void> {
  try {
    await $.command.register({ name: SKILL_PANE, description: 'スキル一覧をカテゴリ別にペインで表示する' })
    await $.command.register({ name: AGENT_PANE, description: 'サブエージェントの実行状況をペインで表示する' })
  } catch (err) {
    report($, 'command.register', err)
  }
  // git の読み取りは待たない（セッション開始を遅らせないため）
  void refreshBranch($)
}

async function onTurnComplete($: EngineInterface, e: TurnCompleteInput): Promise<void> {
  const id = e.agentId
  if (id !== undefined) {
    // サブエージェントのループは1回の実行が1ターン。その完了で done にする
    try {
      await update($, agents, list => markDone(list, id, e.isAborted, e.durationMs))
    } catch (err) {
      report($, 'agents.done', err)
    }
    return
  }
  try {
    await logUsage($)
  } catch (err) {
    report($, 'context.usage', err)
  }
  void refreshBranch($)
}

export const register: Register = (on, options) => {
  const raw = Number(options.contextNudgePct ?? DEFAULT_NUDGE_PCT)
  const threshold = Number.isFinite(raw) ? raw : DEFAULT_NUDGE_PCT

  on('session.start', async ($, e, next) => {
    await onSessionStart($)
    return next(e)
  })

  on('prompt.submit', async ($, e, next) => {
    let nudge: string | undefined
    try {
      nudge = await nudgeOnPrompt($, threshold)
    } catch (err) {
      report($, 'context.nudge', err)
    }
    return nudge === undefined ? next(e) : next({ ...e, context: [...(e.context ?? []), nudge] })
  })

  on('turn.complete', async ($, e, next) => {
    await onTurnComplete($, e)
    return next(e)
  })

  // checkout / commit / merge などは Bash 経由で起きるので、Bash の実行後にブランチを読み直す
  on('tool.call', { tool: 'Bash' }, async ($, e, next) => {
    const ran = await next(e)
    void refreshBranch($)
    return ran
  })

  installBranch(on)
  installSkills(on)
  installAgents(on)
}
