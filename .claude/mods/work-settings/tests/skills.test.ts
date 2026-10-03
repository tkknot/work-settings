import { describe, expect, test } from 'claude-code/testing'
import type { On } from 'claude-code'

import { groupOf, groupSkills, parseFrontmatter } from '../hooks/skills'

const SKILL = (name: string, description: string) => `---\nname: ${name}\ndescription: ${description}\n---\n\n# body\n`

// HOME=/home/u, cwd=/repo。プロジェクトと HOME に同名スキルがあればプロジェクトを優先する
const FILES: Record<string, string> = {
  '/repo/.claude/skills/git--branch-summary/SKILL.md': SKILL('git--branch-summary', 'ブランチ要約（project）'),
  '/home/u/.claude/skills/git--branch-summary/SKILL.md': SKILL('git--branch-summary', 'ブランチ要約（home）'),
  '/home/u/.claude/skills/review--cross-review/SKILL.md': SKILL('review--cross-review', '"反復クロスレビュー"'),
  '/home/u/.claude/skills/plain/SKILL.md': SKILL('plain', 'プレフィックス無し'),
}
const DIRS: Record<string, string[]> = {
  '/repo/.claude/skills': ['git--branch-summary'],
  '/home/u/.claude/skills': ['git--branch-summary', 'review--cross-review', 'plain', 'README.md'],
}

function stubFs(on: On, fills: string[]): void {
  on('env.get', (_$, e) => ({ value: e.name === 'HOME' ? '/home/u' : undefined }))
  on('session.cwd', () => ({ value: '/repo' }))
  on('fs.exists', (_$, e) => ({ value: e.path in FILES || e.path in DIRS }))
  on('fs.list', (_$, e) => ({
    value: (DIRS[e.path] ?? []).map(name => ({
      name,
      kind: name.endsWith('.md') ? ('file' as const) : ('dir' as const),
      size: 0,
      mtimeMs: 0,
      isLink: false,
    })),
  }))
  on('fs.read', (_$, e) => ({ value: FILES[e.path] ?? '' }))
  on('ui.open', () => ({ value: { isPlaced: true as const } }))
  on('prompt.fill', (_$, e) => {
    fills.push(e.text)
    return { isFilled: true }
  })
}

const PANE = {
  component: 'Pane',
  requestId: 'skill-pane',
  props: {
    title: 'Skills',
    isFocused: true,
    bodyColumns: 80,
    placement: 'dock',
    scroll: { offset: 0, bodyRows: 30 },
    view: {},
  },
} as const

describe('frontmatter とグループ化', () => {
  test('name / description を取り出し、引用符を外す', () => {
    expect(parseFrontmatter(SKILL('a--b', '"説明"'))).toEqual({ name: 'a--b', description: '説明' })
    expect(parseFrontmatter('no frontmatter')).toEqual({})
  })

  test('prefix でグループ化し、名前順に並べる', () => {
    expect(groupOf('git--x')).toBe('git')
    expect(groupOf('plain')).toBe('other')
    const grouped = groupSkills([
      { name: 'git--b', description: '', group: 'git' },
      { name: 'arch--a', description: '', group: 'arch' },
      { name: 'git--a', description: '', group: 'git' },
    ])
    expect(grouped.map(([g, ss]) => [g, ss.map(s => s.name)])).toEqual([
      ['arch', ['arch--a']],
      ['git', ['git--a', 'git--b']],
    ])
  })
})

describe('/skill-pane', () => {
  test('一覧をペインに描き、押すとプロンプトへ入れる', async ($, on) => {
    const fills: string[] = []
    stubFs(on, fills)

    const ran = await $.command.run({
      command: 'skill-pane',
      args: '',
      origin: { kind: 'composer' },
      presentation: { isFullscreen: true, columns: 160 },
    })
    expect(ran.text).toContain('3 件')

    for (const surface of ['terminal', 'desktop'] as const) {
      const ui = await $.ui.mount({ plugin: 'work-settings', surface, ...PANE })
      expect(await ui.find({ type: 'Text', text: 'ブランチ要約（project）' })).toBeDefined()
      expect(await ui.find({ type: 'Text', text: 'ブランチ要約（home）' })).toBeUndefined()
      expect(await ui.find({ type: 'Text', text: '反復クロスレビュー' })).toBeDefined()
      expect(await ui.find({ type: 'Text', text: 'other' })).toBeDefined()
      await ui.press({ key: 'skill:review--cross-review' })
      await ui.unmount()
    }
    expect(fills).toEqual(['/review--cross-review ', '/review--cross-review '])
  })
})
