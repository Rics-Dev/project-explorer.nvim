local M = {}

function M.setup(opts)
	opts = opts or {}
	local config = require("project_explorer.config")
	config.config = vim.tbl_deep_extend("force", config.config, opts)

	-- Create the user command for exploring projects
	vim.api.nvim_create_user_command("ProjectExplorer", function(cmd_opts)
		require("project_explorer.explorer").explore_projects(cmd_opts)
	end, {})

	-- Create the user command for adding a project
	vim.api.nvim_create_user_command("ProjectExplorerAdd", function()
		require("project_explorer.explorer").add_project()
	end, {})
end

return M
