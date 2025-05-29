-- Function to handle Lua-specific Tree-sitter parsing
local function lang_lua()
	local parser = vim.treesitter.get_parser(0, "lua")
	local tree = parser:parse()[1]
	if not tree then
		print("Failed to parse the buffer")
		return {}
	end
	local root = tree:root()

	-- Lua-specific Tree-sitter query
	local query = vim.treesitter.query.parse(
		"lua",
		[[
        ; Match standalone function declarations
        (function_declaration
            name: (identifier) @function_name)

        ; Match function declarations in tables (dot-indexed)
        (function_declaration
            name: (dot_index_expression
                table: (identifier) @table_name
                field: (identifier) @field_name))
    ; Match function definitions in table constructors
;    (table_constructor
;        (field
;            name: (identifier) @table_field_name
;            value: (function_definition)))
	    ; Match function definitions in table constructors
    (field
      name: (identifier) @table_field_name
      value: (function_definition))
            ]]
	)

	if not query then
		print("Failed to load query for functions")
		return {}
	end

	local functions = {}

	-- Iterate over the matches in the query
	for _, match, _ in query:iter_matches(root, 0, 0, -1, { all = true }) do
		local func_name = ""
		local start_row = nil

		local table_name_node = nil
		local field_name_node = nil

		for id, nodes in pairs(match) do
			local capture_name = query.captures[id]

			-- Always take the first node for that capture
			local node = nodes[1]

			if capture_name == "function_name" and node then
				func_name = vim.treesitter.get_node_text(node, 0)
				start_row = select(1, node:range())
			elseif capture_name == "table_name" then
				table_name_node = nodes[1]
			elseif capture_name == "field_name" then
				field_name_node = nodes[1]
			elseif capture_name == "table_field_name" and node then
				func_name = vim.treesitter.get_node_text(node, 0)
				start_row = select(1, node:range())
			end
		end

		if table_name_node and field_name_node then
			local table_name = vim.treesitter.get_node_text(table_name_node, 0)
			local field_name = vim.treesitter.get_node_text(field_name_node, 0)
			func_name = table_name .. "." .. field_name
			start_row = select(1, table_name_node:range())
		end

		if func_name ~= "" and start_row then
			table.insert(functions, {
				name = func_name,
				line = start_row + 1,
			})
		end
	end

	return functions
end

return lang_lua
