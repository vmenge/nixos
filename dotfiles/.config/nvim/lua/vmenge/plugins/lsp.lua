return {
  "neovim/nvim-lspconfig",
  dependencies = { 'saghen/blink.cmp' },
  config = function()
    local lsps = {
      "c",
      "clojure",
      "csharp",
      "fsharp",
      "golang",
      "helm",
      "lua",
      "markdown",
      "nix",
      "ocaml",
      "rust",
      "terraform",
      "toml",
      "typescript",
    }

    for _, lsp in ipairs(lsps) do
      local capabilities = require('blink.cmp').get_lsp_capabilities()
      local import = "vmenge.lsps." .. lsp

      require(import).setup({ capabilities = capabilities })
    end
  end,
}
