return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		dependencies = { "nvim-lua/plenary.nvim" },
    priority = 1000,
		opts = {
			pickers = {
				find_files = { hidden = true },
				grep_string = { hidden = true, additional_args = { "--hidden" } },
				live_grep = { hidden = true, additional_args = { "--hidden" } },
			},

			defaults = {
				mappings = {
					i = {
						["<C-j>"] = function(...)
							return require("telescope.actions").move_selection_next(...)
						end,
						["<C-k>"] = function(...)
							return require("telescope.actions").move_selection_previous(...)
						end,
					},
				},
			},
		},
	},
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		build = "cmake -S. -Bbuild -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
	},
	{
		"aznhe21/actions-preview.nvim",
		config = function()
			require("actions-preview").setup()
		end,
		opts = {
			telescope = {
				sorting_strategy = "ascending",
				layout_strategy = "vertical",
				layout_config = {
					width = 0.8,
					height = 0.9,
					prompt_position = "top",
					preview_cutoff = 20,
					preview_height = function(_, _, max_lines)
						return max_lines - 15
					end,
				},
			},
		},
	},
}
