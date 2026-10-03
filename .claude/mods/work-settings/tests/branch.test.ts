import { describe, expect, test } from 'claude-code/testing'
import type { On, RenderElement } from 'claude-code'

import { parseCounts, readBranch } from '../hooks/branch'

// git のサブコマンド（先頭2語）ごとの応答
type Answers = Record<string, { exitCode?: number; stdout?: string }>

const REPO: Answers = {
  'rev-parse --is-inside-work-tree': { stdout: 'true\n' },
  'symbolic-ref --short': { stdout: 'feature/x\n' },
  'status --porcelain': { stdout: ' M a.txt\n?? b.txt\n' },
  'show-ref --verify': { exitCode: 0 },
  'rev-list --left-right': { stdout: '3\t2\n' },
}

function answer(answers: Answers, args: readonly string[]) {
  // symbolic-ref は HEAD と origin/HEAD の2種類。origin/HEAD は未設定扱い（main/master 推測へ）
  if (args[0] === 'symbolic-ref' && args[2] === 'refs/remotes/origin/HEAD') return { exitCode: 1, stdout: '' }
  if (args[0] === 'show-ref' && !String(args[3]).endsWith('origin/master')) return { exitCode: 1, stdout: '' }
  const a = answers[args.slice(0, 2).join(' ')] ?? { exitCode: 1 }
  return { exitCode: a.exitCode ?? 0, stdout: a.stdout ?? '' }
}

function stubGit(on: On, answers: Answers): void {
  on('process.run', (_$, e) => {
    const a = answer(answers, e.argv.slice(1))
    return { value: { ...a, stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }
  })
  on('session.start', (_$, e) => ({ cwd: e.cwd }))
  on('command.register', (_$, e) => ({ value: { command: e.name } }))
  on('ui.log', () => ({ value: undefined }))
  // engine 自身の描画の代わり（plugin が next(e) したときに描かれるもの）
  on('ui.render', ($, e) => {
    const { Box } = $.ui.resolve(e)
    return h(Box, { key: 'engine' }) as RenderElement
  })
}

const BAND = {
  component: 'AbovePrompt',
  props: {
    hasSurvey: false,
    isWorking: false,
    maxRows: 3,
    bodyColumns: 100,
    scroll: { offset: 0, bodyRows: 1 },
    view: {},
  },
} as const

describe('readBranch', () => {
  test('ブランチ・未コミット件数・default との差を読む', async () => {
    const info = await readBranch(async args => answer(REPO, args))
    expect(info).toEqual({ branch: 'feature/x', dirty: 2, defaultRef: 'origin/master', behind: 3, ahead: 2 })
  })

  test('git 管理外なら null', async () => {
    expect(await readBranch(async () => ({ exitCode: 128, stdout: '' }))).toBeNull()
  })

  test('parseCounts は behind / ahead の順', () => {
    expect(parseCounts('5\t1\n')).toEqual({ behind: 5, ahead: 1 })
    expect(parseCounts('')).toBeUndefined()
  })
})

describe('ブランチバンド', () => {
  test('セッション開始後にバンドへ表示する（terminal / desktop）', async ($, on) => {
    stubGit(on, REPO)
    await $.session.start({ cwd: '/repo', surface: 'terminal', isInteractive: true })

    for (const surface of ['terminal', 'desktop'] as const) {
      const ui = await $.ui.mount({ plugin: 'work-settings', surface, ...BAND })
      // refresh は待たずに走るので、描画に反映されるまで数回描き直す
      for (let i = 0; i < 20 && !(await ui.find({ text: /feature\/x/ })); i++) await ui.redraw()
      expect((await ui.find({ text: /⎇ feature\/x/ }))?.text).toContain('↓3')
      expect(await ui.find({ text: /●2 未コミット/ })).toBeDefined()
      await ui.unmount()
    }
  })

  test('git 管理外では何も描かない', async ($, on) => {
    stubGit(on, {})
    await $.session.start({ cwd: '/tmp', surface: 'terminal', isInteractive: true })
    const ui = await $.ui.mount({ plugin: 'work-settings', surface: 'terminal', ...BAND })
    for (let i = 0; i < 5; i++) await ui.redraw()
    expect(await ui.find({ text: /⎇/ })).toBeUndefined()
    await ui.unmount()
  })
})
