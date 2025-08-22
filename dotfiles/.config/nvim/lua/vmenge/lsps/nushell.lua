return {
  setup = function(opts)
    vim.lsp.enable("nushell")
    vim.lsp.config('nushell', {
      capabilities = opts.capabilities
    })
  end
}
