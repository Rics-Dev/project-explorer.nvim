local M = {}

M.config = {
	paths = { "~/dev", "~/projects" }, -- Default paths
	post_open_hook = nil,
	-- post_open_hook = function(dir)
	-- 	local session_file = vim.fn.stdpath("data") .. "/sessions/" .. vim.fn.fnamemodify(dir, ":t") .. ".vim"
	-- 	if vim.fn.filereadable(session_file) == 1 then
	-- 		vim.cmd("source " .. session_file)
	-- 	else
	-- 		vim.cmd("Explore")
	-- 	end
	-- end,
}

return M
