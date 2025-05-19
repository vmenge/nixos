return {
  setup = function(opts)
    vim.lsp.enable("clangd")
    vim.lsp.config('clangd', {
      capabilities = opts.capabilities
    })
  end
}
