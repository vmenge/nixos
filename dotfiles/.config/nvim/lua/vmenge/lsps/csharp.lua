return {
  setup = function(opts)
    vim.lsp.enable("omnisharp")
    vim.lsp.config('omnisharp', {
      capabilities = opts.capabilities
    })
  end
}
