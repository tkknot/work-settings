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

  -- Catppuccin (人気のパステルカラーテーマ)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 999,
    opts = {
      transparent_background = true,
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

  -- Rose Pine (落ち着いた配色)
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = false,
    priority = 999,
    opts = {
      styles = {
        transparency = true,
      },
    },
  },

  -- Gruvbox (クラシックな人気テーマ)
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 999,
    opts = {
      transparent_mode = true,
    },
  },

  -- Nord (北欧系の配色)
  {
    "shaunsingh/nord.nvim",
    lazy = false,
    priority = 999,
    init = function()
      vim.g.nord_disable_background = true
    end,
  },

  -- Nightfox (複数のバリエーション)
  {
    "EdenEast/nightfox.nvim",
    lazy = false,
    priority = 999,
    opts = {
      options = {
        transparent = true,
      },
    },
  },

  -- Dracula (人気のダークテーマ)
  {
    "Mofiqul/dracula.nvim",
    lazy = false,
    priority = 999,
    opts = {
      transparent_bg = true,
    },
  },

  -- LazyVimのデフォルトカラースキーム設定を無効化
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        -- 人気のカラーテーマリスト
        local colorschemes = {
          "tokyonight",
          "tokyonight-night",
          "tokyonight-storm",
          "tokyonight-moon",
          "catppuccin",
          "catppuccin-mocha",
          "catppuccin-macchiato",
          "catppuccin-latte",
          "kanagawa",
          "kanagawa-wave",
          "kanagawa-dragon",
          "rose-pine",
          "rose-pine-moon",
          "rose-pine-dawn",
          "gruvbox",
          "nord",
          "nightfox",
          "duskfox",
          "nordfox",
          "carbonfox",
          "dracula",
        }
        
        -- ランダムシードを設定
        math.randomseed(os.time() + vim.fn.getpid())
        
        -- ランダムにテーマを選択して適用
        local selected_scheme = colorschemes[math.random(#colorschemes)]
        vim.cmd.colorscheme(selected_scheme)
        vim.notify("🎨 Theme: " .. selected_scheme, vim.log.levels.INFO)
      end,
    },
  },
}
