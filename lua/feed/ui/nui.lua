local M = {}
local Win = require "feed.ui.window"
local Config = require "feed.config"
local ut = require "feed.utils"
local api = vim.api

-- Levenshtein distance function
local function levenshtein(a, b)
   local len_a, len_b = #a, #b
   local dp = {}
   for i = 0, len_a do
      dp[i] = {}
      dp[i][0] = i
   end
   for j = 0, len_b do
      dp[0][j] = j
   end
   for i = 1, len_a do
      for j = 1, len_b do
         local cost = (a:sub(i, i) == b:sub(j, j)) and 0 or 1
         dp[i][j] = math.min(
            dp[i - 1][j] + 1,       -- deletion
            dp[i][j - 1] + 1,       -- insertion
            dp[i - 1][j - 1] + cost -- substitution
         )
      end
   end
   return dp[len_a][len_b]
end

-- Fuzzy match function
local function fuzzy_match(input, items, threshold)
   threshold = threshold or 0.5 -- Default similarity threshold
   local results = {}

   for _, item in ipairs(items) do
      local distance = levenshtein(input, item)
      local similarity = 1 - (distance / math.max(#input, #item))
      if similarity >= threshold then
         table.insert(results, { item = item, score = similarity })
      end
   end

   table.sort(results, function(a, b)
      return a.score > b.score
   end)

   return vim.iter(results):map(function(item)
      return item.item
   end):totable()
end

M._select = function(items, opts, on_choice)
   local height = math.floor(vim.o.lines / 2)
   local width = math.floor(vim.o.columns / 2)

   local col = math.floor(vim.o.columns / 4)
   local row = math.floor(vim.o.lines / 4)

   local res = Win.new({
      style = "minimal",
      row = row,
      col = col,
      height = height,
      width = width,
      focusable = false,
      noautocmd = true,
      border = "rounded",
      wo = {
         signcolumn = "yes:1",
         winhighlight = "Normal:Normal,FloatBorder:Normal",
         cursorline = true,
      },
      bo = {
         buftype = "nofile",
      }
   }, false)

   local input = Win.new({
      style = "minimal",
      row = row - 2,
      col = col,
      height = 1,
      width = width,
      title = " " .. opts.prompt .. " ",
      title_pos = "center",
      border = { "╭", "─", "╮", "│", "│", "─", "│", "│" },
      wo = {
         signcolumn = "yes:1",
         winhighlight = "Normal:Normal,FloatBorder:Normal",
         cursorline = true,
      },
      b = {
         completion = false,
      }
   }, true)

   vim.cmd("startinsert!")

   local lines = vim.tbl_map(opts.format_item, items)

   vim.api.nvim_buf_set_lines(res.buf, 0, -1, false, lines)

   vim.api.nvim_buf_attach(input.buf, false, {
      on_lines = vim.schedule_wrap(function()
         vim.api.nvim_buf_set_lines(res.buf, 0, -1, false, {})
         local query = vim.api.nvim_get_current_line()
         local set_items = fuzzy_match(query, lines, 0.3)
         vim.api.nvim_buf_set_lines(res.buf, 0, -1, false, set_items)
      end),
   })

   input:map("n", "q", function()
      res:close()
      input:close()
   end)

   input:map("n", "<enter>", function()
      local item = vim.api.nvim_get_current_line()
      res:close()
      on_choice(item)
   end)
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
      else
         vim.ui.select(items, opts, on_choice)
         -- M._select(items, opts, on_choice)
      end
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

M.input = vim.ui.input

-- function M.input(opts, on_submit)
--    opts = opts or {}
--
--    local win = Win.new({
--       row = vim.o.lines,
--       col = 0,
--       width = vim.o.columns,
--       height = 1,
--       style = "minimal",
--       zindex = 1000,
--       noautocmd = true,
--       autocmds = {
--          BufLeave = function()
--             vim.cmd "stopinsert"
--          end
--       }
--    })
--    vim.cmd "startinsert"
--
--    on_submit = on_submit or function() end
--
--    local prompt = opts.prompt
--    if prompt then
--       vim.wo[win.win].statuscolumn = prompt
--    end
--
--    win:map("n", { "<esc>", "q" }, function()
--       win:close()
--    end)
--
--    win:map("i", "<esc>", function()
--       win:close()
--    end)
--
--    win:map({ "n", "i" }, "<enter>", function()
--       local text = api.nvim_get_current_line()
--       win:close()
--       on_submit(text)
--    end)
-- end

return M
