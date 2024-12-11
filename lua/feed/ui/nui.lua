local M = {}
local Split = require "nui.split"
local Menu = require "nui.menu"
local event = require("nui.utils.autocmd").event
local api = vim.api

local has_dressing = pcall(require, "dressing")

local nui_select = function(items, opts, on_choice, config)
   config = config or {}
   local lines = {}
   local line_width = opts.prompt and vim.api.nvim_strwidth(opts.prompt) or 1
   for i, item in ipairs(items) do
      local line = opts.format_item(item)
      line_width = math.max(line_width, vim.api.nvim_strwidth(line))
      table.insert(lines, Menu.item(line, { value = item, idx = i }))
   end

   if not config.size then
      line_width = math.max(line_width, config.min_width or 20)
      local height = math.max(#lines, config.min_height or 20)
      config.size = {
         width = line_width,
         height = height,
      }
   end

   local callback
   callback = function(...)
      if vim.tbl_isempty { ... } then
         return
      end
      on_choice(...)
      -- Prevent double-calls
      callback = function() end
   end

   local menu = Menu({
      position = "50%",
      size = {
         width = 70,
         height = 10,
      },

      border = {
         style = "single",
         text = {
            top = opts.prompt,
            top_align = "center",
         },
      },
   }, {
      lines = lines,
      max_width = config.max_width or 80,
      max_height = config.max_height or 20,
      keymap = {
         focus_next = { "j", "<Down>", "<Tab>" },
         focus_prev = { "k", "<Up>", "<S-Tab>" },
         close = { "q", "<C-c>" },
         submit = { "<CR>" },
      },
      on_close = function()
         vim.schedule(function()
            callback(nil, nil)
         end)
      end,
      on_submit = function(item)
         callback(item.value, item.idx)
      end,
   })

   menu:mount()

   menu:on(event.BufLeave, menu.menu_props.on_close, { once = true })
end

M.select = has_dressing and vim.ui.select or nui_select

---@param percentage string
---@param lines? string[]
---@return NuiSplit
function M.split(percentage, lines)
   lines = lines or {}
   local split = Split {
      relative = "editor",
      position = "bottom",
      size = percentage,
   }
   split:mount()

   split:map("n", "q", function()
      split:unmount()
   end, { noremap = true })

   split:on(event.BufLeave, function()
      split:unmount()
   end)

   api.nvim_buf_set_lines(split.bufnr, 0, -1, false, lines)
   api.nvim_set_option_value("number", false, { win = split.winid })
   api.nvim_set_option_value("relativenumber", false, { win = split.winid })
   api.nvim_set_option_value("modifiable", false, { buf = split.bufnr })
   return split
end

return M
