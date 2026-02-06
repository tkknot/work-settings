return {
  -- ファイルエクスプローラーと検索の設定
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
          { section = "startup" },
        },
      },
      picker = {
        sources = {
          explorer = {
            hidden = true,
            ignored = true,
            -- explorerでは何も除外しない（すべて表示）
            exclude = {},
          },
          files = {
            hidden = true,
            ignored = false,
            exclude = { "node_modules", ".git" },
          },
          grep = {
            hidden = true,
            ignored = false,
            exclude = { "node_modules", ".git" },
          },
        },
      },
    },
    keys = {
      { "<leader>/", function() Snacks.picker.grep() end, desc = "Grep (Root Dir)" },
      { "<leader>sg", function() Snacks.picker.grep() end, desc = "Grep (Root Dir)" },
      { "<leader>sw", function() Snacks.picker.grep_word() end, desc = "Visual selection or word", mode = { "n", "x" } },
      { "<leader>e", function() Snacks.explorer() end, desc = "File Explorer" },
    },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    enabled = false,
  },
}