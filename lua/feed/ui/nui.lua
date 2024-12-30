local M = {}
local Config = require "feed.config"
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

function M.select(items, opts, on_choice)
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

---@param opts table
---@param percentage string
---@param lines? string[]
---@return feed.win
function M.split(opts, percentage, lines)
   lines = lines or {}
   local Win = require "feed.ui.window"

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
   input:map("i", "<esc>", function()
      input:unmount()
   end)
   input:map("n", "<esc>", function()
      input:unmount()
   end)
end

return M
