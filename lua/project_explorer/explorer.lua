-- local M = {}
--
-- local has_telescope = pcall(require, "telescope")
-- if not has_telescope then
-- 	return M
-- end
--
-- local finders = require("telescope.finders")
-- local pickers = require("telescope.pickers")
-- local telescope_config = require("telescope.config").values
-- local actions = require("telescope.actions")
-- local state = require("telescope.actions.state")
-- local entry_display = require("telescope.pickers.entry_display")
--
-- local config = require("project_explorer.config")
-- ---
-- ----------
-- -- Actions
-- ----------
--
-- local function get_depth_from_path(path)
-- 	local _, count = path:gsub("%*", "")
-- 	return count
-- end
--
-- local function get_dev_projects()
-- 	local projects = {}
-- 	--	local handle = io.popen("find ~/dev -mindepth 2 -maxdepth 2 -type d")
-- 	for _, path in ipairs(config.config.paths) do
-- 		local depth = get_depth_from_path(path)
-- 		local min_depth = depth + 1
-- 		local max_depth = depth + 1
-- 		local clean_path = path:gsub("%*", "")
-- 		local command = string.format(
-- 			"find %s -mindepth %d -maxdepth %d -type d -not -name '.git'",
-- 			clean_path,
-- 			min_depth,
-- 			max_depth
-- 		)
-- 		local handle = io.popen(command)
-- 		if handle then
-- 			for line in handle:lines() do
-- 				table.insert(projects, line)
-- 			end
-- 			handle:close()
-- 		end
-- 	end
-- 	return projects
-- end
--
-- local function create_finder()
-- 	local results = get_dev_projects()
--
-- 	local displayer = entry_display.create({
-- 		separator = " ",
-- 		items = {
-- 			{
-- 				width = 30,
-- 			},
-- 			{
-- 				remaining = true,
-- 			},
-- 		},
-- 	})
--
-- 	local function make_display(entry)
-- 		return displayer({ entry.name, { entry.value, "Comment" } })
-- 	end
--
-- 	return finders.new_table({
-- 		results = results,
-- 		entry_maker = function(entry)
-- 			local name = vim.fn.fnamemodify(entry, ":t")
-- 			return {
-- 				display = make_display,
-- 				name = name,
-- 				value = entry,
-- 				ordinal = name .. " " .. entry,
-- 			}
-- 		end,
-- 	})
-- end
--
-- local function change_working_directory(prompt_bufnr)
-- 	local selected_entry = state.get_selected_entry()
-- 	if selected_entry == nil then
-- 		actions.close(prompt_bufnr)
-- 		return
-- 	end
-- 	local dir = selected_entry.value
-- 	actions.close(prompt_bufnr)
-- 	vim.cmd("Neotree close")
-- 	vim.cmd("cd " .. dir)
-- 	vim.cmd("bdelete")
-- 	vim.cmd("Neotree" .. dir)
-- 	--vim.cmd("Explore")
-- end
--
-- local function add_project(callback)
-- 	local project_name = vim.fn.input("Enter new project name: ")
-- 	if project_name == "" then
-- 		--		print("Project name cannot be empty.")
-- 		callback()
-- 		return
-- 	end
-- 	local base_dir = vim.fn.input("Enter base directory for the new project: ", "~/dev/")
-- 	local full_path = vim.fn.expand(base_dir .. "/" .. project_name)
-- 	print("Attempting to create directory: " .. full_path)
-- 	local success, error_msg = vim.fn.mkdir(full_path, "p")
-- 	if success == 1 then
-- 		print("Project directory created: " .. full_path)
-- 		if vim.fn.isdirectory(full_path) == 1 then
-- 			print("Project created successfully: " .. full_path)
-- 		else
-- 			print("Directory created but not found. Current working directory: " .. vim.fn.getcwd())
-- 		end
-- 	else
-- 		print("Failed to create project directory. Error: " .. tostring(error_msg))
-- 	end
-- 	callback()
-- end
--
-- local function delete_project(callback)
-- 	local selected_entry = state.get_selected_entry()
-- 	if selected_entry == nil then
-- 		callback()
-- 		return
-- 	end
--
-- 	local dir = selected_entry.value
-- 	-- Prompt for confirmation
-- 	local confirm = vim.fn.input("Are you sure you want to delete " .. dir .. "? (y/n): ")
-- 	if confirm:lower() ~= "y" then
-- 		print("Project deletion cancelled.")
-- 		callback()
-- 		return
-- 	end
--
-- 	-- Attempt to delete the directory
-- 	local success, error_msg = os.execute("rm -rf " .. dir)
-- 	if success then
-- 		print("Project deleted successfully: " .. dir)
-- 	else
-- 		print("Failed to delete project. Error: " .. tostring(error_msg))
-- 	end
--
-- 	callback()
-- end
--
-- local function explore_projects(opts)
-- 	opts = opts or {}
--
-- 	local function recreate_picker()
-- 		pickers
-- 			.new(opts, {
-- 				prompt_title = "Project Explorer",
-- 				finder = create_finder(),
-- 				previewer = false,
-- 				sorter = telescope_config.generic_sorter(opts),
-- 				attach_mappings = function(prompt_bufnr, map)
-- 					local on_project_selected = function()
-- 						change_working_directory(prompt_bufnr)
-- 					end
-- 					local on_delete_project = function()
-- 						delete_project(function()
-- 							actions.close(prompt_bufnr)
-- 							recreate_picker()
-- 						end)
-- 					end
-- 					actions.select_default:replace(on_project_selected)
--
-- 					map({ "i", "n" }, "<C-a>", function()
-- 						add_project(function()
-- 							actions.close(prompt_bufnr)
-- 							recreate_picker()
-- 						end)
-- 					end)
--
-- 					map({ "i", "n" }, "<C-d>", on_delete_project)
--
-- 					return true
-- 				end,
-- 			})
-- 			:find()
-- 	end
--
-- 	recreate_picker()
-- end
--
-- -- Expose the main function
-- M.explore_projects = explore_projects
-- M.add_project = add_project
--
-- return M
--

local M = {}

local has_telescope, telescope = pcall(require, "telescope")
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

local expanded_dirs = {}

-- Helper function to get the depth of a directory
local function get_depth_from_path(path)
	local _, count = path:gsub("%*", "")
	return count
end

-- Helper function to get the tree structure of directories
local function get_tree_structure(root_dir, depth)
	local tree = {}
	local command = string.format("find %s -mindepth %d -maxdepth %d -type d -not -name '.git'", root_dir, depth, depth)
	local handle = io.popen(command)
	if handle then
		for line in handle:lines() do
			local parent_dir = line:match("(.+)/[^/]+$")
			if not tree[parent_dir] then
				tree[parent_dir] = {}
			end
			table.insert(tree[parent_dir], line)
		end
		handle:close()
	end
	return tree
end

-- Helper function to recursively add entries to the results
local function add_to_results(results, path, depth)
	local dirs = expanded_dirs[path] and get_tree_structure(path, depth + 1) or {}
	for _, dir in ipairs(dirs[path] or {}) do
		table.insert(results, { path = dir, depth = depth })
		add_to_results(results, dir, depth + 1)
	end
end

-- Create a new finder for Telescope
local function create_finder()
	local results = {}
	local tree = get_tree_structure("~/dev", 2)

	add_to_results(results, "~/dev", 1)

	local displayer = entry_display.create({
		separator = " ",
		items = {
			{ width = 30 },
			{ remaining = true },
		},
	})

	local function make_display(entry)
		return displayer({ entry.path, { entry.depth, "Comment" } })
	end

	return finders.new_table({
		results = results,
		entry_maker = function(entry)
			local name = vim.fn.fnamemodify(entry.path, ":t")
			return {
				display = make_display,
				name = name,
				value = entry.path,
				ordinal = name .. " " .. entry.path,
				depth = entry.depth,
			}
		end,
	})
end

-- Change the working directory and open Neotree
local function change_working_directory(prompt_bufnr)
	local selected_entry = state.get_selected_entry()
	if selected_entry == nil then
		actions.close(prompt_bufnr)
		return
	end
	local dir = selected_entry.value
	actions.close(prompt_bufnr)
	vim.cmd("Neotree close")
	vim.cmd("cd " .. dir)
	vim.cmd("bdelete")
	vim.cmd("Neotree " .. dir)
end

-- Add a new project directory
local function add_project(callback)
	local project_name = vim.fn.input("Enter new project name: ")
	if project_name == "" then
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

-- Delete a project directory
local function delete_project(callback)
	local selected_entry = state.get_selected_entry()
	if selected_entry == nil then
		callback()
		return
	end

	local dir = selected_entry.value
	-- Prompt for confirmation
	local confirm = vim.fn.input("Are you sure you want to delete " .. dir .. "? (y/n): ")
	if confirm:lower() ~= "y" then
		print("Project deletion cancelled.")
		callback()
		return
	end

	-- Attempt to delete the directory
	local success, error_msg = os.execute("rm -rf " .. dir)
	if success then
		print("Project deleted successfully: " .. dir)
	else
		print("Failed to delete project. Error: " .. tostring(error_msg))
	end

	callback()
end

-- Function to toggle the expanded state of a directory
local function toggle_entry(entry)
	if expanded_dirs[entry.path] then
		expanded_dirs[entry.path] = nil
	else
		expanded_dirs[entry.path] = true
	end
end

-- Function to handle expanding a directory
local function expand_entry()
	local entry = state.get_selected_entry()
	if entry then
		toggle_entry(entry)
		-- Update the results to include subdirectories based on expanded_dirs
		recreate_picker()
	end
end

-- Function to handle collapsing a directory
local function collapse_entry()
	local entry = state.get_selected_entry()
	if entry then
		toggle_entry(entry)
		-- Update the results to exclude subdirectories
		recreate_picker()
	end
end

-- Function to recreate the Telescope picker
local function recreate_picker()
	pickers
		.new({}, {
			prompt_title = "Project Explorer",
			finder = create_finder(),
			previewer = false,
			sorter = telescope_config.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				local on_project_selected = function()
					change_working_directory(prompt_bufnr)
				end
				local on_delete_project = function()
					delete_project(function()
						actions.close(prompt_bufnr)
						recreate_picker()
					end)
				end
				actions.select_default:replace(on_project_selected)

				map({ "i", "n" }, "<CR>", on_project_selected)
				map({ "i", "n" }, "<C-a>", function()
					add_project(function()
						actions.close(prompt_bufnr)
						recreate_picker()
					end)
				end)
				map({ "i", "n" }, "<C-d>", function()
					delete_project(function()
						actions.close(prompt_bufnr)
						recreate_picker()
					end)
				end)
				map({ "i", "n" }, "<C-e>", expand_entry) -- Expand
				map({ "i", "n" }, "<C-c>", collapse_entry) -- Collapse

				return true
			end,
		})
		:find()
end

-- Expose the main function
M.explore_projects = function(opts)
	opts = opts or {}
	recreate_picker()
end

M.add_project = add_project

return M
