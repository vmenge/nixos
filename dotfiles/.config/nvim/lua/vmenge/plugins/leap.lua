return {
  "ggandor/leap.nvim",
  enabled = true,
  keys = {
    { "s", mode = { "n", "x", "o" }, desc = "Leap forward to" },
    { "S", mode = { "n", "x", "o" }, desc = "Leap backward to" },
    { "gs", mode = { "n", "x", "o" }, desc = "Leap from windows" },
  },
  config = function(_, opts)
    local leap = require("leap")
    for k, v in pairs(opts) do
      leap.opts[k] = v
    end
    vim.keymap.set({ "n", "x", "o" }, "s", "<Plug>(leap-forward)")
    vim.keymap.set({ "n", "x", "o" }, "S", "<Plug>(leap-backward)")
    vim.keymap.set({ "n", "x", "o" }, "gs", "<Plug>(leap-from-window)")
  end,
}
