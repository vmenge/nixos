return {
  setup = function(opts)
    vim.lsp.enable("pyright")
    vim.lsp.config('pyright', {
      capabilities = opts.capabilities
    })
  end
}
