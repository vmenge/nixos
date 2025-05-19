return {
  'akinsho/bufferline.nvim',
  version = "*",
  dependencies = 'nvim-tree/nvim-web-devicons',
  config = function()
    local hl_none = { fg = "#89b4fa", bg = "NONE" }
    local bufferline = require('bufferline')
    bufferline.setup {
      -- options = {
      --   separator_style = "padded_slope",
      --   style_preset = { bufferline.style_preset.no_italic, bufferline.minimal }
      -- }

      options = {
        separator_style         = { "", "" },
        indicator               = { style = "none" },
        show_buffer_close_icons = false,
        always_show_bufferline  = true,
        style_preset            = {},
      },

      highlights = {
        fill               = { bg = "NONE" },
        background         = { bg = "NONE" },
        tab                = { bg = "#000000" },
        tab_selected       = { bg = "#000000" },
        buffer_visible     = { bg = "NONE" },
        buffer_selected    = { bg = "NONE" },
        separator          = hl_none,
        separator_visible  = hl_none,
        separator_selected = hl_none,
      },
    }

    -- kill any theme-supplied TabLine background so the line stays transparent
    for _, grp in ipairs({ "TabLineFill", "TabLine", "TabLineSel" }) do
      vim.api.nvim_set_hl(0, grp, { bg = "NONE" })
    end
  end
}
