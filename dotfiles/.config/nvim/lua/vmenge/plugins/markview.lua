return {
  "OXY2DEV/markview.nvim",
  dependencies = {
    "saghen/blink.cmp"
  },
  lazy = false,
  priority = 1000,
  config = function()
    require("markview.extras.checkboxes").setup()
  end
};
