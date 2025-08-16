return {
  {
    "bluz71/vim-nightfly-guicolors",
    -- priority = 1000,
    -- config = function()
    -- vim.cmd([[colorscheme nightfly]])
    -- end,
  },
  {
    "EdenEast/nightfox.nvim",
    config = function()
      -- vim.cmd.colorscheme("duskfox")
      -- vim.cmd.colorscheme("carbonfox")
    end,
  },
  {
    "rose-pine/neovim",
    -- name = "rose-pine",
    -- config = function()
    --   vim.cmd([[colorscheme rose-pine]])
    -- end,
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    config = function()
      require("catppuccin").setup({
        flavour = "frappe",
      })

      -- vim.cmd([[colorscheme catppuccin]])
    end,
  },
  {
    "shatur/neovim-ayu",
    config = function()
      require("ayu").setup({
        mirage = true,
        overrides = {
          -- Normal = { bg = "None" },
          -- NormalFloat = { bg = "none" },
          -- ColorColumn = { bg = "None" },
          -- SignColumn = { bg = "None" },
          -- Folded = { bg = "None" },
          -- FoldColumn = { bg = "None" },
          -- CursorLine = { bg = "None" },
          -- CursorColumn = { bg = "None" },
          -- VertSplit = { bg = "None" },
        },
      })

      -- vim.cmd.colorscheme("ayu-dark")
    end,
  },
  {
    "dracula/vim",
    name = "dracula",
    config = function()
      -- vim.cmd([[colorscheme catppuccin]])
    end,
  },
  {
    "maxmx03/solarized.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      -- vim.o.background = "light" -- or 'dark'

      -- vim.cmd.colorscheme("solarized")
    end,
  },
  {
    "shaunsingh/nord.nvim",
    config = function()
      vim.g.nord_contrast = true
      vim.g.nord_borders = false
      vim.g.nord_disable_background = false
      vim.g.nord_italic = false
      vim.g.nord_uniform_diff_background = true
      vim.g.nord_bold = false
    end,
  },
  { "projekt0n/github-nvim-theme" },
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    config = function()
      require("gruvbox").setup({
        terminal_colors = true, -- add neovim terminal colors
        undercurl = true,
        underline = true,
        bold = false,
        italic = {
          strings = false,
          emphasis = false,
          comments = false,
          operators = false,
          folds = false,
        },
        strikethrough = true,
        invert_selection = false,
        invert_signs = false,
        invert_tabline = false,
        invert_intend_guides = false,
        inverse = true,    -- invert background for search, diffs, statuslines and errors
        contrast = "hard", -- can be "hard", "soft" or empty string
        palette_overrides = {},
        overrides = {},
        dim_inactive = false,
        transparent_mode = false,
      })

      -- vim.cmd.colorscheme("gruvbox")
    end,
  },
  {
    "Abstract-IDE/Abstract-cs",
    config = function()
      -- vim.cmd.colorscheme("abscs")
    end,
  },
  {
    "nvimdev/zephyr-nvim",
    config = function()
      -- vim.cmd.colorscheme("zephyr")
    end,
  },
  {
    "Everblush/nvim",
    config = function()
      require("everblush").setup({
        -- Default options
        override = {},
        transparent_background = false,
        nvim_tree = {
          contrast = false,
        },
      })

      -- vim.cmd.colorscheme("everblush")
    end,
  },
  {
    "2nthony/vitesse.nvim",
    dependencies = {
      "tjdevries/colorbuddy.nvim",
    },
    config = function()
      require("vitesse").setup({
        comment_italics = true,
        transparent_background = true,
        transparent_float_background = true, -- aka pum(popup menu) background
        reverse_visual = false,
        dim_nc = false,
        cmp_cmdline_disable_search_highlight_group = false, -- disable search highlight group for cmp item
        -- if `transparent_float_background` false, make telescope border color same as float background
        telescope_border_follow_float_background = false,
        -- similar to above, but for lspsaga
        lspsaga_border_follow_float_background = false,
        -- diagnostic virtual text background, like error lens
        diagnostic_virtual_text_background = false,

        -- override the `lua/vitesse/palette.lua`, go to file see fields
        colors = {},
        themes = {},
      })

      -- vim.cmd.colorscheme("vitesse")
    end,
  },
  {
    "nyngwang/nvimgelion",
    config = function()
      -- vim.cmd.colorscheme("nvimgelion")
    end,
  },
  -- {
  --   "ayu-theme/ayu-vim",
  --   config = function()
  --     -- vim.cmd.colorscheme("ayu")
  --   end,
  -- },
  {
    "cpea2506/one_monokai.nvim",
    config = function()
      -- require("one_monokai").setup({
      -- 	transparent = true,
      -- 	colors = {},
      -- 	themes = function(colors)
      -- 		return {}
      -- 	end,
      -- 	italics = true,
      -- })

      -- vim.cmd.colorscheme("one_monokai")
    end,
  },
  {
    "tanvirtin/monokai.nvim",
    config = function()
      -- require("monokai").setup({ palette = require("monokai").pro })
      -- require("monokai").setup({ palette = require("monokai").soda })
      -- require("monokai").setup({ palette = require("monokai").ristretto })
      -- vim.cmd.colorscheme("monokai")
    end,
  },
  {
    "loctvl842/monokai-pro.nvim",
    config = function()
      -- require("monokai-pro-machine").setup()
    end,
  },
  {
    "xiyaowong/transparent.nvim",
  },
  {
    "akinsho/horizon.nvim",
    opts = {
      plugins = {
        cmp = true,
        indent_blankline = true,
        nvim_tree = true,
        telescope = true,
        which_key = true,
        barbar = true,
        notify = true,
        symbols_outline = true,
        neo_tree = true,
        gitsigns = true,
        crates = true,
        hop = true,
        navic = true,
        quickscope = true,
        flash = true,
      },
    },
    config = function()
      -- vim.cmd.colorscheme("horizon")
    end,
  },
  {
    "kdheepak/monochrome.nvim",
    config = function()
      -- vim.cmd.colorscheme("monochrome")
    end,
  },
  {
    "andreasvc/vim-256noir",
    config = function() end,
  },
  {
    "Alligator/accent.vim",
    config = function()
      -- vim.cmd.colorscheme("accent")
    end,
  },
  {
    "ntk148v/komau.vim",
    config = function()
      -- vim.cmd.colorscheme("komau")
    end,
  },
  {
    "Jorengarenar/vim-darkness",
    config = function()
      -- vim.cmd.colorscheme("darkness")
    end,
  },
  {
    "jesseleite/nvim-noirbuddy",
    config = function()
      -- vim.cmd.colorscheme("noirbuddy")
    end,
  },
  {
    "ewilazarus/preto",
    config = function()
      -- vim.cmd.colorscheme("preto")
    end,
  },
  {
    "hardselius/warlock",
    config = function()
      -- vim.cmd.colorscheme("warlock")
    end,
  },
  {
    "rost/vim-lesser",
    config = function()
      -- vim.cmd.colorscheme("lesser")
    end,
  },
  {
    "pgdouyon/vim-yin-yang",
    config = function()
      --  i dunno
    end,
  },
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      transparent = true,
    },
    config = function()
      require("tokyonight").setup({
        transparent = true,
      })
      vim.cmd.colorscheme("tokyonight")
    end,
  },
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
  },
  {
    "yorik1984/newpaper.nvim",
    priority = 1000,
    config = function()
      -- vim.cmd.colorscheme("newpaper")
    end,
    opts = {
      style = "dark",
    },
  },
  {
    "sho-87/kanagawa-paper.nvim",
    lazy = false,
    priority = 1000,
  },
  {
    "ptdewey/darkearth-nvim",
    priority = 1000,
  },
  {
    "neanias/everforest-nvim",
    version = false,
    lazy = true,
    priority = 1000, -- make sure to load this before all the other start plugins
    -- Optional; default configuration will be used if setup isn't called.
    config = function()
      require("everforest").setup({
        -- Your config here
      })

      -- vim.cmd.colorscheme("everforest")
    end,
  },
  {
    "zenbones-theme/zenbones.nvim",
    -- Optionally install Lush. Allows for more configuration or extending the colorscheme
    -- If you don't want to install lush, make sure to set g:zenbones_compat = 1
    -- In Vim, compat mode is turned on as Lush only works in Neovim.
    dependencies = "rktjmp/lush.nvim",
    lazy = false,
    priority = 1000,
    -- you can set set configuration options here
    config = function()
      -- vim.g.zenbones_darken_comments = 45
      -- vim.cmd.colorscheme('duckbones')
    end
  },
  {
    "Mofiqul/adwaita.nvim",
    config = function()
      -- vim.g.adwaita_darker = true
      -- vim.cmd.colorscheme("adwaita")
    end
  },
  {
    "kjssad/quantum.vim",
    config = function()
      -- vim.cmd.colorscheme("quantum")
    end
  },
  {
    "vague2k/vague.nvim",
    config = function()
      -- vim.cmd.colorscheme("vague")
    end
  },
  {
    "pineapplegiant/spaceduck",
    config = function()
      -- vim.cmd.colorscheme("spaceduck")
    end
  },
  {
    "diegoulloao/neofusion.nvim",
    priority = 1000,
    config = function()
      --   vim.cmd.colorscheme("neofusion")
    end
  },
  {
    "srcery-colors/srcery-vim",
    config = function()
      -- vim.cmd.colorscheme("srcery")
    end
  },
  {
    "bluz71/vim-moonfly-colors",
    name = "moonfly",
    lazy = false,
    priority = 1000,
    config = function()
      -- vim.cmd.colorscheme("moonfly")
    end
  },
  {
    "nyoom-engineering/oxocarbon.nvim",
    config = function()
      -- vim.opt.background = "dark"
      -- vim.cmd.colorscheme("oxocarbon")
    end
  },
  {
    "nanotech/jellybeans.vim",
    config = function()
      -- vim.cmd.colorscheme("jellybeans")
    end
  },
  {
    "Mofiqul/vscode.nvim",
    lazy = false,
    priority = 1000,
  },
  {
    "luisiacc/gruvbox-baby"
  },
  { "miikanissi/modus-themes.nvim", priority = 1000 },
  {
    'olivercederborg/poimandres.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      require('poimandres').setup {
        -- leave this setup function empty for default config
        -- or refer to the configuration section
        -- for configuration options
      }
    end,

    -- optionally set the colorscheme within lazy config
    init = function()
      -- vim.cmd("colorscheme poimandres")
    end
  },
  {
    'ashish2508/Eezzy.nvim',
    config = function()
      require('Eezzy').setup({
        -- NOTE: if your configuration sets vim.o.background in your configuration for Neovim,
        -- the following setting will do nothing, since it'll be overriden.
        transparent = false, -- Boolean: Sets the background to transparent
        italics = {
          comments = true,   -- Boolean: Italicizes comments
          keywords = true,   -- Boolean: Italicizes keywords
          functions = true,  -- Boolean: Italicizes functions
          strings = true,    -- Boolean: Italicizes strings
          variables = true,  -- Boolean: Italicizes variables
        },
        overrides = {},      -- A dictionary of group names, can be a function returning a dictionary or a table.
      })
    end,

    init = function()
      -- vim.cmd("colorscheme Eezzy")
    end
  },
  { "adisen99/apprentice.nvim" },
  { "darkvoid-theme/darkvoid.nvim" }
}
