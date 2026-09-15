return {
  setup = function(opts)
    vim.lsp.roc.setup({
      cmd = { 'roc', 'experimental-lsp' }
    })
  end
}
