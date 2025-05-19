return {
  "OXY2DEV/markview.nvim",
  dependencies = {
    "saghen/blink.cmp"
  },
  config = function()
    require("markview.extras.checkboxes").setup()
  end
};
