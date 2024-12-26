local M = {}
local Config = require "feed.config"
local Split = require("nui.split")
local Menu = require("nui.menu")
local Input = require "nui.input"
local event = require("nui.utils.autocmd").event
local api = vim.api
local ut = require "feed.utils"

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
      if vim.tbl_isempty({ ... }) then
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

M.select = function(items, opts, on_choice)
   local backend = ut.choose_backend(Config.search.backend)
   if backend == 'fzf-lua' then
      local prompt = ' ' .. opts.prompt .. ' '
      opts.prompt = "> "
      local ui_select = require "fzf-lua.providers.ui_select"
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
   else
      if backend == 'pick' then
         MiniPick.ui_select(items, opts, on_choice)
      elseif backend == 'telescope' then
         telescope_select(items, opts, on_choice)
      elseif pcall(require, "dressing") then
         vim.ui.select(items, opts, on_choice)
      else
         nui_select(items, opts, on_choice)
      end
   end
end

---@param percentage string
---@param lines? string[]
---@return NuiSplit
function M.split(percentage, lines)
   lines = lines or {}
   local split = Split({
      relative = "editor",
      position = "bottom",
      size = percentage,
   })
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

function M.input(opts, on_submit)
   local input = Input({
      position = {
         row = vim.o.lines,
         col = 0
      },
      size = {
         width = vim.o.columns,
         height = 1,
      },
      border = {
         style = "none",
      },
      zindex = 1000,
      win_options = {
         winhighlight = "Normal:Normal,FloatBorder:Normal",
      },
   }, {
      prompt = opts.prompt,
      default_value = opts.default,
      on_submit = on_submit,
   })

   input:mount()

   input:on(event.BufLeave, function()
      input:unmount()
   end)
   input:map("n", "q", function()
      input:unmount()
   end)
end

return M
