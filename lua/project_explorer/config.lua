local M = {}

M.config = {
	paths = { "~/dev", "~/projects" }, -- Default paths
	newProjectPath = nil,
	file_explorer = nil,
	post_open_hook = function(dir)
		-- Save the current session before switching
		require("project_explorer").save_current_session()

		-- Close all buffers
		vim.cmd("bufdo bwipeout")

		-- Change to the new directory
		vim.cmd("cd " .. dir)

		-- Load the session for the new project
		local session_file = vim.fn.stdpath("data") .. "/sessions/" .. vim.fn.fnamemodify(dir, ":t") .. ".vim"
		if vim.fn.filereadable(session_file) == 1 then
			vim.cmd("source " .. session_file)
		else
			if M.config.file_explorer then
				M.config.file_explorer(dir)
			else
				vim.cmd("Explore")
			end
		end
	end,
}

return M
