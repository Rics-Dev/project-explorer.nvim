local M = {}

function M.setup(opts)
	opts = opts or {}
	local config = require("project_explorer.config")
	config.config = vim.tbl_deep_extend("force", config.config, opts)
	-- You can add any configuration options here

	-- Create the user command
	vim.api.nvim_create_user_command("ProjectExplorer", function(cmd_opts)
		require("project_explorer.explorer").explore_projects(cmd_opts)
	end, {})
	vim.api.nvim_create_user_command("ProjectExplorerFavorites", function(cmd_opts)
		require("project_explorer.explorer").explore_favorite_projects(cmd_opts)
	end, {})
	-- Create a new user command for AddProject
	-- vim.api.nvim_create_user_command("ProjectExplorerAdd", function()
	-- 	require("project_explorer.explorer").add_project()
	-- end, {})
end

return M
