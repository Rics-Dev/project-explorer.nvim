local M = {}

local has_telescope = pcall(require, "telescope")
if not has_telescope then
	return M
end

local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local telescope_config = require("telescope.config").values
local actions = require("telescope.actions")
local state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")

local config = require("project_explorer.config")
---
----------
-- Actions
----------
local function get_favorites_file()
	return vim.fn.stdpath("data") .. "/project_explorer_favorites.txt"
end

local function get_last_opened_file()
	return vim.fn.stdpath("data") .. "/project_explorer_last_opened.txt"
end

local function load_last_opened()
	local last_opened = {}
	local file = io.open(get_last_opened_file(), "r")
	if file then
		for line in file:lines() do
			local path, timestamp = line:match("(.+),(%d+)")
			if path and timestamp then
				last_opened[path] = tonumber(timestamp)
			end
		end
		file:close()
	end
	return last_opened
end

local function save_last_opened(last_opened)
	local file = io.open(get_last_opened_file(), "w")
	if file then
		for path, timestamp in pairs(last_opened) do
			file:write(string.format("%s,%d\n", path, timestamp))
		end
		file:close()
	end
end

local function update_last_opened(path)
	local last_opened = load_last_opened()
	last_opened[path] = os.time()
	save_last_opened(last_opened)
end

local function load_favorites()
	local favorites = {}
	local file = io.open(get_favorites_file(), "r")
	if file then
		for line in file:lines() do
			favorites[line] = true
		end
		file:close()
	end
	return favorites
end

local function save_favorites(favorites)
	local file = io.open(get_favorites_file(), "w")
	if file then
		for path, _ in pairs(favorites) do
			file:write(path .. "\n")
		end
		file:close()
	end
end

local function get_depth_from_path(path)
	local _, count = path:gsub("%*", "")
	return count
end

local function get_dev_projects()
	local projects = {}
	for _, path in ipairs(config.config.paths) do
		-- Expand wildcards in paths
		local expanded_paths = vim.fn.glob(path, false, true)
		if type(expanded_paths) == "string" then
			expanded_paths = { expanded_paths }
		end

		for _, expanded_path in ipairs(expanded_paths) do
			local depth = get_depth_from_path(expanded_path)
			local min_depth = depth + 1
			local max_depth = depth + 1
			local clean_path = expanded_path:gsub("%*", "")
			local command = string.format(config.config.command_pattern, clean_path, min_depth, max_depth)

			local handle = io.popen(command)
			if handle then
				for line in handle:lines() do
					table.insert(projects, line)
				end
				handle:close()
			end
		end
	end
	return projects
end

local function create_finder(favorites_only)
	local results = get_dev_projects()
	local favorites = load_favorites()
	local last_opened = load_last_opened()

	-- Sort results by last opened time
	table.sort(results, function(a, b)
		local time_a = last_opened[a] or 0
		local time_b = last_opened[b] or 0
		return time_a > time_b
	end)

	local displayer = entry_display.create({
		separator = " ",
		items = {
			{ width = 2 },
			{ width = 30 },
			{ remaining = true },
		},
	})

	local function make_display(entry)
		local favorite_icon = entry.is_favorite and "★" or ""
		return displayer({ favorite_icon, entry.name, { entry.value, "Comment" } })
	end

	return finders.new_table({
		-- results = results,
		results = favorites_only and vim.tbl_filter(function(entry)
			return favorites[entry]
		end, results) or results,
		entry_maker = function(entry)
			-- Removes the trailing slash that is always included within windows
			local normalized_path = vim.fn.fnamemodify(entry, ":p:h")
			local name = vim.fn.fnamemodify(normalized_path, ":t")
			return {
				display = make_display,
				name = name,
				value = entry,
				ordinal = name .. " " .. entry,
				is_favorite = favorites[entry] or false,
			}
		end,
	})
end

local function change_working_directory(prompt_bufnr)
	local selected_entry = state.get_selected_entry()
	if selected_entry == nil then
		actions.close(prompt_bufnr)
		return
	end
	local dir = selected_entry.value
	actions.close(prompt_bufnr)

	-- Call the post_open_hook
	if config.config.post_open_hook then
		config.config.post_open_hook(dir)
	end

	update_last_opened(dir)
end

local function toggle_favorite(callback)
	local selected_entry = state.get_selected_entry()
	if selected_entry == nil then
		return
	end

	local favorites = load_favorites()
	local path = selected_entry.value

	if favorites[path] then
		favorites[path] = nil
	else
		favorites[path] = true
	end

	save_favorites(favorites)
	callback()
	-- actions.close(prompt_bufnr)
	-- explore_projects()
end

local function add_project(callback)
	local project_name = vim.fn.input("Enter new project name: ")
	if project_name == "" then
		callback()
		return
	end
	local base_dir
	if config.config.newProjectPath then
		base_dir = vim.fn.input("Enter base directory for the new project: ", config.config.newProjectPath)
	else
		base_dir = vim.fn.input("Enter base directory for the new project: ", "~/")
	end
	local full_path = vim.fn.expand(base_dir .. "/" .. project_name)
	print("Attempting to create directory: " .. full_path)
	local success, error_msg = vim.fn.mkdir(full_path, "p")
	if success == 1 then
		print("Project directory created: " .. full_path)
		if vim.fn.isdirectory(full_path) == 1 then
			print("Project created successfully: " .. full_path)
		else
			print("Directory created but not found. Current working directory: " .. vim.fn.getcwd())
		end
	else
		print("Failed to create project directory. Error: " .. tostring(error_msg))
	end
	callback()
end

-- local function delete_project(prompt_bufnr)
-- 	local selected_entry = state.get_selected_entry()
-- 	if selected_entry == nil then
-- 		actions.close(prompt_bufnr)
-- 		return
-- 	end
-- 	local dir = selected_entry.value
-- 	-- Prompt for confirmation
-- 	local confirm = vim.fn.input("Are you sure you want to delete " .. dir .. "? (y/n): ")
-- 	if confirm:lower() ~= "y" then
-- 		print("Project deletion cancelled.")
-- 		return
-- 	end
--
-- 	-- Change to home directory
-- 	local home_dir = os.getenv("HOME")
-- 	if not home_dir then
-- 		print("Failed to get home directory.")
-- 		return
-- 	end
--
-- 	local success, error_msg = vim.cmd("cd " .. home_dir)
-- 	if not success then
-- 		print("Failed to change to home directory. Error: " .. tostring(error_msg))
-- 		return
-- 	end
--
-- 	-- Attempt to delete the directory
-- 	success, error_msg = os.execute("rm -rf " .. dir)
-- 	if success then
-- 		actions.close(prompt_bufnr)
-- 		print("Project deleted successfully: " .. dir)
-- 	else
-- 		print("Failed to delete project. Error: " .. tostring(error_msg))
-- 	end
-- end

local function explore_projects(opts)
	opts = opts or {}
	local favorites_only = false
	local function recreate_picker()
		pickers
			.new(opts, {
				prompt_title = favorites_only and "Favorite Projects" or "Project Explorer",
				finder = create_finder(favorites_only),
				previewer = false,
				sorter = telescope_config.generic_sorter(opts),
				attach_mappings = function(prompt_bufnr, map)
					local on_project_selected = function()
						change_working_directory(prompt_bufnr)
					end
					-- local on_delete_project = function()
					-- 	delete_project(prompt_bufnr)
					-- end
					actions.select_default:replace(on_project_selected)

					map({ "i", "n" }, "<C-a>", function()
						add_project(function()
							actions.close(prompt_bufnr)
							recreate_picker()
						end)
					end)

					-- map({ "i", "n" }, "<C-d>", on_delete_project)
					-- Add favorite toggling
					map({ "i", "n" }, "<C-A-f>", function()
						toggle_favorite(function()
							actions.close(prompt_bufnr)
							recreate_picker()
						end)
					end)
					map({ "i", "n" }, "<C-f>", function()
						favorites_only = not favorites_only
						actions.close(prompt_bufnr)
						recreate_picker()
					end)

					return true
				end,
			})
			:find()
	end

	recreate_picker()
end

-- Expose the main function
M.explore_projects = explore_projects
M.add_project = add_project

return M
