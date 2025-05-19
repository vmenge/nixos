local ignore = {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},

	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = {
			"WhoIsSethDaniel/mason-tool-installer.nvim",
		},
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"bashls",
					"csharp_ls",
					"clangd",
					"cssls",
					"dockerls",
					"docker_compose_language_service",
					"eslint",
					"elixirls",
					"elmls",
					"fsautocomplete",
					"html",
					"jsonls",
					"lua_ls",
					"marksman",
					"powershell_es",
					"pyright",
					"rescriptls",
					"sqlls",
					"svelte",
					"taplo",
					"tailwindcss",
					"terraformls",
					"vimls",
					"vuels",
					"yamlls",
					"zls",
				},
			})

			require("mason-lspconfig").setup_handlers({
				-- The first entry (without a key) will be the default handler
				-- and will be called for each installed server that doesn't have
				-- a dedicated handler.
				function(server_name) -- default handler (optional)
					require("lspconfig")[server_name].setup({})
				end,
				-- Next, you can provide a dedicated handler for specific servers.
				-- For example, a handler override for the `rust_analyzer`:
				-- ["rust_analyzer"] = function()
				-- 	require("rust-tools").setup({})
				-- end,
				--
			})

			local mason_tool_installer = require("mason-tool-installer")

			mason_tool_installer.setup({
				ensure_installed = {
					"prettier",
					"stylua",
					"isort",
					"black",
					"fantomas",
				},
			})
		end,
	},

	{
		"neovim/nvim-lspconfig",
		init = function()
			local lspconfig = require("lspconfig")
			local configs = require("lspconfig.configs")

			lspconfig.gdscript.setup({})
			lspconfig.roc_ls.setup({})
		end,
	},

	{ "rust-lang/rust.vim" },

	{
		"mrcjkb/rustaceanvim",
		version = "^4",
		lazy = false,
		dependencies = { "mfussenegger/nvim-dap" },
		ft = { "rust" },
		config = function()
			vim.g.rustaceanvim = {
				server = {
					on_attach = function(client, buffer)
						-- opt keymaps or other things here
					end,
					default_settings = {
						-- rust-analyzer language server configuration
						["rust-analyzer"] = {
							cargo = {
								allFeatures = true,
								loadOutDirsFromCheck = true,
								runBuildScripts = true,
							},
							-- Add clippy lints for Rust.
							checkOnSave = {
								allFeatures = true,
								command = "clippy",
								extraArgs = { "--no-deps" },
							},
							procMacro = {
								enable = true,
								ignored = {
									-- ["async-trait"] = { "async_trait" },
									["napi-derive"] = { "napi" },
									["async-recursion"] = { "async_recursion" },
								},
							},
						},
					},
				},
			}
		end,
	},

	{
		"Fymyte/rasi.vim",
		dependencies = { "Fymyte/tree-sitter-rasi" },
	},

	{
		"Lommix/godot.nvim",
		config = function()
			local godot = require("godot")
			local config = {
				bin = "godot",
			}
			godot.setup(config)
		end,
	},
}

return {}
