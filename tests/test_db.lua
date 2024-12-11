vim.fn.delete("~/.feed.nvim.test/", "rf")
local config = require "feed.config"
config.db_dir = "~/.feed.nvim.test/"
local db = require "feed.db"
local date = require "feed.parser.date"
local eq = MiniTest.expect.equality
local h = require "tests.helpers"
local readfile = h.readfile
local sha = vim.fn.sha256

local T = MiniTest.new_set()

local function new_db()
   db:blowup()
   db = db.new()
end

T["new"] = MiniTest.new_set({
   hooks = {
      post_case = new_db
   }
})
T["iter"] = MiniTest.new_set({
   hooks = {
      post_case = new_db
   }
})

T["filter"] = MiniTest.new_set({
   hooks = {
      post_case = new_db
   }
})

T["new"]["prepares all db files"] = function()
   local dir = tostring(db.dir)
   eq(1, vim.fn.isdirectory(dir))
   eq(1, vim.fn.isdirectory(dir .. "/object/"))
   eq(1, vim.fn.isdirectory(dir .. "/data/"))
   eq(1, vim.fn.filereadable(dir .. "/feeds.lua"))
   eq(1, vim.fn.filereadable(dir .. "/tags.lua"))
   eq(1, vim.fn.filereadable(dir .. "/index"))
   eq("table", type(db.feeds))
end

T["new"]["adds entries to db and in memory, with id as key/filename, and content seperately stored"] = function()
   local entry = {
      link = "https://example.com",
      title = "zig",
      content = "zig is a programming language",
      time = 1,
   }
   local key = sha(entry.link)
   db:add(entry)
   eq(entry.time, db[key].time)
   eq(entry.link, db[key].link)
   eq(entry.title, db[key].title)
   eq("zig is a programming language", readfile("/data/" .. key, db.dir))
end

T["new"]["rm all refs in the db"] = function()
   local entry = {
      link = "https://example.com",
      title = "zig",
      content = "zig is a programming language",
      time = 1,
   }
   local key = sha(entry.link)
   db:add(entry, { "star", "read" })
   db:rm(key)
   eq(nil, db[key])
   eq(nil, db.tags['star'][key])
   eq(nil, db.tags['read'][key])
   eq(0, vim.fn.filereadable(db.dir .. "/data/" .. key))
end

T["iter"]["iterates by time"] = function()
   local entry = {
      link = "link1",
      content = "zig is a programming language",
      time = 20,
   }

   local entry2 = {
      content = "zig is a programming language",
      link = "link2",
      time = 30,
   }
   db:add(entry)
   db:add(entry2)
   local res = {}
   for _, v in db:iter(true) do
      table.insert(res, v.time)
   end
   assert(res[1] > res[2])
end

T["new"]["tags/untags entry"] = function()
   local entry = {
      link = "https://example.com",
      time = 1,
      title = "zig",
      content = "zig is a programming language",
   }
   local id = sha(entry.link)

   db:add(entry)
   db:tag(id, "star")
   eq(db.tags.star[id], true)
   eq(db[id].tags.star, true)
   db:untag(id, "star")
   eq(nil, db.tags.star[id])
   eq(nil, db[id].tags.star)
end

local function simulate_db(entries)
   for i, v in ipairs(entries) do
      v.content = ""
      v.link = tostring(i)
      v.time = v.time or i
      db:add(v, v.tags)
   end
end

T["filter"]["return empty if filter empty"] = function()
   local res = db:filter ""
   eq({}, res)
end

T["filter"]["by tag"] = function()
   simulate_db {
      { tags = { "read", "star" } },
      { tags = { "read" } },
      { tags = { "star" } },
      {},
      { tags = { "read" } }
   }
   local res = db:filter "+read -star"
   eq({ sha "5", sha "2" }, res)
end

T["filter"]["filter by date"] = function()
   simulate_db {
      [1] = { time = date.days_ago(6) },
      [2] = { time = date.days_ago(7) },
      [3] = { time = date.days_ago(1) },
      [4] = { time = os.time() },
   }
   eq({ sha "4", sha "3" }, db:filter "@5-days-ago")
end

T["filter"]["filter by limit number"] = function()
   local entries = {}
   for i = 1, 20 do
      entries[i] = { title = i, time = i, id = i }
   end
   simulate_db(entries)
   local res = db:filter "#10"
   eq(10, #res)
end

T["filter"]["filter by regex"] = function()
   simulate_db {
      { title = "Neovim is awesome" },
      { title = "neovim is lowercase" },
      { title = "Vim is awesome" },
      { title = "vim is lowercase" },
      { title = "bim is not a thing" },
   }
   local res = db:filter "Neo vim"
   eq({ sha "2", sha "1", }, res)
   -- local res2 = db:filter "!Neo !vim"
   -- eq({ "5" }, res2)
end

T["filter"]["filter by feed"] = function()
   simulate_db {
      { feed = "neovim.io" },
      { feed = "ovim.io" },
      { feed = "vm.io" },
   }
   local res = db:filter "=vim"
   eq(2, #res)
   -- db:blowup()
end

return T
