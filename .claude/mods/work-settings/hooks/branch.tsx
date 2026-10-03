// 機能2: プロンプト上のバンドに git ブランチ状態を常時表示する。
//
// default ブランチの判定と ahead/behind の数え方は .claude/hooks/git-branch-report.sh と同じ。
// fetch はしない（SessionStart の git-branch-report.sh が担当し、ここは手元の refs を読むだけ）。
// 更新（$.process.run で git を叩く）は register.ts が session.start / turn.complete / Bash 後に行う。
import { atom, read } from 'claude-code'
import type { On } from 'claude-code'

import type { BranchInfo } from '../types'

const branch = atom({ plugin: 'work-settings', key: 'branch' } as const, null)

export type Git = (args: string[]) => Promise<{ exitCode: number; stdout: string }>

// `git rev-list --left-right --count <default>...HEAD` の出力 "behind\tahead"
export function parseCounts(stdout: string): { behind: number; ahead: number } | undefined {
  const m = stdout.trim().match(/^(\d+)\s+(\d+)$/)
  return m ? { behind: Number(m[1]), ahead: Number(m[2]) } : undefined
}

export async function readBranch(git: Git): Promise<BranchInfo | null> {
  const inside = await git(['rev-parse', '--is-inside-work-tree'])
  if (inside.exitCode !== 0) return null

  let name = (await git(['symbolic-ref', '--short', 'HEAD'])).stdout.trim()
  if (!name) {
    const sha = (await git(['rev-parse', '--short', 'HEAD'])).stdout.trim()
    name = `(detached ${sha})`
  }

  const status = await git(['status', '--porcelain'])
  const dirty = status.stdout.split('\n').filter(line => line.trim() !== '').length

  // origin/HEAD があればそれが正。無ければ main/master の実在で推測する
  let defaultRef = (await git(['symbolic-ref', '--short', 'refs/remotes/origin/HEAD'])).stdout.trim()
  if (!defaultRef) {
    for (const cand of ['origin/main', 'origin/master']) {
      if ((await git(['show-ref', '--verify', '--quiet', `refs/remotes/${cand}`])).exitCode === 0) {
        defaultRef = cand
        break
      }
    }
  }
  if (!defaultRef) return { branch: name, dirty }

  const counts = parseCounts((await git(['rev-list', '--left-right', '--count', `${defaultRef}...HEAD`])).stdout)

  return { branch: name, dirty, defaultRef, ...counts }
}

export function installBranch(on: On): void {
  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const info = await read($, branch)
    if (e.props.hasSurvey || info === null) return next(e)

    const { Box, Text } = $.ui.resolve(e)
    const isBehind = (info.behind ?? 0) > 0

    return (
      <Box>
        <Text wrap="truncate">
          <Text color="cyan">⎇ {info.branch}</Text>
          {info.defaultRef !== undefined && info.ahead !== undefined && (
            <Text>
              {'  '}↑{info.ahead} <Text color={isBehind ? 'yellow' : undefined}>↓{info.behind}</Text>
              <Text dimColor> vs {info.defaultRef}</Text>
            </Text>
          )}
          {info.dirty > 0 ? (
            <Text color="yellow">
              {'  '}●{info.dirty} 未コミット
            </Text>
          ) : (
            <Text dimColor>{'  '}✓ clean</Text>
          )}
        </Text>
      </Box>
    )
  })
}
