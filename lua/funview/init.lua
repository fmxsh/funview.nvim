local M = {}

--local log = require("wswrite").log

local context = "ctx_funview"

-- Map file extensions to language-specific functions
local language_handlers = {
	lua = require("funview.parsers.lua"),
	php = require("funview.parsers.php"),
	javascript = require("funview.parsers.javascript"),
	bash = require("funview.parsers.bash"),
	markdown = require("funview.parsers.markdown"),
	c = require("funview.parsers.c"),
}

local last_buffer_we_bound_to = nil

-- Function to detect language by file extension and call appropriate function
local function get_functions()
	-- Detect the filetype of the current buffer
	local filetype = vim.bo.filetype
	--log("filetype: " .. filetype)
	--log("file: " .. vim.api.nvim_buf_get_name(0))
	-- Get the appropriate function handler based on the filetype
	local handler = language_handlers[filetype]
	--	local handler = require("funview.parsers." .. filetype)
	if handler then
		return handler() -- Call the language-specific function
	else
		-- Return an empty table for unsupported filetypes
		return {}
	end
end

-- Shared function to generate a unique key for a function name
--local function generate_unique_key(func_name, assigned_keys)
--	local key = nil
--	local func_name_cleaned = func_name:gsub("[^%w]", "") -- Remove non-alphanumeric characters
--
--	-- Iterate through the letters in the cleaned function name to find an available key
--	for i = 1, #func_name_cleaned do
--		local candidate_key = func_name_cleaned:sub(i, i):lower()
--		if not assigned_keys[candidate_key] then
--			key = candidate_key
--			assigned_keys[candidate_key] = true -- Mark the key as assigned
--			return key
--		end
--	end
--
--	-- Fallback: Iterate through lowercase alphabet
--	for i = 97, 122 do -- ASCII codes for 'a' to 'z'
--		local candidate_key = string.char(i)
--		if not assigned_keys[candidate_key] then
--			key = candidate_key
--			assigned_keys[candidate_key] = true
--			return key
--		end
--	end
--
--	-- Fallback: Iterate through uppercase alphabet
--	for i = 65, 90 do -- ASCII codes for 'A' to 'Z'
--		local candidate_key = string.char(i)
--		if not assigned_keys[candidate_key] then
--			key = candidate_key
--			assigned_keys[candidate_key] = true
--			return key
--		end
--	end
--
--	-- Fallback: Iterate through numbers 0-9
--	for i = 48, 57 do -- ASCII codes for '0' to '9'
--		local candidate_key = string.char(i)
--		if not assigned_keys[candidate_key] then
--			key = candidate_key
--			assigned_keys[candidate_key] = true
--			return key
--		end
--	end
--
--	return key -- In case all keys are taken, this will return nil
--end

-- Function to filter out duplicates based on function name and line number
local function filter_duplicates(functions)
	local seen_functions = {}
	local unique_functions = {}

	for _, func in ipairs(functions) do
		local unique_id = func.name .. "_" .. func.line
		if not seen_functions[unique_id] then
			table.insert(unique_functions, func)
			seen_functions[unique_id] = true -- Mark this function as seen
		end
	end

	return unique_functions
end

-- Public function to return the list of keys and function names
function M.get_list()
	local functions = get_functions()

	-- Filter out duplicates based on function name and line number
	local unique_functions = filter_duplicates(functions)

	local assigned_keys = {}

	-- Generate the list of keys and function names
	local result = {}
	local dynkey = require("dynkey")
	local key_group_id = context .. vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
	for _, func in ipairs(unique_functions) do
		--let Keypoint decide the key for the function
		local key = dynkey.get_key(key_group_id, func.name)
		if key then
			table.insert(result, { key = key, text = func.name })
		end
	end

	return result
end

-- Utility function to truncate the name to a given max length
local function truncate_name(name, max_length)
	max_length = max_length or 11 -- Default to 11 if no max_length is provided
	if #name > max_length then
		return name:sub(1, max_length)
	end
	return name
end
--
--
--
--
--
-- Function to generate a table of lines based on the function list
function M.get_function_list_flat(truncate_by)
	-- Fetch the list of functions
	local function_list = M.get_list()

	-- Prepare a table of lines to display
	local lines = {}
	for _, the_function in ipairs(function_list) do
		-- Extract the main and sub function names
		local name1, name2 = the_function.text:match("([^%.]*)%.?(.*)")
		name1 = name1:gsub("%.", "")
		name2 = name2:gsub("%.", "")

		-- Handle cases with or without sub-function names
		if name2 == "" then
			local truncated_name1 = truncate_name(name1, truncate_by)
			table.insert(lines, " " .. the_function.key .. " " .. truncated_name1)
		else
			local truncated_name1 = truncate_name(name1, truncate_by)
			local truncated_name2 = truncate_name(name2, truncate_by)
			table.insert(lines, " " .. the_function.key .. " " .. truncated_name2)
			table.insert(lines, "   " .. truncated_name1) -- This second entry is indented
		end
	end

	-- Return the generated lines
	return lines
end
--
--
--
-- -- Function to bind keys to functions
-- function M.bind_function_keys()
-- 	local functions = get_functions()
--
-- 	-- Filter out duplicates based on function name and line number
-- 	local unique_functions = filter_duplicates(functions)
--
-- 	local assigned_keys = {}
--
--
-- 	for _, func in ipairs(unique_functions) do
-- 		local key = generate_unique_key(func.name, assigned_keys)
-- 		if key then
-- 			-- Create keybinding to go to the function's line with a description for which-key
-- 			vim.api.nvim_set_keymap(
-- 				"n",
-- 				"<leader>u" .. key,
-- 				[[:lua vim.api.nvim_win_set_cursor(0, {]] .. func.line .. [[, 0})<CR>]],
-- 				{ noremap = true, silent = true, desc = func.name } -- Set description using `desc`
-- 			)
-- 		else
-- 			print("Could not find a unique key for function: " .. func.name)
-- 		end
-- 	end
-- end
-- Function to print all normal mode keymaps
-- function M.enk()
-- 	-- Get the normal mode keymaps
-- 	local normal_maps = vim.api.nvim_get_keymap("n")
--
-- 	-- Print each keymap in the command line
-- 	for _, map in ipairs(normal_maps) do
-- 		print(vim.inspect(map))
-- 	end
-- end

-- -- Now bind the function to a command for easy access
-- vim.api.nvim_create_user_command("PrintNormalKeymaps", function()
-- 	print_normal_keymaps()
-- end, {})

-- Function to clear all keybindings for <leader>u
local function clear_leader_u_keys()
	-- Get the current leader key (fallback to '\' if not set)
	local leader = vim.g.mapleader or "\\"

	-- Get the normal mode keymaps
	local leader_u_keys = vim.api.nvim_get_keymap("n")

	-- Iterate over all normal mode keymaps and delete those starting with <leader>u
	for _, map in ipairs(leader_u_keys) do
		local expected_lhs = leader .. "u"
		-- Check if the keybinding starts with <leader>u (actual leader key + 'u')
		if vim.startswith(map.lhs, expected_lhs) then
			-- Delete the keybinding for normal mode
			vim.api.nvim_del_keymap("n", map.lhs)
		end
	end
end

-- To call the function in Neovim, you can run:
-- :lua clear_leader_u_keys()

-- Function to concatenate all functions into a string for comparison
local function calculate_concatenation(functions)
	local concat = ""
	for _, func in ipairs(functions) do
		concat = concat .. func.name .. func.line
	end
	return concat -- Return the concatenated string of function names and lines
end

-- Function to calculate a simple hash for a list of functions
local function calculate_hash(functions)
	local concat = ""
	for _, func in ipairs(functions) do
		concat = concat .. func.name .. func.line
	end
	return vim.fn.sha256(concat) -- Return the SHA-256 hash of the concatenated string
end

function M.get_current_buffer_name()
	local bufname = vim.api.nvim_buf_get_name(0) -- Get the current buffer name
	if bufname == "" then
		return "[No Name]" -- Return "[No Name]" if the buffer has no name
	else
		return bufname -- Return the actual buffer name
	end
end

-- Function to bind all unique function keys using dynkey
function M.re_bind_function_keys()
	local dynkey = require("dynkey")

	-- Get the list of functions (you'll need to implement or get this function)
	local functions = get_functions()
	---- Caching ----
	-- Caching function
	-- NOT E: Question is if the caching function is beneficial...
	-- Calculate the current hash of the functions
	--local current_hash = calculate_hash(functions)
	local current_hash = calculate_concatenation(functions)
	--	local current_buffer = vim.api.nvim_get_current_buf()

	local current_buffer = M.get_current_buffer_name()

	-- Retrieve the previous hash for this buffer (vim.b is for buffer-local variables)
	local previous_hash = vim.b.previous_function_hash

	if
		previous_hash
		and current_hash == previous_hash
		and last_buffer_we_bound_to
		and last_buffer_we_bound_to == current_buffer
	then
		-- Skip rebinding as both the hash and the buffer haven't changed
		-- print("No changes in function list for this buffer. Skipping rebinding.")
		return
	end

	last_buffer_we_bound_to = vim.api.nvim_get_current_buf()

	-- Cache the new hash in the buffer-local variable
	vim.b.previous_function_hash = current_hash
	--x--
	------------------

	-- Define the key group id and prefix for our key group

	--local key_group_id = context .. vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())

	local key_group_id = context .. "[buffer:" .. current_buffer .. "]:functionkeys"

	-- Check if there is a previously bound key group in the context and unbind it
	--unbind whatever latest context we had, this buffer or another
	dynkey.unbind_latest_bindings(context)

	--	dynkey.unbind_keys(key_group_id)
	--
	--
	local prefix_keys = "z"

	-- Add a new key group
	dynkey.add_group(key_group_id, prefix_keys)

	-- Loop through each function and assign a unique key
	for _, func in ipairs(functions) do
		-- Create a function to go to the function's line
		--local key_func = [[vim.api.nvim_win_set_cursor(0, {]] .. func.line .. [[, 0})]]

		local key_func = function()
			-- Set the cursor to the specified line and column 0
			vim.api.nvim_win_set_cursor(0, { func.line, 0 })
		end

		-- Add the key to the group using dynkey's `make_key` function
		dynkey.make_key(key_group_id, func.name, key_func, "n", func.name .. " (" .. func.line .. ")") -- normal mode binding
	end

	-- Finalize the key group and bind the keys
	dynkey.finalize(key_group_id)
	dynkey.bind_keys(context, key_group_id)
end

-- Function to bind new function keys (buffer-specific)
-- function M.bind_function_keys()
-- 	-- Get the list of functions
-- 	local functions = get_functions()
--
-- 	-- Caching function
-- 	-- NOT E: Question is if the caching function is beneficial...
-- 	-- Calculate the current hash of the functions
-- 	--local current_hash = calculate_hash(functions)
-- 	local current_hash = calculate_concatenation(functions)
-- 	local current_buffer = vim.api.nvim_get_current_buf()
--
-- 	-- Retrieve the previous hash for this buffer (vim.b is for buffer-local variables)
-- 	local previous_hash = vim.b.previous_function_hash
--
-- 	if
-- 		previous_hash
-- 		and current_hash == previous_hash
-- 		and last_buffer_we_bound_to
-- 		and last_buffer_we_bound_to == current_buffer
-- 	then
-- 		-- Skip rebinding as both the hash and the buffer haven't changed
-- 		-- print("No changes in function list for this buffer. Skipping rebinding.")
-- 		return
-- 	end
--
-- 	last_buffer_we_bound_to = vim.api.nvim_get_current_buf()
--
-- 	-- Cache the new hash in the buffer-local variable
-- 	vim.b.previous_function_hash = current_hash
--
-- 	-- Clear all existing <leader>u keybindings
-- 	clear_leader_u_keys()
--
-- 	-- Filter out duplicates based on function name and line number
-- 	local unique_functions = filter_duplicates(functions)
--
-- 	local assigned_keys = {}
--
-- 	-- Bind each unique function to a new key
-- 	for _, func in ipairs(unique_functions) do
-- 		local key = generate_unique_key(func.name, assigned_keys)
-- 		if key then
-- 			-- Create keybinding to go to the function's line with a description
-- 			vim.api.nvim_set_keymap(
-- 				"n",
-- 				"<leader>u" .. key,
-- 				[[:lua vim.api.nvim_win_set_cursor(0, {]] .. func.line .. [[, 0})<CR>]],
-- 				{ noremap = true, silent = true, desc = func.name }
-- 			)
-- 		else
-- 			print("Could not find a unique key for function: " .. func.name)
-- 		end
-- 	end
-- end

-- Function to set up the plugin with user options
function M.setup()
	--	M.config = vim.tbl_extend("force", M.config, user_config or {})
end

return M
