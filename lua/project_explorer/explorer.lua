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
			local command = string.format(
				"find %s -mindepth %d -maxdepth %d -type d -not -name '.git'",
				clean_path,
				min_depth,
				max_depth
			)
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
			local name = vim.fn.fnamemodify(entry, ":t")
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
	-- vim.cmd("Neotree close")
	vim.cmd("cd " .. dir)
	vim.cmd("bdelete")
	-- vim.cmd("Neotree" .. dir)
	vim.cmd("Explore")
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
		--		print("Project name cannot be empty.")
		callback()
		return
	end
	local base_dir = vim.fn.input("Enter base directory for the new project: ", "~/dev/")
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
					map({ "i", "n" }, "<C-S-f>", function()
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
