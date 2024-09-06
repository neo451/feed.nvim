---@meta

---@class feed.entry
---@field time integer
---@field id integer
---@field title string
---@field feed string
---@field tags string[]
---@field link string
---@field author string

---@class feed.db
---@field index feed.entry[]
---@field is_stored fun(db: feed.db, id: integer): boolean
---@field add fun(db: feed.db, entry: feed.entry, content: string)
---@field get fun(db: feed.db, entry: feed.entry): string # maybe get back a list of lines?
---@field address fun(db: feed.db, entry: feed.entry): string
---@field sort fun(db: feed.db)
---@field update_index fun(db: feed.db)
---@field save fun(db: feed.db)
---@field blowup fun(db: feed.db)

---@class feed.render
---@field state table<string, boolean>
---@field curent_index integer
---@field current_entry fun(): table<string, any>
---@field show_entry fun(row: integer)
---@field show_index function

---@class feed.feed
---@field name string
---@field tags string[]

--- TODO: feed.config