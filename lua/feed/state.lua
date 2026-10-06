---@class feed.state
---@field query string
---@field index? feed.win
---@field entry? feed.win
---@field entries? string[]
---@field cur integer
---@field undo_history table[]
---@field redo_history table[]

---@type feed.state
---@diagnostic disable-next-line: missing-fields
local state = {
   query = require("feed.config").search.default_query,
   index = nil,
   entry = nil,
   entries = nil,
   undo_history = {},
   redo_history = {},
}

return state
