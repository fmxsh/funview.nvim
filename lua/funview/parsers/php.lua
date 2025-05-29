local function lang_php()
	-- Safely get the Tree-sitter parser for PHP
	local ok, parser = pcall(vim.treesitter.get_parser, 0, "php")
	if not ok or not parser then
		print("Failed to get PHP parser")
		return {}
	end

	local tree = parser:parse()[1]
	if not tree then
		print("Failed to parse the buffer")
		return {}
	end

	local root = tree:root()

	-- Tree-sitter query for PHP declarations
	local query = vim.treesitter.query.parse(
		"php",
		[[
(function_definition
  name: (name) @function_name)

(method_declaration
  name: (name) @method_name)

(class_declaration
  name: (name) @class_name)
		]]
	)

	if not query then
		print("Failed to load query for declarations")
		return {}
	end

	local declarations = {}

	for _, match, _ in query:iter_matches(root, 0, 0, -1, { all = false }) do
		for id, node in pairs(match) do
			local capture_name = query.captures[id]
			if node and node:range() then
				local name = vim.treesitter.get_node_text(node, 0)
				local start_row = select(1, node:range())

				local kind = capture_name:gsub("_name$", "") -- "function", "method", "class"

				table.insert(declarations, {
					name = name,
					line = start_row + 1,
					type = kind,
				})
			end
		end
	end

	return declarations
end

return lang_php
