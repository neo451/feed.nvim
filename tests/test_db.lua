local date = require("feed.parser.date")
local eq = MiniTest.expect.equality
local sha = vim.fn.sha256
local coop = require("coop")
local db = require("feed.db")
db = db.new("~/.feed.nvim.test/")

local T = MiniTest.new_set()

local function new_db()
   db:blowup()
   db = db.new("~/.feed.nvim.test/")
end

T["new"] = MiniTest.new_set({
   hooks = {
      post_case = new_db,
   },
})
T["iter"] = MiniTest.new_set({
   hooks = {
      post_case = new_db,
   },
})

T["tag"] = MiniTest.new_set({
   hooks = {
      post_case = new_db,
   },
})

T["filter"] = MiniTest.new_set({
   hooks = {
      post_case = new_db,
   },
})

T["new"]["prepares all db files"] = function()
   vim.defer_fn(function()
      local dir = db.dir
      eq(1, vim.fn.isdirectory(tostring(dir)))
      eq(1, vim.fn.isdirectory(tostring(dir / "object")))
      eq(1, vim.fn.isdirectory(tostring(dir / "data")))
      eq(1, vim.fn.filereadable(tostring(dir / "feeds.lua")))
      eq(1, vim.fn.filereadable(tostring(dir / "tags.lua")))
      eq(1, vim.fn.filereadable(tostring(dir / "index")))
   end, 1)
end

T["new"]["adds entries to db and in memory, with id as key/filename, and content seperately stored"] = function()
   local entry = {
      link = "https://example.com",
      title = "zig",
      time = 1,
   }
   coop.spawn(function()
      local key = sha(entry.link)
      db[key] = entry
      eq(entry.time, db[key].time)
      eq(entry.link, db[key].link)
      eq(entry.title, db[key].title)
   end)
end

T["new"]["rm all refs in the db"] = function()
   local entry = {
      link = "https://example.com",
      title = "zig",
      time = 1,
   }
   coop.spawn(function()
      local id = sha(entry.link)
      db[id] = entry
      db:tag(id, { "star", "read" })
      db:rm(id)
      eq(nil, db[id])
      eq(nil, db.tags["star"][id])
      eq(nil, db.tags["read"][id])
      eq(0, vim.fn.filereadable(tostring(db.dir / "data" / id)))
   end)
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
   coop.spawn(function()
      db[sha("link1")] = entry
      db[sha("link2")] = entry2
      local res = {}
      for _, v in db:iter(true) do
         table.insert(res, v.time)
      end
      assert(res[1] > res[2])
   end)
end

T["tag"]["tag/untag"] = function()
   local entry = {
      link = "https://example.com",
      time = 1,
      title = "zig",
      content = "zig is a programming language",
   }
   coop.spawn(function()
      local id = sha(entry.link)
      db[id] = entry
      db:tag(id, "star")
      eq(db.tags.star[id], true)
      db:untag(id, "star")
      eq(nil, db.tags.star[id])
   end)
end

T["tag"]["tag comma seperated string or a list of tags"] = function()
   local entry = { time = 1, title = "zig" }
   coop.spawn(function()
      local id = sha(entry.link)
      db[id] = entry
      db:tag(id, "star, read")
      eq(db.tags.star[id], true)
      eq(db.tags.read[id], true)
      db:untag(id, "star, read")
      eq(nil, db.tags.star[id])
      eq(nil, db.tags.read[id])
      db:tag(id, { "star", "read" })
      eq(db.tags.star[id], true)
      eq(db.tags.read[id], true)
      db:untag(id, { "star", "read" })
      eq(nil, db.tags.star[id])
      eq(nil, db.tags.read[id])
   end)
end

local function simulate_db(entries)
   for i, v in ipairs(entries) do
      v.content = ""
      v.link = tostring(i)
      v.time = v.time or i
      local id = sha(v.link)
      db[id] = v
      db:tag(id, v.tags)
   end
end

T["filter"]["return empty if filter empty"] = function()
   local res = db:filter("")
   eq({}, res)
end

T["filter"]["by tag"] = function()
   coop.spawn(function()
      simulate_db({
         { tags = { "read", "star" } },
         { tags = { "read" } },
         { tags = { "star" } },
         {},
         { tags = { "read" } },
      })
      local res = db:filter("+read -star")
      eq({ sha("5"), sha("2") }, res)
   end)
end

T["filter"]["filter by date"] = function()
   coop.spawn(function()
      simulate_db({
         [1] = { time = date.literal("6-days-ago") },
         [2] = { time = date.literal("7-days-ago") },
         [3] = { time = date.literal("1-day-ago") },
         [4] = { time = os.time() },
      })
      eq({ sha("4"), sha("3") }, db:filter("@5-days-ago"))
   end)
end

T["filter"]["filter by limit number"] = function()
   coop.spawn(function()
      local entries = {}
      for i = 1, 20 do
         entries[i] = { title = i, time = i, id = i }
      end
      simulate_db(entries)
      local res = db:filter("#10")
      eq(10, #res)
   end)
end

T["filter"]["filter by regex"] = function()
   coop.spawn(function()
      simulate_db({
         { title = "Neovim is awesome" },
         { title = "neovim is lowercase" },
         { title = "Vim is awesome" },
         { title = "vim is lowercase" },
         { title = "bim is not a thing" },
      })
      local res = db:filter("Neo vim")
      eq({ sha("2"), sha("1") }, res)
      -- local res2 = db:filter "!Neo !vim"
      -- eq({ "5" }, res2)
   end)
end

T["filter"]["filter by feed"] = function()
   coop.spawn(function()
      simulate_db({
         { feed = "neovim.io" },
         { feed = "ovim.io" },
         { feed = "vm.io" },
      })
      local res = db:filter("=vim")
      eq(2, #res)
   end)
end

return T
