local wezterm = require("wezterm")
local config = {}

-- 最新のWezTermではconfig_builderを使うのが推奨されています
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- --- 外観の設定 ---
-- カラースキーム（Tokyo Night）
config.color_scheme = "Tokyo Night"
-- フォントの設定（Hack Nerd Font をベースに、日本語フォントをフォールバックに指定）
config.font = wezterm.font_with_fallback({
	{ family = "Hack Nerd Font" },
	{ family = "Hiragino Sans", weight = "Regular" },
	{ family = "Hiragino Kaku Gothic ProN", weight = "Regular" },
	{ family = "Meiryo" },
})
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
	-- フォントサイズを大きくする
	config.font_size = 16.0
end

-- --- パフォーマンスと動作の設定 ---
-- フロントエンド（GPUを使用するWebGpuを設定）
config.front_end = "WebGpu"
-- スクロールバックの保持行数
config.scrollback_lines = 10000
-- 日本語入力（IME）を有効にする
config.use_ime = true

-- --- キーバインド設定 ---
config.keys = {
	{
		key = "E",
		mods = "CTRL|SHIFT",
		action = wezterm.action.PromptInputLine({
			description = "Enter new tab title",
			action = wezterm.action_callback(function(window, _, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},
}

-- Windows向けにCtrl+C/Ctrl+Vでコピー＆ペーストできるようにする
if wezterm.target_triple:find("windows") then
	-- Ctrl+C: 選択範囲があればコピー、なければCtrl+C（SIGINT）を送信する
	table.insert(config.keys, {
		key = "c",
		mods = "CTRL",
		action = wezterm.action_callback(function(window, pane)
			local has_selection = window:get_selection_text_for_pane(pane) ~= ""
			if has_selection then
				window:perform_action(wezterm.action.CopyTo("ClipboardAndPrimarySelection"), pane)
				window:perform_action(wezterm.action.ClearSelection, pane)
			else
				window:perform_action(wezterm.action.SendKey({ key = "c", mods = "CTRL" }), pane)
			end
		end),
	})
	-- Ctrl+V: クリップボードからペーストする
	table.insert(config.keys, {
		key = "v",
		mods = "CTRL",
		action = wezterm.action.PasteFrom("Clipboard"),
	})
end

-- macOS向けにCMD+Tも同様に設定
if wezterm.target_triple:find("darwin") then
	table.insert(config.keys, {
		key = "t",
		mods = "CMD",
		action = wezterm.action.PromptInputLine({
			description = "Enter new tab title",
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					local tab, _ = window:mux_window():spawn_tab({
						cwd = "~",
					})
					tab:set_title(line)
				end
			end),
		}),
	})
end

-- --- ペイン分割レイアウト ---
-- 数字キーは Shift 併用でシフト記号に化けるため、レイアウト非依存の phys: 表記で指定する
-- Ctrl+Shift+4 : 2x2 の田の字
table.insert(config.keys, {
	key = "phys:4",
	mods = "CTRL|SHIFT",
	action = wezterm.action_callback(function(_, pane)
		-- 右に分割して右ペインを取得 → 左右それぞれを下に分割し 2x2 を作る
		local right = pane:split({ direction = "Right", size = 0.5 })
		pane:split({ direction = "Bottom", size = 0.5 })
		right:split({ direction = "Bottom", size = 0.5 })
	end),
})
-- Ctrl+Shift+2 : 左右 2 分割（縦線）
table.insert(config.keys, {
	key = "phys:2",
	mods = "CTRL|SHIFT",
	action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
})
-- Ctrl+Shift+3 : 上下 2 分割（横線）
table.insert(config.keys, {
	key = "phys:3",
	mods = "CTRL|SHIFT",
	action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
})

-- --- イベントハンドラ ---
-- 設定がリロードされた時にログ（Ctrl+Shift+Lで表示）を出力する
wezterm.on("window-config-reloaded", function(window, _)
	wezterm.log_info("the config was reloaded for this window!")
end)

return config
