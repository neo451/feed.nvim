local popup = {}

local mod = {}

mod.popup = popup

function mod.eq(...)
   return assert.are.same(...)
end

function mod.approx(...)
   return assert.are.near(...)
end

function mod.neq(...)
   return assert["not"].are.same(...)
end

---@param fn fun(): nil
---@param error string
---@param is_plain boolean
function mod.errors(fn, error, is_plain)
   assert.matches_error(fn, error, 1, is_plain)
end

---@param keys string
---@param mode string
function mod.feedkeys(keys, mode)
   vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), mode or "", true)
end

function mod.is_url(str, mes)
   local looks_like_url = require("feed.utils").looks_like_url
   assert(looks_like_url(str) == true, mes)
end

return mod