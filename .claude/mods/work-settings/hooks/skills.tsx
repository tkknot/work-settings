// 機能3: /skill-pane でスキル一覧をカテゴリ（`{prefix}--`）別にペイン表示する。
//
// meta--skill-catalog スキルと違い、Claude を介さず SKILL.md の frontmatter を直接読むので
// トークンを使わない。ボタンを押すと `/<name> ` をプロンプトへ入れる。
// 組み込みの /skills と衝突しないよう名前は skill-pane にしている。
import { atom, read, update } from 'claude-code'
import type { EngineInterface, On } from 'claude-code'

import type { SkillEntry } from '../types'

export const SKILL_PANE = 'skill-pane'
const PANE = SKILL_PANE
const skills = atom({ plugin: 'work-settings', key: 'skills' } as const, [])

export function parseFrontmatter(text: string): { name?: string; description?: string } {
  const m = text.match(/^---\r?\n([\s\S]*?)\r?\n---/)
  if (!m) return {}
  const out: { name?: string; description?: string } = {}
  for (const line of m[1]!.split(/\r?\n/)) {
    const kv = line.match(/^(name|description):\s*(.*)$/)
    if (kv) out[kv[1] as 'name' | 'description'] = kv[2]!.trim().replace(/^(['"])(.*)\1$/, '$2')
  }
  return out
}

export function groupOf(name: string): string {
  const i = name.indexOf('--')
  return i > 0 ? name.slice(0, i) : 'other'
}

// グループ名順、グループ内はスキル名順
export function groupSkills(list: readonly SkillEntry[]): [string, SkillEntry[]][] {
  const groups = new Map<string, SkillEntry[]>()
  for (const s of list) groups.set(s.group, [...(groups.get(s.group) ?? []), s])
  return [...groups.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([g, ss]) => [g, [...ss].sort((a, b) => a.name.localeCompare(b.name))])
}

async function loadSkills($: EngineInterface): Promise<SkillEntry[]> {
  const home = await $.env.get('HOME')
  const cwd = await $.session.cwd()
  const roots = [`${cwd}/.claude/skills`, ...(home ? [`${home}/.claude/skills`] : [])]
  const found = new Map<string, SkillEntry>()

  for (const root of roots) {
    if (!(await $.fs.exists(root))) continue
    for (const entry of await $.fs.list(root)) {
      if (entry.kind === 'file') continue
      const file = `${root}/${entry.name}/SKILL.md`
      if (!(await $.fs.exists(file))) continue
      const text = await $.fs.read(file)
      const fm = parseFrontmatter(typeof text === 'string' ? text : '')
      const name = fm.name ?? entry.name
      // プロジェクトのスキルを優先（roots の先頭）
      if (!found.has(name)) found.set(name, { name, description: fm.description ?? '', group: groupOf(name) })
    }
  }

  return [...found.values()]
}

export function installSkills(on: On): void {
  on('command.run', { command: PANE }, async $ => {
    const list = await loadSkills($)
    await update($, skills, () => list)
    await $.ui.open({ id: PANE, title: `Skills (${list.length})`, closeOnEscape: true })

    return { text: `スキル ${list.length} 件をペインに表示しました。` }
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Button, Text } = $.ui.resolve(e)
    const list = await read($, skills)
    const width = Math.max(20, e.props.bodyColumns)

    if (list.length === 0) return <Text dimColor>スキルが見つかりません。</Text>

    return (
      <Box flexDirection="column">
        {groupSkills(list).map(([group, ss]) => (
          <Box key={`g:${group}`} flexDirection="column" marginBottom={1}>
            <Text bold color="cyan">
              {group}
            </Text>
            {ss.map(s => (
              <Box key={`s:${s.name}`} flexDirection="column" width={width}>
                <Button
                  key={`skill:${s.name}`}
                  plain
                  label={`/${s.name}`}
                  onPress={() => $.prompt.fill({ text: `/${s.name} `, mode: 'replace' })}
                />
                <Text dimColor wrap="truncate">
                  {' '}
                  {s.description}
                </Text>
              </Box>
            ))}
          </Box>
        ))}
      </Box>
    )
  })
}
