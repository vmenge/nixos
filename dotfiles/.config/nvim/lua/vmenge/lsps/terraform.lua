return {
  setup = function(opts)
    vim.lsp.enable("terraformls")
    vim.lsp.config('terraformls', {
      capabilities = opts.capabilities
    })
  end
}
