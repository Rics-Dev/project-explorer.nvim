local M = {}

function M.setup(opts)
	opts = opts or {}
	-- You can add any configuration options here

	-- Create the user command
	vim.api.nvim_create_user_command("ProjectExplorer", function(cmd_opts)
		require("project_explorer.explorer").explore_projects(cmd_opts)
	end, {})
end

return M
