return {
  setup = function(opts)
    vim.lsp.enable("gopls")
    vim.lsp.config('gopls', {
      capabilities = opts.capabilities
    })
  end
}
