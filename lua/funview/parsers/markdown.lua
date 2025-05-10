-- Function to handle Markdown-specific Tree-sitter parsing
local function lang_markdown()
	local parser = vim.treesitter.get_parser(0, "markdown")
	local tree = parser:parse()[1]
	if not tree then
		print("Failed to parse the buffer")
		return {}
	end
	local root = tree:root()

	-- Markdown-specific Tree-sitter query
	local query = vim.treesitter.query.parse(
		"markdown",
		[[
        ; Match ATX-style headings (e.g., ## Heading)
        (atx_heading
            (inline) @heading_title)

        ; Match Setext-style headings (e.g., Heading\n=====)
        (setext_heading
            (paragraph (inline) @heading_title))
        ]]
	)

	if not query then
		print("Failed to load query for markdown headings")
		return {}
	end

	local headings = {}

	-- Iterate over the matches in the query
	for _, match, _ in query:iter_matches(root, 0) do
		local heading_title = ""
		local start_row = nil

		for id, node in pairs(match) do
			local capture_name = query.captures[id]
			if capture_name == "heading_title" then
				heading_title = vim.treesitter.get_node_text(node, 0)
				start_row = node:range()
			end
		end

		if heading_title ~= "" and start_row then
			table.insert(headings, { name = heading_title, line = start_row + 1 }) -- Store heading title and line
		end
	end
	return headings
end

return lang_markdown
