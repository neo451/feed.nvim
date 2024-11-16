local M = require "feed.db.query"
local date = require "feed.parser.date"
local config = require "feed.config"
config.db_dir = "~/.feed.nvim.test/"
local db = require "feed.db"

local function clear()
   for id, v in db:iter() do
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

describe("parse_query", function()
   it("should split query into parts", function()
      local query = M.parse_query "+read -star @5-days-ago linu[xs]"
      local expected =
         { must_have = { "read" }, must_not_have = { "star" }, after = date.today:days_ago(5):absolute(), before = date.today:absolute(), re = { vim.regex "linu[xs]" } }
      assert.same(expected.must_have, query.must_have)
      assert.same(expected.must_not_have, query.must_not_have)
      assert.same(expected.after, query.after)
      assert.same(type(expected.re), type(query.re))
   end)
   it("should allow partial query for live searching", function()
      local query = M.parse_query "@6-"
      assert.same({}, query)
   end)
   it("should treat unread as negative read", function()
      local query = M.parse_query "+unread"
      assert.same("read", query.must_not_have[1])
      query = M.parse_query "-unread"
      assert.same("read", query.must_have[1])
   end)
end)

describe("filter", function()
   it("return identical if query empty", function()
      DB {
         { title = "hi" },
         { title = "hello" },
      }
      db:tag("1", "unread")
      db:tag("1", "star")
      local res = db:filter ""
      assert.same({ "2", "1" }, res)
      clear()
   end)

   -- it("filter by tags", function()
   --    DB {
   --       { time = 3 },
   --       { time = 2 },
   --       { time = 0 },
   --       { time = 0 },
   --       { time = 1 },
   --    }
   --    db:tag("1", "read")
   --    db:tag("1", "star")
   --    db:tag("2", "read")
   --    db:tag("3", "star")
   --    db:tag("5", "read")
   --    local res = db:filter "+read -star"
   --    assert.same({ "5", "2" }, res)
   --    db:untag("1", "unread")
   --    db:untag("1", "star")
   --    db:untag("2", "unread")
   --    db:untag("3", "star")
   --    db:untag("5", "unread")
   -- end)
   --
   it("filter by date", function()
      DB {
         { time = date.today:days_ago(6):absolute() },
         { time = date.today:days_ago(7):absolute() },
         { time = date.today:days_ago(1):absolute() },
         { time = date.today:absolute() },
      }
      db:sort()
      local res = db:filter "@5-days-ago"
      assert.same({ "4", "3" }, res)
   end)

   it("filter by limit number", function()
      local entries = {}
      for i = 1, 20 do
         entries[i] = { title = i, time = i, id = i }
      end
      DB(entries)
      local res = db:filter "#10"
      assert.same(10, #res)
   end)

   it("filter by regex", function()
      DB {
         { title = "Neovim is awesome", time = 1 },
         { title = "neovim is lowercase", time = 1 },
         { title = "Vim is awesome", time = 1 },
         { title = "vim is lowercase", time = 1 },
         { title = "bim is not a thing", time = 1 },
      }
      local res = db:filter "Neo vim"
      assert.same({ "1", "2" }, res)
      -- local res2 = db:filter "!Neo !vim"
      -- assert.same({ "5" }, res2)
   end)

   it("filter by feed", function()
      DB {
         { feed = "neovim.io" },
         { feed = "ovim.io" },
         { feed = "vm.io" },
      }
      local res = db:filter "=vim"
      assert.same(2, #res)
      db:blowup()
   end)
end)
