-- https://www.jsonfeed.org/mappingrssandatom/
--
local M = {}

function M.is_json(str)
	local ok = pcall(vim.json.decode, str)
	return ok
end

function M.parse_json(str)
	return vim.json.decode(str)
end

return M
