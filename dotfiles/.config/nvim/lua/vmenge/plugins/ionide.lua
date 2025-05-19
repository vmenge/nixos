return {
  "ionide/Ionide-vim",
  init = function()
    vim.g["fsharp#fsautocomplete_command"] = {
      'fsautocomplete',
      '--background-service-enabled',
      '--msbuildproperty:Platform=Editor', -- ← this is the only new part
    }
  end
}
