#!/bin/bash

# コピー先ディレクトリを作成
mkdir -p base/agents
mkdir -p base/commands
mkdir -p base/skills

# .cursor配下のファイルをbase配下にコピー
cp -r .cursor/agents/* base/agents/
cp -r .cursor/commands/* base/commands/
cp -r .cursor/skills/* base/skills/
cp .cursor/playwright-config.json base/playwright-config.json

# AGENTS.mdをbase配下にコピー
cp AGENTS.md base/AGENTS.md

# baseを.baseにコピー
cp -r base .base

echo "コピー完了"
