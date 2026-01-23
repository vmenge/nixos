return {
	{
		"hrsh7th/nvim-cmp",
		version = false, -- last release is way too old
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"saadparwaiz1/cmp_luasnip",
		},
		opts = function()
			vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
			local cmp = require("cmp")
			local defaults = require("cmp.config.default")()
			return {
				completion = {
					completeopt = "menu,menuone,noinsert",
				},
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-j>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
					["<C-k>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
					["<S-CR>"] = cmp.mapping.confirm({
						behavior = cmp.ConfirmBehavior.Replace,
						select = true,
					}), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp", priority = 1000 },
					{ name = "luasnip", priority = 900 },
					{ name = "buffer", priority = 800 },
					{ name = "path", priority = 800 },
				}),
				formatting = {
					format = function(_, item)
						local icons = require("vmenge.config.icons").kinds
						if icons[item.kind] then
							item.kind = icons[item.kind] .. item.kind
						end
						return item
					end,
				},
				experimental = {
					ghost_text = {
						hl_group = "CmpGhostText",
					},
				},
				sorting = defaults.sorting,
			}
		end,
	},
	{
		"L3MON4D3/LuaSnip",
		-- follow latest release.
		version = "2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
		-- install jsregexp (optional!).
		build = "make install_jsregexp",
	},
}

-- return {
--   'saghen/blink.cmp',
--   dependencies = {
--     'rafamadriz/friendly-snippets', 'Kaiser-Yang/blink-cmp-avante',
--   },
--   version = '1.*',
--   ---@module 'blink.cmp'
--   ---@type blink.cmp.Config
--   opts = {
--     -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
--     -- 'super-tab' for mappings similar to vscode (tab to accept)
--     -- 'enter' for enter to accept
--     -- 'none' for no mappings
--     --
--     -- All presets have the following mappings:
--     -- C-space: Open menu or open docs if already open
--     -- C-n/C-p or Up/Down: Select next/previous item
--     -- C-e: Hide menu
--     -- C-k: Toggle signature help (if signature.enabled = true)
--     --
--     -- See :h blink-cmp-config-keymap for defining your own keymap
--     keymap = { preset = 'enter' },
--
--     appearance = {
--       -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
--       -- Adjusts spacing to ensure icons are aligned
--       nerd_font_variant = 'mono'
--     },
--
--     completion = {
--       documentation = { auto_show = false },
--       trigger = {
--         show_on_trigger_character = true,
--         show_on_insert_on_trigger_character = true,
--       },
--     },
--
--     -- Default list of enabled providers defined so that you can extend it
--     -- elsewhere in your config, without redefining it, due to `opts_extend`
--     sources = {
--       default = { 'lsp', 'avante', 'path', 'snippets', 'buffer' },
--       providers = {
--         avante = {
--           module = 'blink-cmp-avante',
--           name = 'Avante',
--           opts = {}
--         }
--       },
--     },
--
--     -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
--     -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
--     -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
--     --
--     -- See the fuzzy documentation for more information
--     fuzzy = { implementation = "prefer_rust_with_warning" }
--   },
--   opts_extend = { "sources.default" }
-- }
