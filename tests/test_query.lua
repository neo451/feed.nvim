local M = require("feed.db.query")
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

T["parse"] = MiniTest.new_set()

T["parse"]["splits query into parts"] = function()
   local query = M.parse_query("+read -star @5-days-ago linu[xs] =vim ~emacs")
   eq("read", query.must_have[1])
   eq("star", query.must_not_have[1])
   eq("number", type(query.after))
   eq("userdata", type(query.re[1]))
   assert(query.feed:match_str("vim"))
   assert(query.not_feed:match_str("emacs"))
end

T["parse"]["allows imcomplete query for live searching"] = function()
   eq({}, M.parse_query("@6"))
end

T["parse"]["treats unread as negative read"] = function()
   local query = M.parse_query("+unread")
   eq("read", query.must_not_have[1])
   query = M.parse_query("-unread")
   eq("read", query.must_have[1])
end

return T
