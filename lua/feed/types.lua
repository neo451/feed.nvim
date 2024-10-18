---@meta

---@alias feed.action function

---@alias feed.feed feed._feed | table | string

---@class feed._feed
---@field title string
---@field link string
---@field desc string
---@field entries feed.entry[]

---@class feed.entry
---@field time integer
---@field id integer
---@field title string
---@field feed string
---@field tags table<string, boolean>
---@field link string
---@field author string
---@field content string

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

---@class feed.opml
---@field title string
---@field outline table
---@field names table
---@field export fun(self: feed.opml, topath: string?): string?
---@field append fun(self: feed.opml, t: table)

---@class feed.config
---@field feeds? feed.feed[]
---@field colorscheme? string
---@field split? string
---@field keymaps? { index : table<string, string | function>, entry : table<string, string | function> }
---@field db_dir? string
---@field layout? table
vim.g.feed = vim.g.feed

---@class feed.date
---@field year integer
---@field month integer
---@field day integer
---@field hour integer
---@field min integer
---@field sec integer
---@field absolute fun(date: feed.date): feed.date
---@field format fun(date: feed.date, format: string): feed.date
---@field from_now fun(date: feed.date): integer
