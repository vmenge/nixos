return {
  'mrcjkb/rustaceanvim',
  version = '^6',
  ft = 'rust',
  dependencies = { 'saghen/blink.cmp' },
  init = function()
    vim.g.rustaceanvim = {
      server = {
        cmd = function()
          -- this makes it work with the rust-analyzer provided by nix flakes
          local handle = io.popen('rustup which rust-analyzer 2>/dev/null')
          if handle then
            local result = handle:read('*a'):gsub('%s+$', '')
            handle:close()
            if result ~= '' then
              return { result }
            end
          end
          return { 'rust-analyzer' }
        end,

        default_settings = {
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
              attributes = {
                enable = true,
              },
            },
          }
        },
        flags = {
          debounce_text_changes = 150,
        },
      },
    }
  end,
}
