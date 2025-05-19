return {
  setup = function(opts)
    vim.lsp.enable("rust_analyzer")
    vim.lsp.config('rust_analyzer', {
      settings = {
        ['rust-analyzer'] = {
          diagnostics = {
            enable = true,
            experimental = true,
          },
          check = {
            command = "clippy"
          }
        }
      },
      capabilities = opts.capabilities
    })
  end
}
