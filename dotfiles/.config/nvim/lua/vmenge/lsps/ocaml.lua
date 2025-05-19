return {
  setup = function(opts)
    vim.lsp.enable("ocamllsp")
    vim.lsp.config('ocamllsp', {
      capabilities = opts.capabilities
    })
  end
}
