local M = {}

function M.setup(opts)
	opts = opts or {}
	-- You can add any configuration options here

	-- Ensure the command is created even if the plugin is lazy-loaded
	vim.api.nvim_create_user_command("ProjectExplorer", function()
		require("project_explorer.explorer").explore_projects()
	end, {})
end

-- Add this function to allow direct calling
function M.explore_projects()
	require("project_explorer.explorer").explore_projects()
end

return M
