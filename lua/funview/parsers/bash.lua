local function lang_bash()
	log("Parsing Bash")

	local ok, parser = pcall(vim.treesitter.get_parser, 0, "bash")
	if not ok or not parser then
		print("Failed to get Bash parser")
		return {}
	end

	local tree = parser:parse()[1]
	if not tree then
		print("Failed to parse the buffer")
		return {}
	end

	local root = tree:root()

	local query = vim.treesitter.query.parse(
		"bash",
		[[
    (function_definition
        name: (word) @function_name)
    ]]
	)
	if not query then
		print("Failed to load query for Bash functions")
		return {}
	end

	local functions = {}

	-- Safe for Neovim 0.11+
	for _, match, _ in query:iter_matches(root, 0, 0, -1, { all = false }) do
		local func_name = ""
		local start_row = nil

		for id, node in pairs(match) do
			local capture_name = query.captures[id]
			if capture_name == "function_name" or capture_name == "variable_name" or capture_name == "command_name" then
				if node and node:range() then
					func_name = vim.treesitter.get_node_text(node, 0)
					start_row = select(1, node:range())
				end
			end
		end

		if func_name ~= "" and start_row then
			table.insert(functions, { name = func_name, line = start_row + 1 })
		end
	end

	return functions
end

return lang_bash
