return {
  -- Tokyo Night
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },

  -- Kanagawa (日本の伝統色ベース)
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 999,
    opts = {
      transparent = true,
    },
  },

  -- LazyVimのデフォルトカラースキーム設定を無効化
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        local colorschemes = {
          "tokyonight",
          "kanagawa",
        }
        
        -- ランダムシードを設定
        math.randomseed(os.time() + vim.fn.getpid())
        
        -- ランダムにテーマを選択して適用
        local selected_scheme = colorschemes[math.random(#colorschemes)]
        vim.cmd.colorscheme(selected_scheme)
        vim.notify("🎨 Theme: " .. selected_scheme, vim.log.levels.INFO)

        -- ターミナル背景を透明にするためのハイライト設定を追加
        vim.api.nvim_set_hl(0, "Terminal", { link = "Normal" })
        vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
        vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
      end,
    },
  },
}
