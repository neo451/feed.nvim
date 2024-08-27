local xml2lua = require("xml")
local handler = require("tree")
local M = {}

function M.parse_opml(file)
	local hdlr = handler:new()
	local parser = xml2lua.parser(hdlr)
	local src = vim.fn.readfile(file)
	parser:parse(table.concat(src, "\n"))
	return hdlr.root.opml.body.outline.outline
end

return M
