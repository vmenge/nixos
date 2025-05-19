return {
  setup = function(opts)
    vim.lsp.enable("helm_ls")
    vim.lsp.config('helm_ls', {
      capabilities = opts.capabilities
    })
  end
}
