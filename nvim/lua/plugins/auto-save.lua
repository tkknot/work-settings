return {
  "okuuva/auto-save.nvim",
  cmd = "ASToggle",
  event = { "InsertLeave", "TextChanged" },
  opts = {
    enabled = true,
    trigger_events = {
      immediate_save = { "BufLeave", "FocusLost" },
      defer_save = { "InsertLeave", "TextChanged" },
    },
    condition = function(buf)
      local fn = vim.fn
      local utils = require("auto-save.utils.data")

      if
        fn.getbufvar(buf, "&modifiable") == 1 and
        fn.getbufvar(buf, "&buftype") == ""
      then
        return true
      end
      return false
    end,
    write_delay = 1000, -- 1秒のディレイ（連打対策）
    debounce_delay = 135,
  },
}
