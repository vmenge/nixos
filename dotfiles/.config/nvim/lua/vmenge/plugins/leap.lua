return {
  url = "https://codeberg.org/andyg/leap.nvim",
  enabled = true,
  keys = {
    { "s", mode = { "n", "x", "o" }, desc = "Leap forward to" },
    { "S", mode = { "n", "x", "o" }, desc = "Leap backward to" },
    { "gs", mode = { "n", "x", "o" }, desc = "Leap from windows" },
    { "f", mode = { "n", "x", "o" }, desc = "Leap f" },
    { "F", mode = { "n", "x", "o" }, desc = "Leap F" },
    { "t", mode = { "n", "x", "o" }, desc = "Leap t" },
    { "T", mode = { "n", "x", "o" }, desc = "Leap T" },
  },
  config = function(_, opts)
    local leap = require("leap")
    for k, v in pairs(opts) do
      leap.opts[k] = v
    end
    vim.keymap.set({ "n", "x", "o" }, "s", "<Plug>(leap-forward)")
    vim.keymap.set({ "n", "x", "o" }, "S", "<Plug>(leap-backward)")
    vim.keymap.set({ "n", "x", "o" }, "gs", "<Plug>(leap-from-window)")

    -- f/t motions (replaces flit.nvim)
    local function ft(key_specific_args)
      leap.leap(
        vim.tbl_deep_extend('keep', key_specific_args, {
          inputlen = 1,
          inclusive = true,
          opts = {
            labels = '',
            -- Labels in normal and visual modes (matching old flit labeled_modes = "nx").
            safe_labels = vim.fn.mode(1):match('o') and '' or nil,
          },
        })
      )
    end

    local clever = require('leap.user').with_traversal_keys
    local clever_f, clever_t = clever('f', 'F'), clever('t', 'T')

    vim.keymap.set({ 'n', 'x', 'o' }, 'f', function() ft { opts = clever_f } end)
    vim.keymap.set({ 'n', 'x', 'o' }, 'F', function() ft { backward = true, opts = clever_f } end)
    vim.keymap.set({ 'n', 'x', 'o' }, 't', function() ft { offset = -1, opts = clever_t } end)
    vim.keymap.set({ 'n', 'x', 'o' }, 'T', function() ft { backward = true, offset = 1, opts = clever_t } end)
  end,
}
