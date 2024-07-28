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

-- Helper Functions

local function get_dev_projects()
	local projects = {}
	local function scan_directory(path, parent)
		local handle = io.popen("find " .. path .. " -maxdepth 1 -type d")
		if handle then
			for line in handle:lines() do
				if line ~= path then
					local name = vim.fn.fnamemodify(line, ":t")
					local entry = { name = name, path = line, parent = parent, expanded = false, children = {} }
					table.insert(parent and parent.children or projects, entry)
					scan_directory(line, entry)
				end
			end
			handle:close()
		end
	end

	for _, path in ipairs(config.config.paths) do
		local clean_path = path:gsub("%*", "")
		scan_directory(clean_path)
	end
	return projects
end

-- Finder Creation

local function create_finder()
	local results = get_dev_projects()

	local displayer = entry_display.create({
		separator = " ",
		items = {
			{ width = 30 },
			{ remaining = true },
		},
	})

	local function make_display(entry)
		local indent = string.rep("  ", entry.depth or 0)
		local icon = entry.expanded and "▼ " or "▶ "
		return displayer({ indent .. icon .. entry.name, { entry.path, "Comment" } })
	end

	local function flatten_results(items, depth, parent)
		local flat = {}
		for _, item in ipairs(items) do
			item.depth = depth
			item.parent = parent
			table.insert(flat, item)
			if item.expanded then
				for _, child in ipairs(flatten_results(item.children, depth + 1, item)) do
					table.insert(flat, child)
				end
			end
		end
		return flat
	end

	return finders.new_table({
		results = flatten_results(results, 0, nil),
		entry_maker = function(entry)
			return {
				value = entry,
				display = make_display,
				ordinal = entry.path,
			}
		end,
	})
end

-- Actions

local function toggle_directory(prompt_bufnr)
	local selected_entry = state.get_selected_entry()
	if selected_entry == nil then
		return
	end
	local entry = selected_entry.value

	if vim.fn.isdirectory(entry.path) == 1 then
		entry.expanded = not entry.expanded
		actions.close(prompt_bufnr)
		M.explore_projects() -- Reopen the picker with updated state
	end
end

local function change_working_directory(prompt_bufnr)
	local selected_entry = state.get_selected_entry()
	if selected_entry == nil then
		actions.close(prompt_bufnr)
		return
	end
	local entry = selected_entry.value

	if not vim.fn.isdirectory(entry.path) == 1 then
		actions.close(prompt_bufnr)
		vim.cmd("Neotree close")
		vim.cmd("cd " .. entry.path)
		vim.cmd("bdelete")
		vim.cmd("Neotree " .. entry.path)
	end
end

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

local function delete_project(callback)
	local selected_entry = state.get_selected_entry()
	if selected_entry == nil then
		callback()
		return
	end

	local dir = selected_entry.value.path
	local confirm = vim.fn.input("Are you sure you want to delete " .. dir .. "? (y/n): ")
	if confirm:lower() ~= "y" then
		print("Project deletion cancelled.")
		callback()
		return
	end

	local success, error_msg = os.execute("rm -rf " .. dir)
	if success then
		print("Project deleted successfully: " .. dir)
	else
		print("Failed to delete project. Error: " .. tostring(error_msg))
	end

	callback()
end

-- Main Function

function M.explore_projects(opts)
	opts = opts or {}

	pickers
		.new(opts, {
			prompt_title = "Project Explorer",
			finder = create_finder(),
			previewer = false,
			sorter = telescope_config.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					change_working_directory(prompt_bufnr)
				end)

				-- Map right arrow to expand directory
				map("i", "<Right>", function()
					toggle_directory(prompt_bufnr)
				end)
				map("n", "<Right>", function()
					toggle_directory(prompt_bufnr)
				end)

				-- Map left arrow to collapse directory
				map("i", "<Left>", function()
					local selected_entry = state.get_selected_entry()
					if selected_entry and selected_entry.value.parent then
						selected_entry.value.parent.expanded = false
						actions.close(prompt_bufnr)
						M.explore_projects(opts)
					end
				end)
				map("n", "<Left>", function()
					local selected_entry = state.get_selected_entry()
					if selected_entry and selected_entry.value.parent then
						selected_entry.value.parent.expanded = false
						actions.close(prompt_bufnr)
						M.explore_projects(opts)
					end
				end)

				-- Keep the existing mappings
				map({ "i", "n" }, "<C-a>", function()
					add_project(function()
						actions.close(prompt_bufnr)
						M.explore_projects(opts)
					end)
				end)

				map({ "i", "n" }, "<C-d>", function()
					delete_project(function()
						actions.close(prompt_bufnr)
						M.explore_projects(opts)
					end)
				end)

				return true
			end,
		})
		:find()
end

-- Expose the main function and add_project function
M.add_project = add_project

return M
