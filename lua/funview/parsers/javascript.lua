-- Function to handle JavaScript-specific Tree-sitter parsing
local function lang_javascript()
	log("Parsing JavaScript")
	local parser = vim.treesitter.get_parser(0, "javascript")
	local tree = parser:parse()[1]
	if not tree then
		print("Failed to parse the buffer")
		return {}
	end
	local root = tree:root()

	-- JavaScript-specific Tree-sitter query
	local query = vim.treesitter.query.parse(
		"javascript",
		[[
    ; Match regular function declarations
    (function_declaration
        name: (identifier) @function_name)

    ; Match function expressions assigned to variables
    (variable_declarator
        name: (identifier) @variable_name
        value: [(function_expression) (arrow_function)])

    ; Match class method definitions
    (method_definition
        name: (property_identifier) @method_name)

    ; Match object literal methods
    (pair
        key: (property_identifier) @object_key
        value: [(function_expression) (arrow_function)])
    ]]
	)

	if not query then
		print("Failed to load query for JavaScript functions")
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
				-- Regular function declaration
				func_name = vim.treesitter.get_node_text(node, 0)
				start_row = node:range()
			elseif capture_name == "variable_name" then
				-- Function assigned to a variable
				func_name = vim.treesitter.get_node_text(node, 0)
				start_row = node:range()
			elseif capture_name == "method_name" then
				-- Class method
				func_name = vim.treesitter.get_node_text(node, 0)
				start_row = node:range()
			elseif capture_name == "object_key" then
				-- Object literal method
				func_name = vim.treesitter.get_node_text(node, 0)
				start_row = node:range()
			end
		end

		if func_name ~= "" and start_row then
			table.insert(functions, { name = func_name, line = start_row + 1 }) -- Store function name and line
		end
	end
	return functions
end

return lang_javascript
