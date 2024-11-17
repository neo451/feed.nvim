---@meta

---@alias feed.action function
---@alias feed.type "rss" | "atom" | "json"

---@class feed.feed
---@field title string
---@field text string
---@field htmlUrl string
---@field type feed.type
---@field tags? string[]
---@field lastUpdated? string -- TODO: ???
---@field entries? feed.entry[]

---@alias feed.opml table<string, feed.feed>

---@class feed.entry
---@field time integer # falls back to the current os.time
---@field feed string # link to the feed
---@field title? string
---@field link? string # link to the entry
---@field author? string # falls back to the feed
---@field content? string
---@field tags? table<string, boolean>

---@class feed.db
---@field dir string
---@field feeds feed.opml
---@field log table
---@field index table
---@field tags table<string, table<string, boolean>>
---@field is_stored fun(db: feed.db, id: integer): boolean
---@field add fun(db: feed.db, entry: feed.entry, tags: string[]?)
---@field rm fun(db: feed.db, id: integer)
---@field iter Iter
---@field filter fun(db: feed.db, query: string) : string[]
---@field read_entry fun(db: feed.db, id: string): string?
---@field save_entry fun(db: feed.db, id: string): boolean
---@field save_err fun(db: feed.db, type: string, url: string, mes: string): boolean
---@field save_feeds fun(db: feed.db): boolean
---@field tag fun(db: feed.db, id: string, tag: string)
---@field untag fun(db: feed.db, id: string, tag: string)
---@field blowup fun(db: feed.db)

---@class feed.entry_opts
---@field row_idx? integer # will default to cursor row
---@field untag? boolean # default true
---@field id? string # db_id
---@field buf? integer # db_id

---@class feed.render
---@field show_index fun(opts: table)
---@field show_entry fun(opts: feed.entry_opts)
---@field get_entry fun(opts: feed.entry_opts)

---@class feed.config
---@field feeds? string | { name: string, tags: table }
---@field colorscheme? string
---@field split_cmd? string
---@field db_dir? string
---@field date_format? string
---@field enable_default_keymaps? boolean
---@field layout? table
---@field search? table
---@field options? table
---@field on_attach? fun(bufs: table<string, integer>)
-- TODO:

---@class feed.date
---@field year integer
---@field month integer
---@field day integer
---@field hour integer
---@field min integer
---@field sec integer
---@field absolute fun(date: feed.date): feed.date
---@field format fun(date: feed.date, format: string): string
---@field from_now fun(date: feed.date): integer
-- TODO:

---@class feed.query
---@field after? feed.date #@
---@field before? feed.date #@
---@field must_have? string[] #+
---@field must_not_have? string[] #-
---@field feed? string #=
---@field limit? number ##
---@field re? vim.regex[]
