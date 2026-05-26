return {
	"nvim-mini/mini.files",
	version = false,
	opts = {
		windows = {
			preview = false,
			width_focus = 60,
			width_preview = 30,
		},
		options = {
			use_as_default_explorer = true,
		},
	},
	keys = {
		{
			"<leader>e",
			function()
				require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
			end,
			desc = "mini.files (current file)",
		},
		{
			"<leader>E",
			function()
				require("mini.files").open(vim.loop.cwd(), true)
			end,
			desc = "mini.files (cwd)",
		},
	},
	config = function(_, opts)
		require("mini.files").setup(opts)

		local sanitize_lsp_file_operation_filters = function(client)
			local workspace = client.server_capabilities and client.server_capabilities.workspace
			local file_operations = workspace and workspace.fileOperations

			if type(file_operations) ~= "table" then
				return
			end

			for _, operation_name in ipairs({
				"didCreate",
				"didDelete",
				"didRename",
				"willCreate",
				"willDelete",
				"willRename",
			}) do
				local operation = file_operations[operation_name]
				local filters = type(operation) == "table" and operation.filters or nil

				if type(filters) == "table" then
					for _, filter in ipairs(filters) do
						if type(filter.scheme) ~= "string" then
							filter.scheme = nil
						end
					end
				end
			end
		end

		for _, client in ipairs(vim.lsp.get_clients()) do
			sanitize_lsp_file_operation_filters(client)
		end

		vim.api.nvim_create_autocmd("LspAttach", {
			callback = function(args)
				local client = vim.lsp.get_client_by_id(args.data.client_id)
				if client then
					sanitize_lsp_file_operation_filters(client)
				end
			end,
		})

		local show_dotfiles = true
		local filter_show = function(fs_entry)
			return true
		end
		local filter_hide = function(fs_entry)
			return not vim.startswith(fs_entry.name, ".")
		end

		local toggle_dotfiles = function()
			show_dotfiles = not show_dotfiles
			local new_filter = show_dotfiles and filter_show or filter_hide
			require("mini.files").refresh({ content = { filter = new_filter } })
		end

		vim.api.nvim_create_autocmd("User", {
			pattern = "MiniFilesBufferCreate",
			callback = function(args)
				local buf_id = args.data.buf_id
				-- Tweak left-hand side of mapping to your liking
				vim.keymap.set("n", "g.", toggle_dotfiles, { buffer = buf_id })
			end,
		})
	end,
}
