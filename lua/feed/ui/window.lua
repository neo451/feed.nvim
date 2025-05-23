local ut = require("feed.utils")
local Config = require("feed.config")
local api, uv = vim.api, vim.uv

---@class feed.win.Config: vim.api.keyset.win_config
---@field text? string[]
---@field wo? vim.wo|{} window options
---@field bo? vim.bo|{} buffer options
---@field b? table<string, any> buffer local variables
---@field w? table<string, any> window local variables
---@field ft? string
---@field buf? integer
---@field win? integer
---@field zen? boolean
---@field keys? table
---@field enter boolean
---@field prev_win integer
---@field is_backdrop boolean

---@class feed.win
---@field opts feed.win.Config
---@field id number
---@field win integer
---@field buf integer
---@field keys table
---@field open fun(feed.win: self)
---@field close fun(feed.win: self)
---@field valid fun(feed.win: self): boolean
---@field map fun(feed.win: self, mode: string, lhs: string, rhs: string | function)
local M = {}
M.__index = M
local id = 0

---@param opts feed.win.Config | {}
---@param enter? boolean
---@return table
function M.new(opts, enter)
   local width = opts.zen and Config.zen.width or vim.o.columns
   local height = opts.zen and vim.o.lines or vim.o.lines - (vim.o.cmdheight + 1)
   opts = vim.tbl_deep_extend("force", {
      relative = "editor",
      height = height,
      width = width,
      row = 0,
      col = (vim.o.columns - width) / 2,
      zindex = 5,
      wo = {
         winhighlight = "Normal:Normal,FloatBorder:Normal",
      },
      bo = {},
      w = {},
      b = {},
   }, opts)

   opts.show = vim.F.if_nil(opts.show, true)
   opts.enter = vim.F.if_nil(enter, true)

   opts.wo.statuscolumn = ""
   id = id + 1
   local self = setmetatable({
      opts = opts,
      id = id,
      keys = {},
   }, M)

   local done = {}
   for key, spec in pairs(opts.keys or {}) do
      if spec then
         if type(spec) == "string" then
            spec = { key, spec, desc = spec }
         elseif type(spec) == "function" then
            spec = { key, spec }
         elseif type(spec) == "table" and spec[1] and not spec[2] then
            spec = vim.deepcopy(spec) -- deepcopy just in case
            spec[1], spec[2] = key, spec[1]
         end
         local lhs = M.normkey(spec[1] or "")
         local mode = type(spec.mode) == "table" and spec.mode or { spec.mode or "n" }
         ---@cast mode string[]
         mode = #mode == 0 and { "n" } or mode
         for _, m in ipairs(mode) do
            local k = m .. ":" .. lhs
            if done[k] then
               vim.notify(
                  string
                     .format("# Duplicate key mapping for `%s` mode=%s (check case):\n```lua\n%s\n```\n```lua\n%s\n```")
                     :format(lhs, m, vim.inspect(done[k]), vim.inspect(spec))
               )
            end
            done[k] = spec
         end
         table.insert(self.keys, spec)
      end
   end

   if opts.show then
      self:show()
      if self.opts.zen then
         self:back()
      end
   end

   return self
end

function M:back()
   local bg, winblend = "#000000", 60
   local group = ("FeedBackdrop_%s"):format(bg and bg:sub(2) or "T")

   api.nvim_set_hl(0, group, { bg = bg })

   local wo = {
      winhighlight = "Normal:" .. group,
      winblend = winblend,
      colorcolumn = "",
      cursorline = false,
   }

   self.backdrop = M.new({
      is_backdrop = true,
      wo = wo,
      enter = false,
      zen = false,
      zindex = self.opts.zindex - 1,
      width = vim.o.columns,
      height = vim.o.lines,
      style = "minimal",
      border = "none",
      relative = "editor",
      focusable = false,
   }, false)
end

local win_opts = {
   "anchor",
   "border",
   "bufpos",
   "col",
   "external",
   "fixed",
   "focusable",
   "footer",
   "footer_pos",
   "height",
   "hide",
   "noautocmd",
   "relative",
   "row",
   "style",
   "title",
   "title_pos",
   "width",
   "win",
   "zindex",
}

function M:win_opts()
   local opts = {}
   for _, k in ipairs(win_opts) do
      opts[k] = self.opts[k]
   end
   return opts
end

function M:show()
   if self.opts.buf then
      self.buf = self.opts.buf
   else
      self.buf = api.nvim_create_buf(false, true)
   end

   if self.opts.text then
      api.nvim_buf_set_lines(self.buf, 0, -1, false, self.opts.text)
   end

   if self.opts.b then
      for k, v in pairs(self.opts.b) do
         api.nvim_buf_set_var(self.buf, k, v)
      end
   end

   self.win = api.nvim_open_win(self.buf, self.opts.enter, self:win_opts())

   ut.bo(self.buf, self.opts.bo)
   ut.wo(self.win, self.opts.wo)

   if self.opts.wo.winbar then
      local timer = uv.new_timer()
      local bar = self.opts.wo.winbar
      assert(timer)
      timer:start(
         0,
         100,
         vim.schedule_wrap(function()
            if not self:valid() then
               timer:stop()
               return
            end
            ut.wo(self.win, { winbar = bar })
         end)
      )
   end

   self.augroup = api.nvim_create_augroup("feed.win." .. self.id, { clear = true })

   -- update window size when resizing
   api.nvim_create_autocmd({ "VimResized", "CmdwinLeave" }, {
      group = self.augroup,
      callback = vim.schedule_wrap(function()
         self:update()
      end),
   })

   api.nvim_create_autocmd("Filetype", {
      pattern = "qf",
      group = self.augroup,
      callback = function()
         local augroup_id = api.nvim_create_augroup("feed_quick_close", { clear = true })
         api.nvim_create_autocmd("WinLeave", {
            group = augroup_id,
            callback = function()
               self:update()
               api.nvim_del_augroup_by_id(augroup_id)
            end,
         })
      end,
   })

   api.nvim_create_autocmd("CmdwinEnter", {
      group = self.augroup,
      callback = function()
         local opts = self:win_opts()
         opts.height = opts.height - vim.o.cmdwinheight
         api.nvim_win_set_config(self.win, opts)
      end,
   })

   api.nvim_create_autocmd("QuickFixCmdPre", {
      group = self.augroup,
      callback = function()
         local opts = self:win_opts()
         opts.height = opts.height - 10
         api.nvim_win_set_config(self.win, opts)
      end,
   })

   -- swap buffers when opening a new buffer in the same window
   api.nvim_create_autocmd("BufWinEnter", {
      group = self.augroup,
      callback = function()
         -- window closes, so delete the autocmd
         if not self:win_valid() then
            return true
         end

         local buf = api.nvim_win_get_buf(self.win)

         -- same buffer
         if buf == self.buf then
            return
         end

         -- another buffer was opened in this window
         -- find another window to swap with
         for _, win in ipairs(api.nvim_list_wins()) do
            if win ~= self.win and vim.bo[api.nvim_win_get_buf(win)].buftype == "" then
               vim.schedule(function()
                  api.nvim_win_set_buf(self.win, self.buf)
                  api.nvim_win_set_buf(win, buf)
                  api.nvim_set_current_win(win)
                  vim.cmd.stopinsert()
               end)
               return
            end
         end
      end,
   })

   self:maps()
end

---@param str string
function M.keycode(str)
   return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local key_cache = {}
---@param key string
function M.normkey(key)
   if key_cache[key] then
      return key_cache[key]
   end
   local function norm(v)
      local l = v:lower()
      if l == "leader" then
         return M.normkey("<leader>")
      elseif l == "localleader" then
         return M.normkey("<localleader>")
      end
      return vim.fn.keytrans(M.keycode(("<%s>"):format(v)))
   end
   local orig = key
   key = key:gsub("<lt>", "<")
   local lower = key:lower()
   if lower == "<leader>" then
      key = vim.g.mapleader
      key = vim.fn.keytrans((not key or key == "") and "\\" or key)
   elseif lower == "<localleader>" then
      key = vim.g.maplocalleader
      key = vim.fn.keytrans((not key or key == "") and "\\" or key)
   else
      local extracted = {} ---@type string[]
      local function extract(v)
         v = v:sub(2, -2)
         if v:sub(2, 2) == "-" and v:sub(1, 1):find("[aAmMcCsS]") then
            local m = v:sub(1, 1):upper()
            m = m == "A" and "M" or m
            local k = v:sub(3)
            if #k > 1 then
               return norm(v)
            end
            if m == "C" then
               k = k:upper()
            elseif m == "S" then
               return k:upper()
            end
            return ("<%s-%s>"):format(m, k)
         end
         return norm(v)
      end
      local placeholder = "_#_"
      ---@param v string
      key = key:gsub("(%b<>)", function(v)
         table.insert(extracted, extract(v))
         return placeholder
      end)
      key = vim.fn.keytrans(key):gsub("<lt>", "<")

      -- Restore extracted %b<> sequences
      local i = 0
      key = key:gsub(placeholder, function()
         i = i + 1
         return extracted[i] or ""
      end)
   end
   key_cache[orig] = key
   key_cache[key] = key
   return key
end

function M:maps()
   for _, spec in pairs(self.keys or {}) do
      local opts = vim.deepcopy(spec)
      opts[1] = nil
      opts[2] = nil
      opts.mode = nil
      ---@diagnostic disable-next-line: cast-type-mismatch
      ---@cast opts vim.keymap.set.Opts
      opts.buffer = self.buf
      opts.nowait = true
      local rhs = spec[2]
      spec.desc = spec.desc or opts.desc
      vim.keymap.set(spec.mode or "n", spec[1], rhs, opts)
   end
end

---@param mode string | string[]
---@param lhs string
---@param rhs string | function
function M:map(mode, lhs, rhs)
   local set = vim.keymap.set
   if type(lhs) == "table" then
      for _, l in ipairs(lhs) do
         set(mode, l, rhs, { buffer = self.buf, nowait = true })
      end
   else
      set(mode, lhs, rhs, { buffer = self.buf, nowait = true })
   end
end

function M:update()
   if self:valid() then
      ut.bo(self.buf, self.opts.bo)
      ut.wo(self.win, self.opts.wo)
      local opts = self:win_opts()
      opts.noautocmd = nil
      opts.height = opts.zen and vim.o.lines or vim.o.lines - (vim.o.cmdheight + 1)
      opts.width = self.opts.zen and Config.zen.width or vim.o.columns
      opts.col = (vim.o.columns - opts.width) / 2
      api.nvim_win_set_config(self.win, opts)
      if not self.opts.is_backdrop then
         api.nvim_set_current_win(self.win)
      end
   end
end

function M:close()
   local close = function(win, buf)
      if win and api.nvim_win_is_valid(win) then
         api.nvim_win_close(win, true)
      end
      if buf and api.nvim_buf_is_valid(buf) then
         api.nvim_buf_delete(buf, { force = true })
      end
      api.nvim_set_current_win(self.opts.prev_win)
   end
   local try_close
   try_close = function()
      local ok, err = pcall(close, self.win, self.buf)
      if not ok and err and err:find("E565") then
         vim.defer_fn(try_close, 50)
      else
         self.win = nil
         self.buf = nil
      end
   end
   vim.schedule(try_close)
   api.nvim_del_augroup_by_id(self.augroup)
   if self.backdrop then
      self.backdrop:close()
   end
end

function M:buf_valid()
   return self.buf and api.nvim_buf_is_valid(self.buf)
end

function M:win_valid()
   return self.win and api.nvim_win_is_valid(self.win)
end

function M:valid()
   return self:win_valid() and self:buf_valid() and api.nvim_win_get_buf(self.win) == self.buf
end

return M
