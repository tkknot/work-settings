#!/bin/bash

# コピー先ディレクトリを作成
mkdir -p ai-setting-base/agents
mkdir -p ai-setting-base/commands
mkdir -p ai-setting-base/skills

# .cursor配下のファイルをai-setting-base配下にコピー
cp -r .cursor/agents/* ai-setting-base/agents/
cp -r .cursor/commands/* ai-setting-base/commands/
cp -r .cursor/skills/* ai-setting-base/skills/
cp .cursor/playwright-config.json ai-setting-base/playwright-config.json

# AGENTS.mdをai-setting-base配下にコピー
cp AGENTS.md ai-setting-base/AGENTS.md

# ai-setting-baseを.ai-setting-baseにコピー
cp -r ai-setting-base .ai-setting-base

echo "コピー完了"