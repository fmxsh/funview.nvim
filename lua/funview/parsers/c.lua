local function lang_c()
	log("Parsing C")

	local ok, parser = pcall(vim.treesitter.get_parser, 0, "c")
	if not ok or not parser then
		print("Failed to get C parser")
		return {}
	end

	local tree = parser:parse()[1]
	if not tree then
		print("Failed to parse the buffer")
		return {}
	end

	local root = tree:root()

	local query = vim.treesitter.query.parse(
		"c",
		[[
        (function_definition
            declarator: (function_declarator
                declarator: (identifier) @function_name))
        ]]
	)

	if not query then
		print("Failed to load query for C functions")
		return {}
	end

	local functions = {}

	for _, match, _ in query:iter_matches(root, 0, 0, -1, { all = false }) do
		local func_name = ""
		local start_row = nil

		for id, node in pairs(match) do
			local capture_name = query.captures[id]
			if capture_name == "function_name" and type(node) == "userdata" then
				local ok1, text = pcall(vim.treesitter.get_node_text, node, 0)
				local ok2, row = pcall(function()
					return select(1, node:range())
				end)

				if ok1 and ok2 and text ~= "" then
					table.insert(functions, { name = text, line = row + 1 })
				end
			end
		end

		if func_name ~= "" and start_row then
			table.insert(functions, { name = func_name, line = start_row + 1 })
		end
	end

	return functions
end

return lang_c
