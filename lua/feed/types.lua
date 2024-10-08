---@meta

---@alias feed.action function

---@alias feed.feed feed._feed | table | string

---@class feed._feed
---@field title string
---@field link string
---@field entries feed.entry[]

---@class feed.entry
---@field time integer
---@field id integer
---@field title string
---@field feed string
---@field tags table<string, boolean>
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

---@class feed.config
---@field feeds string[]
---@field keymaps feed.keymap[]
---@field db_dir string
---@field options table<string, table<string, any>>
---@field layout table<string, table<string, any>>
---@field search table<string, any>

---@class feed.userConfig
---@field feeds string[]
---@field keymaps? feed.keymap[]
---@field db_dir? string
---@field options? table<string, table<string, any>>
---@field layout? table<string, table<string, any>>
---@field search? table<string, any>

---@class feed.opml
---@field title string
---@field outline table
---@field export fun(self: feed.opml, topath: string?): string?
---@field append fun(self: feed.opml, t: table)
