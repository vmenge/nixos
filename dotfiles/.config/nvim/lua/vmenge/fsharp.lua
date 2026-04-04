local M = {
  codelens_enabled = false,
}

function M.codelens_settings()
  return {
    FSharp = {
      codeLenses = {
        signature = { enabled = M.codelens_enabled },
        references = { enabled = M.codelens_enabled },
      },
      lineLens = {
        enabled = M.codelens_enabled and "always" or "never",
        prefix = "",
      },
      enableReferenceCodeLens = M.codelens_enabled,
    },
  }
end

local function fsharp_clients()
  local clients = {}

  for _, client in ipairs(vim.lsp.get_clients()) do
    if client.name == "ionide" or client.name == "fsautocomplete" then
      table.insert(clients, client)
    end
  end

  return clients
end

local function refresh_codelens()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype == "fsharp" then
      pcall(vim.lsp.codelens.refresh, { bufnr = bufnr })
    end
  end
end

local function clear_codelens()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype == "fsharp" then
      pcall(vim.lsp.codelens.clear, nil, bufnr)
    end
  end
end

function M.apply_codelens_settings()
  local settings = M.codelens_settings()

  for _, client in ipairs(fsharp_clients()) do
    client.notify("workspace/didChangeConfiguration", {
      settings = settings,
    })
  end

  if M.codelens_enabled then
    refresh_codelens()
  else
    clear_codelens()
    refresh_codelens()
  end
end

function M.toggle_codelens()
  M.codelens_enabled = not M.codelens_enabled
  M.apply_codelens_settings()

  vim.notify(
    ("F# CodeLens %s"):format(M.codelens_enabled and "enabled" or "disabled"),
    vim.log.levels.INFO
  )
end

return M
