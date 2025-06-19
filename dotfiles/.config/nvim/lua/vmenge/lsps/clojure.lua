return {
  setup = function(opts)
    vim.lsp.enable("clojure_lsp")
    vim.lsp.config('clojure_lsp', {
      capabilities = opts.capabilities
    })
  end
}
