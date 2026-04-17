return {
  "ionide/Ionide-vim",
  init = function()
    vim.g["fsharp#fsautocomplete_command"] = {
      'fsautocomplete',
      '--background-service-enabled',
      '--msbuildproperty:Platform=Editor', -- ← this is the only new part
    }

    vim.g["fsharp#lsp_auto_setup"] = 0
    vim.g["fsharp#lsp_codelens"] = 0
  end,
  config = function()
    vim.lsp.enable('ionide')

    local fsharp = require("vmenge.fsharp")
    vim.lsp.config('ionide', fsharp.codelens_settings())
  end,
}
