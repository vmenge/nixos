return {
  setup = function(opts)
    vim.lsp.enable("rust_analyzer")
    
    -- Configure hover timeout specifically
    vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
      vim.lsp.handlers.hover, {
        timeout_ms = 1000,
        silent = true,
      }
    )
    
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
      capabilities = opts.capabilities,
      flags = {
        debounce_text_changes = 150,
      },
    })
  end
}
