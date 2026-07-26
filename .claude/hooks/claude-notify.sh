#!/usr/bin/env bash
# Claude Code Stop フック: 回答完了を OS 通知する（macOS / WSL+Windows / Linux 対応）
#
# 利用可能な通知バックエンドを順に試し、どれか 1 つ成功で終了する。
# Stop フックの stdin(JSON) から cwd を取り出し、ディレクトリ名を本文に添える（jq があれば）。

input="$(cat 2>/dev/null)"
dir=""
if command -v jq >/dev/null 2>&1; then
  dir="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)"
  [ -n "$dir" ] && dir="$(basename "$dir")"
fi

title="Claude Code"
msg="${dir:+$dir の}回答が完了しました"

# --- macOS ---
if [ "$(uname)" = "Darwin" ]; then
  osascript -e "display notification \"$msg\" with title \"$title\"" >/dev/null 2>&1
  exit 0
fi

# --- WSL（Windows 通知）---
if grep -qi microsoft /proc/version 2>/dev/null; then
  # WSLg の通知（libnotify-bin が必要）
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "$title" "$msg" && exit 0
  fi
  # wsl-notify-send（導入済みなら）
  if command -v wsl-notify-send.exe >/dev/null 2>&1; then
    wsl-notify-send.exe --category "$title" "$msg" && exit 0
  fi
  # PowerShell トースト（追加インストール不要。powershell.exe 経由の文字化けを避けるため本文は ASCII 固定）
  powershell.exe -NoProfile -NonInteractive -Command \
"\$ErrorActionPreference='SilentlyContinue';\
\$null=[Windows.UI.Notifications.ToastNotificationManager,Windows.UI.Notifications,ContentType=WindowsRuntime];\
\$t=[Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02);\
\$e=\$t.GetElementsByTagName('text');\
\$e.Item(0).AppendChild(\$t.CreateTextNode('Claude Code'))|Out-Null;\
\$e.Item(1).AppendChild(\$t.CreateTextNode('Response complete'))|Out-Null;\
\$n=[Windows.UI.Notifications.ToastNotification]::new(\$t);\
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe').Show(\$n)" \
    >/dev/null 2>&1
  exit 0
fi

# --- 通常の Linux ---
if command -v notify-send >/dev/null 2>&1; then
  notify-send "$title" "$msg"
fi
exit 0
