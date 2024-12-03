local M = {}

local has_dressing = pcall(require, "dressing")

local nui_select = function(items, opts, on_choice, config)
   config = config or {}
   local Menu = require "nui.menu"
   local event = require("nui.utils.autocmd").event
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
      -- size = config.size or 45,
      size = {
         width = 45,
         height = 10,
      },
      -- relative = config.relative,

      border = {
         style = "single",
         text = {
            top = opts.prompt,
            top_align = "center",
         },
      },
      -- buf_options = config.buf_options,
      -- win_options = config.win_options,
      -- enter = true,
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

return M
