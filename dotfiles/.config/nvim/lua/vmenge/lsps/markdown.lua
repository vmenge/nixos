return {
  setup = function(opts)
    local mkoxide_cap = {
      workspace = {
        didChangeWatchedFiles = {
          dynamicRegistration = true,
        },
      },
    }

    vim.lsp.enable("markdown_oxide")
    vim.lsp.config('markdown_oxide', {
      capabilities = vim.tbl_deep_extend('force', opts.capabilities, mkoxide_cap)
    })
  end
}
