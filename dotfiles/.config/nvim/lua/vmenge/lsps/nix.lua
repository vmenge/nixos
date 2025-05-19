return {
  setup = function(opts)
    vim.lsp.enable("nixd")
    vim.lsp.config('nixd', {
      capabilities = opts.capabilities
    })
  end
}
