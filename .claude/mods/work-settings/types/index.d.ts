// work-settings mod の $.state 契約。hooks/*.ts はここから型を import する。

export type BranchInfo = {
  /** ブランチ名。detached HEAD は `(detached <sha>)` */
  branch: string
  /** 比較対象の default ブランチ（`origin/master` など）。特定できなければ無し */
  defaultRef?: string
  ahead?: number
  behind?: number
  /** `git status --porcelain` の行数 */
  dirty: number
}

export type SkillEntry = {
  name: string
  description: string
  /** `{prefix}--{name}` の prefix。prefix 無しは `other` */
  group: string
}

export type AgentRow = {
  id: string
  type: string
  description: string
  startedAt: number
  status: 'running' | 'completed' | 'aborted'
  durationMs?: number
}

declare module 'claude-code' {
  interface PluginState {
    'work-settings': {
      nudged: boolean
      branch: BranchInfo | null
      skills: SkillEntry[]
      agents: AgentRow[]
    }
  }
}
