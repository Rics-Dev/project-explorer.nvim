local M = {}

local function save_current_session()
	local current_dir = vim.fn.getcwd()
	local session_file = vim.fn.stdpath("data") .. "/sessions/" .. vim.fn.fnamemodify(current_dir, ":t") .. ".vim"
	vim.cmd("mksession! " .. session_file)
end

function M.setup(opts)
	opts = opts or {}
	local config = require("project_explorer.config")
	config.config = vim.tbl_deep_extend("force", config.config, opts)

	vim.api.nvim_create_user_command("ProjectExplorer", function(cmd_opts)
		require("project_explorer.explorer").explore_projects(cmd_opts)
	end, {})

	-- Create sessions directory if it doesn't exist
	local session_dir = vim.fn.stdpath("data") .. "/sessions"
	if vim.fn.isdirectory(session_dir) == 0 then
		vim.fn.mkdir(session_dir, "p")
	end

	-- Set up autocmd to save session on exit
	vim.api.nvim_create_autocmd("VimLeavePre", {
		callback = function()
			save_current_session()
		end,
	})
end

M.save_current_session = save_current_session

return M
