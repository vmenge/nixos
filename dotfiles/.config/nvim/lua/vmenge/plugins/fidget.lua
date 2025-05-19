return {
  "j-hui/fidget.nvim",
  event = "LspAttach",
  config = function()
    require("fidget").setup({
      progress = {
        suppress_on_insert = true,
        ignore_done_already = true,
        display = {
          render_limit = 4,
          done_ttl = 2,
        },
      },
    })
  end
}
