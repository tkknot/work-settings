-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<C-/>", function()
  Snacks.terminal(nil, { win = { position = "right", width = 0.4 } })
end, { desc = "Terminal (Right)" })

vim.keymap.set("n", "<C-_>", function()
  Snacks.terminal(nil, { win = { position = "right", width = 0.4 } })
end, { desc = "Terminal (Right)" })

-- Lazygit
vim.keymap.set("n", "<leader>gg", function()
  Snacks.terminal("lazygit", { win = { position = "float" } })
end, { desc = "Lazygit" })
