local wezterm = require("wezterm")
local config = {}

-- 最新のWezTermではconfig_builderを使うのが推奨されています
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- --- 外観の設定 ---
-- カラースキーム（Tokyo Night）
config.color_scheme = "Tokyo Night"
-- フォントの設定（Hack Nerd Font）
config.font = wezterm.font("Hack Nerd Font")
-- フォントサイズ
config.font_size = 12.0
-- 背景の不透明度（0.85 = 85%）
config.window_background_opacity = 0.85
-- ウィンドウ装飾（タイトルバーを消してリサイズのみ有効にする）
config.window_decorations = "RESIZE"

-- --- タブバーの配色 ---
config.colors = {
	tab_bar = {
		-- アクティブな（現在開いている）タブの色設定
		active_tab = {
			bg_color = "#7aa2f7", -- 背景色（明るい青）
			fg_color = "#1f2335", -- 文字色（濃い紺）
			intensity = "Bold", -- 太字
		},
	},
}

-- --- OS固有の設定 ---
if wezterm.target_triple:find("windows") then
	-- Windowsの場合：デフォルトでWSL2のUbuntu-24.04を起動する
	config.default_domain = "WSL:Ubuntu-24.04"
elseif wezterm.target_triple:find("darwin") then
	-- macOSの場合：背景のぼかし強度を設定
	config.macos_window_background_blur = 20
end

-- --- パフォーマンスと動作の設定 ---
-- フロントエンド（GPUを使用するWebGpuを設定）
config.front_end = "WebGpu"
-- スクロールバックの保持行数
config.scrollback_lines = 10000
-- 日本語入力（IME）を有効にする
config.use_ime = true
-- タブやウィンドウを閉じる際の確認をしない
config.window_close_confirmation = 'NeverPrompt'

-- --- キーバインド設定 ---
config.keys = {
  {
    key = 'E',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.PromptInputLine {
      description = 'Enter new tab title',
      action = wezterm.action_callback(function(window, _, line)
        if line then
          window:active_tab():set_title(line)
        end
      end),
    },
  },
}

-- --- イベントハンドラ ---
-- 設定がリロードされた時にログ（Ctrl+Shift+Lで表示）を出力する
wezterm.on("window-config-reloaded", function(window, _)
	wezterm.log_info("the config was reloaded for this window!")
end)

return config

