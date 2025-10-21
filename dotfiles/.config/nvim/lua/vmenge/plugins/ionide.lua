return {
  "ionide/Ionide-vim",
  init = function()
    vim.g["fsharp#fsautocomplete_command"] = {
      'fsautocomplete',
      '--background-service-enabled',
      '--msbuildproperty:Platform=Editor', -- ← this is the only new part
    }

    vim.g["fsharp#lsp_codelens"] = 0
  end
}

