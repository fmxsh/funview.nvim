local function lang_markdown()
	local ok, parser = pcall(vim.treesitter.get_parser, 0, "markdown")
	if not ok or not parser then
		print("Failed to get Markdown parser")
		return {}
	end

	local tree = parser:parse()[1]
	if not tree then
		print("Failed to parse the buffer")
		return {}
	end

	local root = tree:root()

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

	for _, match, _ in query:iter_matches(root, 0, 0, -1, { all = false }) do
		local heading_title = ""
		local start_row = nil

		for id, node in pairs(match) do
			local capture_name = query.captures[id]
			if capture_name == "heading_title" then
				if node and node:range() then
					heading_title = vim.treesitter.get_node_text(node, 0)
					start_row = select(1, node:range())
				end
			end
		end

		if heading_title ~= "" and start_row then
			table.insert(headings, { name = heading_title, line = start_row + 1 })
		end
	end

	return headings
end

return lang_markdown
