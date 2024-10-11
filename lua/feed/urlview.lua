---view all links and open them through vim.ui.select or telescope, inspired by `newsboat`'s link listing feature and `urlview.nvim`

local inline_query = vim.treesitter.query.parse("markdown_inline", [[(inline_link (link_text)@text (link_destination)@link)]])
local auto_query = vim.treesitter.query.parse("markdown_inline", [[(uri_autolink)@link]])

local get_root = function(str)
   local parser = vim.treesitter.get_string_parser(str, "markdown_inline")
   return parser:parse()[1]:root()
end

local function markdown_links(str)
   local list_kv = vim.iter(inline_query:iter_captures(get_root(str), str))
      :map(function(_, node)
         return vim.treesitter.get_node_text(node, str)
      end)
      :totable()
   local list = {}
   for i = 1, #list_kv, 2 do
      list[#list + 1] = { list_kv[i], list_kv[i + 1] }
   end
   local list2 = vim.iter(auto_query:iter_captures(get_root(str), str))
      :map(function(_, node)
         local text = vim.treesitter.get_node_text(node, str):sub(2, -2)
         return text, text
      end)
      :totable()
   return vim.list_extend(list, list2)
end

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

--- TODO: for vim.ui.select
--- TODO: increment identical names, image1, image2...

local function urlview(str, opts)
   opts = opts or require("telescope.themes").get_dropdown {}
   local items = markdown_links(str)
   pickers
      .new(opts, {
         prompt_title = "url",
         finder = finders.new_table {
            results = items,
            entry_maker = function(entry)
               return {
                  value = entry,
                  display = entry[1],
                  ordinal = entry[1],
               }
            end,
         },
         attach_mappings = function(prompt_bufnr, _)
            actions.select_default:replace(function()
               actions.close(prompt_bufnr)
               local selection = action_state.get_selected_entry()
               vim.ui.open(selection.value[2])
            end)
            return true
         end,
         sorter = conf.generic_sorter(opts),
      })
      :find()
end

return urlview
