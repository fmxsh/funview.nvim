-- Function to handle Bash-specific Tree-sitter parsing
local function lang_bash()
	log("Parsing Bash")
	local parser = vim.treesitter.get_parser(0, "bash")
	local tree = parser:parse()[1]
	if not tree then
		print("Failed to parse the buffer")
		return {}
	end
	local root = tree:root()

	-- Updated Bash-specific Tree-sitter query
	local query = vim.treesitter.query.parse(
		"bash",
		[[
    ; Match function definitions in Bash
    (function_definition
        name: (word) @function_name)

    ]]
	)
	--	    ; Match variable assignments
	--    (variable_assignment
	--        name: (variable_name) @variable_name)
	--
	--    ; Match pipelines and commands
	--    (command
	--        name: (command_name) @command_name)

	if not query then
		print("Failed to load query for Bash functions")
		return {}
	end

	local functions = {}

	-- Iterate over the matches in the query
	for _, match, _ in query:iter_matches(root, 0) do
		local func_name = ""
		local start_row = nil

		for id, node in pairs(match) do
			local capture_name = query.captures[id]
			if capture_name == "function_name" then
				-- Standard function definition
				func_name = vim.treesitter.get_node_text(node, 0)
				start_row = node:range()
			elseif capture_name == "variable_name" then
				-- Variable assignments
				func_name = vim.treesitter.get_node_text(node, 0)
				start_row = node:range()
			elseif capture_name == "command_name" then
				-- Command names
				func_name = vim.treesitter.get_node_text(node, 0)
				start_row = node:range()
			end
		end

		if func_name ~= "" and start_row then
			table.insert(functions, { name = func_name, line = start_row + 1 }) -- Store name and line
		end
	end
	return functions
end

return lang_bash
