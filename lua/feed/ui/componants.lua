local M = {}
local Win = require("feed.ui.window")
local Config = require("feed.config")
local ut = require("feed.utils")
local api = vim.api

local function telescope_select(items, opts, on_choice)
   local pickers = require("telescope.pickers")
   local finders = require("telescope.finders")
   local actions = require("telescope.actions")
   local action_state = require("telescope.actions.state")
   local sorters = require("telescope.sorters")

   pickers
      .new(require("telescope.themes").get_dropdown(), {
         prompt_title = opts.prompt,
         finder = finders.new_table({
            results = items,
            entry_maker = function(entry)
               return {
                  value = entry,
                  display = opts.format_item(entry),
                  ordinal = opts.format_item(entry),
               }
            end,
         }),
         attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
               actions.close(prompt_bufnr)
               local selection = action_state.get_selected_entry()
               on_choice(selection.value)
            end)
            return true
         end,
         sorter = sorters.get_generic_fuzzy_sorter(opts),
      })
      :find()
end

local function fzf_ui_select(items, opts, on_choice)
   local prompt = " " .. opts.prompt .. " "
   opts.prompt = "> "
   local ui_select = require("fzf-lua.providers.ui_select")
   if ui_select.is_registered() then
      ui_select.deregister()
   end
   require("fzf-lua").register_ui_select(function(_, i)
      local min_h, max_h = 0.15, 0.70
      local h = (#i + 4) / vim.o.lines
      if h < min_h then
         h = min_h
      elseif h > max_h then
         h = max_h
      end
      return { winopts = { height = h, width = 0.60, row = 0.40, title = prompt, title_pos = "center" } }
   end)
   require("fzf-lua.providers.ui_select").ui_select(items, opts, on_choice)
end

function M.select(items, opts, on_choice)
   local backend = ut.choose_backend(Config.search.backend)
   if backend == "fzf-lua" then
      fzf_ui_select(items, opts, on_choice)
   elseif backend == "pick" then
      require("mini.pick").ui_select(items, opts, on_choice)
   elseif backend == "telescope" then
      telescope_select(items, opts, on_choice)
   else
      vim.ui.select(items, opts, on_choice)
   end
end

---@param opts table
---@param percentage string
---@param lines? string[]
---@return feed.win
function M.split(opts, percentage, lines)
   lines = lines or {}

   local height = math.floor(vim.o.lines * (tonumber(percentage:sub(1, -2)) / 100))
   local width = vim.o.columns
   local col = vim.o.columns - width
   local row = vim.o.lines - height - vim.o.cmdheight

   opts = vim.tbl_extend("force", {
      relative = "editor",
      style = "minimal",
      focusable = false,
      noautocmd = true,
      height = height,
      width = width,
      col = col,
      row = row,
      wo = {
         winbar = "",
         scrolloff = 0,
         foldenable = false,
         statusline = "",
         wrap = false,
      },
      bo = {
         buftype = "nofile",
         bufhidden = "wipe",
      },
   }, opts)

   local win = Win.new(opts)

   win:map("n", "q", function()
      win:close()
   end)

   api.nvim_buf_set_lines(win.buf, 0, -1, false, lines)

   return win
end

M.input = function(opts, on_confirm)
   vim.ui.input(opts, function(input)
      if not input or vim.trim(input) == "" then
         return
      end
      on_confirm(input)
   end)
end

return M
