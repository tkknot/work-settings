-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- 入力モード
vim.keymap.set("i", "jj", "<Esc>", { desc = "Exit insert mode" })

-- 表示行単位での移動
vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")

-- 大文字HJKLでの高速移動 (LazyVimのデフォルトバッファ切り替えを上書き)
-- バッファ切り替えは LazyVim 標準の [b / ]b または以前のまま S-h / S-l を使いたい場合はここを削除してください
vim.keymap.set({ "n", "v" }, "H", "^", { desc = "Go to line start" })
vim.keymap.set({ "n", "v" }, "L", "$", { desc = "Go to line end" })
vim.keymap.set({ "n", "v" }, "J", "}", { desc = "Go to next paragraph" })
vim.keymap.set({ "n", "v" }, "K", "{", { desc = "Go to previous paragraph" })

-- 設定ファイルを開く
vim.keymap.set("n", "<leader>.", ":e $MYVIMRC<CR>", { desc = "Open config" })

-- コメントアウトのトグル (LazyVimの機能を利用)
vim.keymap.set("n", "<leader>cc", "gcc", { remap = true, desc = "Toggle comment line" })
vim.keymap.set("v", "<leader>c", "gc", { remap = true, desc = "Toggle comment" })

-- terminal toggle
vim.keymap.set("n", "<C-/>", function()
  Snacks.terminal(nil, { win = { position = "bottom", height = 0.3 } })
end, { desc = "Terminal (Bottom)" })

vim.keymap.set("n", "<C-_>", function()
  Snacks.terminal(nil, { win = { position = "bottom", height = 0.3 } })
end, { desc = "Terminal (Bottom)" })

-- Lazygit
vim.keymap.set("n", "<leader>gg", function()
  Snacks.terminal("lazygit", { win = { position = "float" } })
end, { desc = "Lazygit" })
