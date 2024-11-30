local config = require "feed.config"
config.db_dir = "~/.feed.nvim.test/"
local ut = require "feed.utils"
local db = ut.require "feed.db"
local date = require "feed.parser.date"
local eq = MiniTest.expect.equality
local h = require "tests.helpers"
local readfile = h.readfile

local T = MiniTest.new_set()

T["new"] = MiniTest.new_set()
T["iter"] = MiniTest.new_set()
T["filter"] = MiniTest.new_set()

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
      id = "1234567",
      time = 1,
   }
   db:add(entry)
   eq(entry.time, db["1234567"].time)
   eq(entry.link, db["1234567"].link)
   eq(entry.title, db["1234567"].title)
   eq("zig is a programming language", readfile("/data/1234567", db.dir))
end

T["iter"]["iterates by time"] = function()
   local entry = {
      content = "zig is a programming language",
      id = "1",
      time = 20,
   }

   local entry2 = {
      content = "zig is a programming language",
      id = "2",
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
      id = "1",
   }

   db:add(entry)
   db:tag("1", "star")
   eq(db.tags.star["1"], true)
   eq(db["1"].tags.star, true)
   db:untag("1", "star")
   eq(nil, db.tags.star["1"])
   eq(nil, db["1"].tags.star)
end

local function clear()
   for id, _ in db:iter() do
      db:rm(id)
   end
end
function DB(entries)
   clear()
   for i, v in ipairs(entries) do
      v.content = ""
      v.id = tostring(i)
      v.time = v.time or i
      db:add(v)
   end
end

T["filter"]["return identical if query empty"] = function()
   DB {
      { title = "hi" },
      { title = "hello" },
   }
   db:tag("1", "unread")
   db:tag("1", "star")
   local res = db:filter ""
   eq({ "2", "1" }, res)
   clear()
end

T["filter"]["by tag"] = function()
   DB { {}, {}, {}, {}, {} }
   db:tag("1", "read")
   db:tag("1", "star")
   db:tag("2", "read")
   db:tag("3", "star")
   db:tag("5", "read")
   local res = db:filter "+read -star"
   eq({ "5", "2" }, res)
   db:untag("1", "unread")
   db:untag("1", "star")
   db:untag("2", "unread")
   db:untag("3", "star")
   db:untag("5", "unread")
end

T["filter"]["filter by date"] = function()
   DB {
      { time = date.days_ago(6) },
      { time = date.days_ago(7) },
      { time = date.days_ago(1) },
      { time = os.time() },
   }
   db:sort()
   local res = db:filter "@5-days-ago"
   eq({ "4", "3" }, res)
end

T["filter"]["filter by limit number"] = function()
   local entries = {}
   for i = 1, 20 do
      entries[i] = { title = i, time = i, id = i }
   end
   DB(entries)
   local res = db:filter "#10"
   eq(10, #res)
end

T["filter"]["filter by regex"] = function()
   DB {
      { title = "Neovim is awesome", time = 1 },
      { title = "neovim is lowercase", time = 1 },
      { title = "Vim is awesome", time = 1 },
      { title = "vim is lowercase", time = 1 },
      { title = "bim is not a thing", time = 1 },
   }
   local res = db:filter "Neo vim"
   eq({ "1", "2" }, res)
   -- local res2 = db:filter "!Neo !vim"
   -- eq({ "5" }, res2)
end

T["filter"]["filter by feed"] = function()
   DB {
      { feed = "neovim.io" },
      { feed = "ovim.io" },
      { feed = "vm.io" },
   }
   local res = db:filter "=vim"
   eq(2, #res)
   db:blowup()
end

return T
