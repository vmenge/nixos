return {
  setup = function(opts)
    vim.lsp.enable("taplo")
    vim.lsp.config('taplo', {
      capabilities = opts.capabilities
    })
  end
}
