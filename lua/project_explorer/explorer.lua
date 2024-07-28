require("lfs")
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

local function get_depth_from_path(path)
	local _, count = path:gsub("%*", "")
	return count
end

local function get_dev_projects()
	local projects = {}
	--	local handle = io.popen("find ~/dev -mindepth 2 -maxdepth 2 -type d")
	for _, path in ipairs(config.config.paths) do
		local depth = get_depth_from_path(path)
		local min_depth = depth + 1
		local max_depth = depth + 1
		local clean_path = path:gsub("%*", "")
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
	return projects
end

local function create_finder()
	local results = get_dev_projects()

	local displayer = entry_display.create({
		separator = " ",
		items = {
			{
				width = 30,
			},
			{
				remaining = true,
			},
		},
	})

	local function make_display(entry)
		return displayer({ entry.name, { entry.value, "Comment" } })
	end

	return finders.new_table({
		results = results,
		entry_maker = function(entry)
			local name = vim.fn.fnamemodify(entry, ":t")
			return {
				display = make_display,
				name = name,
				value = entry,
				ordinal = name .. " " .. entry,
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
	vim.cmd("Neotree close")
	vim.cmd("cd " .. dir)
	vim.cmd("bdelete")
	vim.cmd("Neotree" .. dir)
	--vim.cmd("Explore")
end

local function explore_projects(opts)
	opts = opts or {}
	pickers
		.new(opts, {
			prompt_title = "Project Explorer",
			finder = create_finder(),
			previewer = false,
			sorter = telescope_config.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr)
				local on_project_selected = function()
					change_working_directory(prompt_bufnr)
				end
				actions.select_default:replace(on_project_selected)
				return true
			end,
		})
		:find()
end

local function add_project(opts)
	opts = opts or {}
	local action = function(prompt_bufnr)
		local project_name = state.get_current_line()
		actions.close(prompt_bufnr)

		-- Ask for the base directory
		local base_dir = vim.fn.input("Enter base directory for the new project: ", "~/dev/")

		-- Create the full path
		local full_path = base_dir .. "/" .. project_name

		-- Create the directory
		local success, error_msg = lfs.mkdir(full_path)
		if success then
			print("Project directory created: " .. full_path)
			-- Optionally, change to the new directory
			vim.cmd("cd " .. full_path)
		else
			print("Failed to create project directory: " .. error_msg)
		end
	end

	pickers
		.new(opts, {
			prompt_title = "Add New Project",
			finder = finders.new_table({
				results = { "" },
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry,
						ordinal = entry,
					}
				end,
			}),
			sorter = telescope_config.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				map("i", "<CR>", action)
				map("n", "<CR>", action)
				return true
			end,
		})
		:find()
end

-- Expose the main function
M.explore_projects = explore_projects
M.add_project = add_project

return M
