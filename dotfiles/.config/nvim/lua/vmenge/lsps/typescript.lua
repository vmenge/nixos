return {
  setup = function(opts)
    vim.lsp.enable("ts_ls")
    vim.lsp.config('ts_ls', {
      capabilities = opts.capabilities
    })
  end
}
