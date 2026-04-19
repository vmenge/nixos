return {
  "ionide/Ionide-vim",
  ft = { 'fsharp', 'fsharp_project' },
  init = function()
    vim.g["fsharp#fsautocomplete_command"] = {
      'fsautocomplete',
      '--background-service-enabled',
      '--msbuildproperty:Platform=Editor',
    }

    vim.g["fsharp#lsp_codelens"] = 0
  end,
  config = function()
    local fsharp = require("vmenge.fsharp")
    vim.lsp.config('ionide', { settings = fsharp.codelens_settings() })
  end,
}
