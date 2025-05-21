return {
  "folke/which-key.nvim",
  event = "VeryLazy",

  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,

  config = function()
    function DeleteBufferWithoutClosingWindow()
      local cur_buf = vim.api.nvim_get_current_buf()
      local buffers = vim.api.nvim_list_bufs()
      local replacement_buf = nil

      -- Attempt to find an alternative buffer that is not the current one and is loaded
      for _, buf in ipairs(buffers) do
        if buf ~= cur_buf and vim.api.nvim_buf_is_loaded(buf) and vim.fn.buflisted(buf) == 1 then
          replacement_buf = buf
          break
        end
      end

      -- If no alternative buffer is found, check for any buffer, even if not loaded
      if replacement_buf == nil then
        for _, buf in ipairs(buffers) do
          if buf ~= cur_buf and vim.fn.buflisted(buf) == 1 then
            replacement_buf = buf
            break
          end
        end
      end

      -- If still no buffer is found, create a new one
      if replacement_buf == nil then
        replacement_buf = vim.api.nvim_create_buf(true, false)
      end

      -- Set the found or new buffer to the current window
      vim.api.nvim_win_set_buf(0, replacement_buf)

      -- Delete the original buffer
      vim.api.nvim_buf_delete(cur_buf, { force = true })
    end

    function Format()
      local file = vim.api.nvim_buf_get_name(0)

      require("conform").format({
        lsp_fallback = true,
        async = false,
        timeout_ms = 1000,
      })

      if file:sub(-3) == ".rs" then
        vim.cmd("write")
        vim.fn.jobstart({ "dx", "fmt", "-f", file }, {
          on_exit = function()
            vim.schedule(function()
              local view = vim.fn.winsaveview()
              vim.cmd("edit!")
              vim.fn.winrestview(view)
            end)
          end
        })
      end
    end

    local wk = require("which-key")
    wk.add({
      { "<leader>g", group = "Git" },
      { "<leader>gb", "<cmd>GitBlameToggle<CR>", desc = "Toggle Git Blame" },
      { "<leader>L", "<cmd>Lazy<CR>", desc = "Lazy" },
      { "<leader>b", group = "Buffer" },
      { "<leader>bD", "<cmd>bwipeout<CR>", desc = "Wipe Buffer" },
      { "<leader>bd", "<cmd>lua DeleteBufferWithoutClosingWindow()<CR>", desc = "Delete Buffer" },
      { "<leader>bg", "<cmd>BufferLinePick<CR>", desc = "Go to Buffer" },
      { "<leader>f", group = "Find" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Find in Buffers" },
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find Files" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live Grep" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help Tags" },
      { "<leader>k", "<cmd>lua vim.lsp.buf.hover()<CR>", desc = "Hover", icon = "" },
      { "<leader>l", group = "Lsp", icon = "" },
      { "<leader>la", "<cmd>lua vim.lsp.buf.code_action()<CR>", desc = "Code Action" },
      { "<leader>lc", "<cmd>lua vim.lsp.codelens.display()<CR>", desc = "CodeLens" },
      { "<leader>ld", "<cmd>Telescope diagnostics<CR>", desc = "Diagnostics" },
      { "<leader>lf", "<cmd>lua Format()<CR>", desc = "Format" },
      { "<leader>li", "<cmd>LspInfo<CR>", desc = "Lsp Info" },
      {
        "<leader>ll",
        "<cmd>lua vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())<CR>",
        desc = "Inlay Hints",
      },
      { "<leader>lr", "<cmd>lua vim.lsp.buf.rename()<CR>", desc = "Rename" },
      -- { "<leader>m", "<cmd>Mason<CR>", desc = "Mason" },
      { "<leader>m", group = "Markdown" },
      { "<leader>mt", "<cmd>Checkbox toggle<CR>", desc = "Toggle Checkbox" },
      { "<leader>mi", "<cmd>Checkbox Interactive<CR>", desc = "Interactive Checkbox" },
      { "<leader>mc", "<cmd>Checkbox change 1 0<CR>", desc = "Next Checkbox State" },
      { "<leader>mC", "<cmd>Checkbox change -1 0<CR>", desc = "Previous Checkbox State" },
      { "<leader>n", group = "Notify" },
      { "<leader>nx", '<cmd>lua require("notify").dismiss()<CR>', desc = "Dismiss" },
      { "<leader>nh", '<cmd>Telescope notify<CR>', desc = "History" },
      { "<leader>o", group = "Org-mode", icon = "" },
      { "<leader>q", group = "Quit" },
      { "<leader>qQ", "<cmd>qa!<CR>", desc = "Quit (force)" },
      { "<leader>qq", "<cmd>qa<CR>", desc = "Quit" },
      { "<leader>s", group = "Search" },
      { "<leader>sc", "<cmd>Telescope commands<cr>", desc = "Commands" },
      { "<leader>sM", "<cmd>Telescope man_pages<cr>", desc = "Man Pages" },
      { "<leader>sR", "<cmd>Telescope registers<cr>", desc = "Registers" },
      { "<leader>sb", "<cmd>Telescope git_branches<cr>", desc = "Checkout branch" },
      { "<leader>sC", "<cmd>Telescope colorscheme<cr>", desc = "Colorscheme" },
      { "<leader>sh", "<cmd>Telescope help_tags<cr>", desc = "Find Help" },
      { "<leader>sk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
      { "<leader>sr", "<cmd>Telescope oldfiles<cr>", desc = "Open Recent File" },
      { "<leader>t", group = "Treesitter", icon = "" },
      { "<leader>tt", "<cmd>TSToggle highlight<CR>", desc = "Toggle Highlight" },
      { "<leader>w", group = "Window" },
      { "<leader>wd", "<cmd>clo<CR>", desc = "Close Window" },
      { "<leader>wj", "<cmd>sp<CR>", desc = "Split down" },
      { "<leader>wl", "<cmd>vsp<CR>", desc = "Split right" },
      { "<leader>ww", "<C-w>w", desc = "Attach" },
      { "<leader>x", group = "Trouble", icon = "" },
    })
  end,

  dependencies = {
    "echasnovski/mini.icons",
    "nvim-tree/nvim-web-devicons"
  }
}
