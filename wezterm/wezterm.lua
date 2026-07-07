local wezterm = require("wezterm")
local act = wezterm.action
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
-- 背景色オーバーライド（set_config_overrides）は config.colors を丸ごと置き換えるため、
-- オーバーライド側からも参照できるよう local に切り出しておく
local tab_bar_colors = {
	-- アクティブな（現在開いている）タブの色設定
	active_tab = {
		bg_color = "#7aa2f7", -- 背景色（明るい青）
		fg_color = "#1f2335", -- 文字色（濃い紺）
		intensity = "Bold", -- 太字
	},
}
config.colors = {
	tab_bar = tab_bar_colors,
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
-- リーダーキー（Ctrl+b）。LEADER を前置するキーバインドで使用する
config.leader = { key = "b", mods = "CTRL", timeout_milliseconds = 1000 }

-- ※ Ctrl+Shift+E（タブ名変更）は prompt_tab_color 定義後に追加する
config.keys = {}

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

-- --- ペイン分割レイアウト ---
-- 数字キーは Shift 併用でシフト記号に化けるため、レイアウト非依存の phys: 表記で指定する
-- WSL(Windows) では分割時に cwd が /mnt/c/... へフォールバックするため、WSL ホームを明示する
-- （cwd 文字列は ~ 展開非対応／wezterm.home_dir は Windows ホームを指すためハードコードする）
-- 他プラットフォームでは nil とし、従来どおり cwd を継承させる
local split_cwd = nil
if wezterm.target_triple:find("windows") then
	split_cwd = "/home/kazuki"
end

-- Ctrl+Shift+2 : 左右 2 分割（縦線）
table.insert(config.keys, {
	key = "phys:2",
	mods = "CTRL|SHIFT",
	action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain", cwd = split_cwd }),
})
-- Ctrl+Shift+3 : 上下 2 分割（横線）
table.insert(config.keys, {
	key = "phys:3",
	mods = "CTRL|SHIFT",
	action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain", cwd = split_cwd }),
})

-- --- 新規タブ（名前入力 → 色選択） ---
-- 白文字に映える濃色パレット。id に背景色の hex を持たせる
local tab_color_choices = {
	{ id = "#3d59a1", label = "ブルー" },
	{ id = "#7847bd", label = "パープル" },
	{ id = "#1a7a6e", label = "ティール" },
	{ id = "#2e7d32", label = "グリーン" },
	{ id = "#c62828", label = "レッド" },
	{ id = "#d84315", label = "オレンジ" },
	{ id = "#ad1457", label = "マゼンタ" },
	{ id = "#546e7a", label = "グレー" },
}

-- タブごとの色は tab_id をキーに wezterm.GLOBAL へ保存する（設定リロード後も保持される）
local function set_tab_color(tab_id, color)
	local colors = wezterm.GLOBAL.tab_colors or {}
	colors[tostring(tab_id)] = color
	wezterm.GLOBAL.tab_colors = colors
end

local function prompt_tab_color(window, pane)
	window:perform_action(
		act.InputSelector({
			title = "タブの色を選択（Esc でデフォルト）",
			choices = tab_color_choices,
			action = wezterm.action_callback(function(win, _, id, _)
				-- Esc でキャンセルした場合 id は nil → デフォルト色のまま
				if id then
					set_tab_color(win:active_tab():tab_id(), id)
				end
			end),
		}),
		pane
	)
end

-- Ctrl+Shift+E : タブ名変更（名前入力 → 色選択）
-- Esc でキャンセルした場合は名前変更も色選択もスキップする
table.insert(config.keys, {
	key = "E",
	mods = "CTRL|SHIFT",
	action = act.PromptInputLine({
		description = "Enter new tab title",
		action = wezterm.action_callback(function(window, pane, line)
			if not line then
				return
			end
			if line ~= "" then
				window:active_tab():set_title(line)
			end
			prompt_tab_color(window, pane)
		end),
	}),
})

-- 新規タブを開き、名前入力 → 色選択の順にプロンプトを出す
-- どちらも未入力（空欄 / Esc）ならデフォルトのまま
local new_tab_with_prompt = wezterm.action_callback(function(window, _)
	local _, new_pane = window:mux_window():spawn_tab({ cwd = split_cwd })
	window:perform_action(
		act.PromptInputLine({
			description = "新しいタブの名前を入力（空欄でデフォルト）",
			action = wezterm.action_callback(function(win, p, line)
				if line and line ~= "" then
					win:active_tab():set_title(line)
				end
				prompt_tab_color(win, p)
			end),
		}),
		new_pane
	)
end)

-- Ctrl+Shift+T（デフォルトの SpawnTab を置き換え）
table.insert(config.keys, {
	key = "t",
	mods = "CTRL|SHIFT",
	action = new_tab_with_prompt,
})
-- macOS では CMD+T でも同じ動作にする
if wezterm.target_triple:find("darwin") then
	table.insert(config.keys, {
		key = "t",
		mods = "CMD",
		action = new_tab_with_prompt,
	})
end

-- --- 背景色の変更（Ctrl+Shift+B） ---
-- タブ色パレットを流用し、末尾に「デフォルトに戻す」を追加した選択肢を作る
local background_color_choices = {}
for _, choice in ipairs(tab_color_choices) do
	table.insert(background_color_choices, choice)
end
table.insert(background_color_choices, { id = "default", label = "デフォルトに戻す" })

-- 背景色をウィンドウのオーバーライドとして適用する。color が nil ならデフォルト
-- （カラースキームの背景色）に戻す。選択した色は wezterm.GLOBAL に保存し、
-- 設定リロード時に再適用する（WezTerm 終了で破棄され、次回起動時はデフォルトに戻る）
local function apply_background_color(window, color)
	wezterm.GLOBAL.background_color = color
	local overrides = window:get_config_overrides() or {}
	local current = overrides.colors and overrides.colors.background
	-- set_config_overrides は window-config-reloaded を再発火させるため、
	-- 適用済みの色と同じ場合は何もしない（無限ループ防止）
	if current == color then
		return
	end
	if color then
		-- overrides.colors は config.colors を丸ごと置き換えるため tab_bar も含める
		overrides.colors = { background = color, tab_bar = tab_bar_colors }
	else
		overrides.colors = nil
	end
	window:set_config_overrides(overrides)
end

table.insert(config.keys, {
	key = "B",
	mods = "CTRL|SHIFT",
	action = act.InputSelector({
		title = "背景色を選択（Esc でキャンセル）",
		choices = background_color_choices,
		action = wezterm.action_callback(function(win, _, id, _)
			-- Esc でキャンセルした場合 id は nil → 現在の背景色のまま
			if id == "default" then
				apply_background_color(win, nil)
			elseif id then
				apply_background_color(win, id)
			end
		end),
	}),
})

-- LEADER+z : 直前のコマンドと出力をコピー（OSC 133 セマンティックゾーンを使用）
-- ※ シェル統合(OSC 133)が必要。sync_shell.sh で ~/.bashrc に導入する
table.insert(config.keys, {
	key = "z",
	mods = "LEADER",
	action = wezterm.action_callback(function(window, pane)
		-- コピーモードに入る
		window:perform_action(act.ActivateCopyMode, pane)

		-- 直前のInputゾーン（最後のコマンド）に移動
		window:perform_action(act.CopyMode({ MoveBackwardZoneOfType = "Input" }), pane)

		-- セル選択モードを開始
		window:perform_action(act.CopyMode({ SetSelectionMode = "Cell" }), pane)

		-- 次のPromptゾーンまで選択（コマンドと出力を含む）
		window:perform_action(act.CopyMode({ MoveForwardZoneOfType = "Prompt" }), pane)

		-- 1行上に移動して行末へ（現在のプロンプト行を除外）
		window:perform_action(act.CopyMode("MoveUp"), pane)
		window:perform_action(act.CopyMode("MoveToEndOfLineContent"), pane)

		-- クリップボードにコピー
		window:perform_action(
			act.Multiple({
				{ CopyTo = "ClipboardAndPrimarySelection" },
				{ Multiple = { "ScrollToBottom", { CopyMode = "Close" } } },
			}),
			pane
		)

		-- ステータスバーに一時的なステータスを表示
		window:set_right_status("📋 Copied!")
		-- 3秒後にクリア
		wezterm.time.call_after(3, function()
			window:set_right_status("")
		end)
	end),
})

-- LEADER+h/j/k/l : ペイン移動（vim 風）
table.insert(config.keys, { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") })
table.insert(config.keys, { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") })
table.insert(config.keys, { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") })
table.insert(config.keys, { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") })

-- Ctrl+Shift+L : デバッグオーバーレイを表示（ログ確認用）
table.insert(config.keys, {
	key = "L",
	mods = "CTRL",
	action = wezterm.action.ShowDebugOverlay,
})

-- --- イベントハンドラ ---
-- 設定がリロードされた時にログ（Ctrl+Shift+Lで表示）を出力する
wezterm.on("window-config-reloaded", function(window, _)
	wezterm.log_info("the config was reloaded for this window!")
	-- 選択済みの背景色があれば再適用する（新規ウィンドウ作成時にも発火する）
	if wezterm.GLOBAL.background_color then
		apply_background_color(window, wezterm.GLOBAL.background_color)
	end
end)

-- タブ作成時に選択した色でタブを描画する（文字色は白固定）
-- 色未選択のタブは nil を返してデフォルト描画（config.colors.tab_bar）に任せる
wezterm.on("format-tab-title", function(tab)
	local colors = wezterm.GLOBAL.tab_colors or {}
	local color = colors[tostring(tab.tab_id)]
	if not color then
		return nil
	end
	local title = tab.tab_title
	if not title or title == "" then
		title = tab.active_pane.title
	end
	local items = {
		{ Background = { Color = color } },
		{ Foreground = { Color = "#ffffff" } },
	}
	if tab.is_active then
		table.insert(items, { Attribute = { Intensity = "Bold" } })
	end
	table.insert(items, { Text = " " .. title .. " " })
	return items
end)

-- シェルで `nvim` と打つと別タブで開く（WSL/macOS 用）
-- WSL からは wezterm cli が mux に到達できずハングするため、macOS でも統一して
-- シェル側(shell/wezterm-nvim.sh)が OSC 1337 SetUserVar=claude_open_nvim=<base64> を emit し、
-- GUI 側のここで新規タブを起動する。Linux ネイティブは wezterm cli spawn を使うため不要。
if wezterm.target_triple:find("windows") or wezterm.target_triple:find("darwin") then
	wezterm.on("user-var-changed", function(window, _pane, name, value)
		if name ~= "claude_open_nvim" then
			return
		end
		-- value(wezterm が base64 デコード済み): "nonce\ncwd\nfile1\nfile2..."
		local lines = {}
		for line in (value .. "\n"):gmatch("(.-)\n") do
			table.insert(lines, line)
		end
		table.remove(lines, 1) -- nonce を捨てる
		local cwd = table.remove(lines, 1)

		local args
		if wezterm.target_triple:find("darwin") then
			-- macOS: GUIアプリ(WezTerm.app)は最小PATH("/usr/bin:/bin:/usr/sbin:/sbin")で
			-- 起動されるため、Homebrew版nvim(/opt/homebrew/bin等)がPATH上に見つからない。
			-- ログインシェル経由で起動し、.zprofile等でPATHを解決させてからnvimをexecする。
			-- "$@" を使うことで、ファイル名にスペースを含む場合もシェルクォート不要で渡せる。
			args = { "/bin/zsh", "-l", "-c", 'exec nvim "$@"', "zsh" }
		else
			args = { "nvim" }
		end
		for _, f in ipairs(lines) do
			if f ~= "" then
				table.insert(args, f)
			end
		end

		local spawn = { args = args }
		if cwd and cwd ~= "" then
			spawn.cwd = cwd
		end
		-- WSL ではドメインを明示する。macOS はデフォルト（ローカル継承）でよい
		if wezterm.target_triple:find("windows") then
			spawn.domain = { DomainName = "WSL:Ubuntu-24.04" }
		end
		local ok, tab = pcall(function()
			return window:mux_window():spawn_tab(spawn)
		end)
		if ok and tab then
			tab:activate()
		end
	end)
end

return config
