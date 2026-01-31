return {
  -- ファイルエクスプローラーと検索の設定
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            hidden = true, -- デフォルトで隠しファイルを表示
          },
          files = {
            hidden = true, -- ファイル検索でも隠しファイルを表示
          },
        },
      },
    },
  },
}
