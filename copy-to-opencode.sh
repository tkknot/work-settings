#!/bin/bash

# コピー先ディレクトリを作成
mkdir -p opencode/agents
mkdir -p opencode/commands
mkdir -p opencode/skills

# .cursor配下のファイルをopencode配下にコピー
cp -r .cursor/agents/* opencode/agents/
cp -r .cursor/commands/* opencode/commands/
cp -r .cursor/skills/* opencode/skills/
cp .cursor/playwright-config.json opencode/playwright-config.json

# AGENTS.mdをopencode配下にコピー
cp AGENTS.md opencode/AGENTS.md

# opencodeを.opencodeにコピー
cp -r opencode .opencode

echo "コピー完了"
