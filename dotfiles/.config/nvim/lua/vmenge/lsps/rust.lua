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
          cargo = {
            allFeatures = true,
            loadOutDirsFromCheck = true,
            runBuildScripts = true,
          },
          check = {
            command = "clippy"
          },
          checkOnSave = {
            allFeatures = true,
            command = "clippy",
            extraArgs = { "--no-deps" },
          },
          procMacro = {
            enable = true,
            ignored = {
              -- ["async-trait"] = { "async_trait" },
              ["napi-derive"] = { "napi" },
              ["async-recursion"] = { "async_recursion" },
            },
          }
        }
      },
      capabilities = opts.capabilities
    })
  end
}
