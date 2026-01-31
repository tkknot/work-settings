-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- 表示と言語
vim.opt.fileencoding = "utf-8" -- エンコーディングをUTF-8に設定

-- 行番号とカーソル
vim.opt.number = true -- 行番号を表示
vim.opt.relativenumber = true -- 現在の行番号を相対表示
vim.opt.cursorline = true -- 現在の行を強調表示
vim.opt.virtualedit = "onemore" -- 行末の1文字先までカーソルを移動できるように

-- インデント
vim.opt.smartindent = true
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.autoindent = true

-- 検索
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.wrapscan = true
vim.opt.hlsearch = true

-- UI・不可視文字
vim.opt.list = true -- 不可視文字を可視化
vim.opt.listchars = { tab = "▸-", trail = "·" }
vim.opt.showmatch = true -- 括弧入力時の対応する括弧を表示
vim.opt.laststatus = 3 -- グローバルステータスラインを使用（Neovim推奨）

-- 分割とバッファ
vim.opt.splitbelow = true
vim.opt.hidden = true -- バッファが編集中でもその他のファイルを開けるように

-- クリップボード
vim.opt.clipboard:append({ "unnamedplus" })
