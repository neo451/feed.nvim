local M = {}

-- M.setup = function(opts)
--   print("Options:", opts)
-- end

-- functions we need:
-- - vim.keymap.set(...) -> create new keymaps
-- - nvim_get_keymap

-- vim.api.nvim_get_keymap(...)

local find_mapping = function(maps, lhs)
	-- pairs
	--    iterates over EVERY key in a table
	--    order not guaranteed
	-- ipairs
	--    iteratres over ONLY numeric keys in a table
	--    order IS guaranteed
	for _, value in ipairs(maps) do
		if value.lhs == lhs then
			return value
		end
	end
end

M._stack = {}

M.push = function(name, mode, mappings)
	local maps = vim.api.nvim_get_keymap(mode)

	local existing_maps = {}
	for lhs, rhs in pairs(mappings) do
		local existing = find_mapping(maps, lhs)
		if existing then
			existing_maps[lhs] = existing
		end
	end

	for lhs, rhs in pairs(mappings) do
		-- TODDO: need some way to pass options in here
		vim.keymap.set(mode, lhs, rhs)
	end

	-- TODO: Next time show bash about metatables POGSLIDE
	M._stack[name] = M._stack[name] or {}

	M._stack[name][mode] = {
		existing = existing_maps,
		mappings = mappings,
	}
end

M.pop = function(name, mode)
	local state = M._stack[name][mode]
	M._stack[name][mode] = nil

	for lhs in pairs(state.mappings) do
		if state.existing[lhs] then
			-- Handle mappings that existed
			local og_mapping = state.existing[lhs]

			-- TODO: Handle the options from the table
			vim.keymap.set(mode, lhs, og_mapping.rhs)
		else
			-- Handled mappings that didn't exist
			vim.keymap.del(mode, lhs)
		end
	end
end

--[[
lua require("mapstack").push("debug_mode", "n", {
  ["<leader>st"] = "echo 'Hello'",
  ["<leader>sz"] = "echo 'Goodbye'",
})

...

push "debug"
push "other"
pop "debug"
pop "other

lua require("mapstack").pop("debug_mode")
--]]

M._clear = function()
	M._stack = {}
end

return M
