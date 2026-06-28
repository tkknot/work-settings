# WezTerm: シェルで `nvim` と打つと別タブで開く
#
# - WSL: `wezterm cli` は WSL から Windows 側 mux に到達できずハングするため使えない。
#   代わりに OSC 1337 SetUserVar を emit し、GUI 側(wezterm.lua の user-var-changed)に
#   新規タブでの nvim 起動を依頼する。
# - ネイティブ wezterm(mac/Linux): `wezterm cli spawn` が使えるので新規タブで開く。
# - wezterm 外 / 非 tty では通常の nvim にフォールバック。
# - `command nvim` で関数を迂回し実バイナリを呼ぶ。git commit 等の $EDITOR 起動は
#   非対話シェル経由でこの関数を通らないため従来どおり。

nvim() {
  if [ "${TERM_PROGRAM:-}" != "WezTerm" ] || [ ! -t 1 ]; then
    command nvim "$@"
    return
  fi

  if grep -qi microsoft /proc/version 2>/dev/null; then
    # WSL: OSC 1337 ユーザー変数で GUI 側にタブ起動を依頼する
    if command -v base64 >/dev/null 2>&1; then
      local nonce payload a b64
      nonce="$$-${RANDOM:-0}" # 同一値連投でもイベントが発火するよう nonce を付与
      payload="$nonce"$'\n'"$PWD"
      for a in "$@"; do
        payload="$payload"$'\n'"$a"
      done
      b64="$(printf '%s' "$payload" | base64 | tr -d '\n')"
      printf '\033]1337;SetUserVar=claude_open_nvim=%s\007' "$b64"
      return
    fi
  else
    # ネイティブ wezterm(mac/Linux): cli spawn で新規タブを開く
    if command -v wezterm >/dev/null 2>&1; then
      wezterm cli spawn --cwd "$PWD" -- nvim "$@" >/dev/null 2>&1 && return
    fi
  fi

  command nvim "$@" # フォールバック
}
