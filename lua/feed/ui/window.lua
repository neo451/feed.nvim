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
---@field kind "float" | "tab" | "replace"

---@class feed.win
---@field opts feed.win.Config
---@field id number
---@field win integer
---@field buf integer
---@field prev_buf integer
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
      kind = "float",
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

   for _, keys in pairs(self.opts.keys or {}) do
      local lhs, rhs = unpack(keys)
      vim.keymap.set("n", lhs, rhs, { buffer = self.buf })
   end

   if self.opts.text then
      api.nvim_buf_set_lines(self.buf, 0, -1, false, self.opts.text)
   end

   if self.opts.b then
      for k, v in pairs(self.opts.b) do
         api.nvim_buf_set_var(self.buf, k, v)
      end
   end

   local kind = self.opts.kind

   if kind == "float" then
      self.win = api.nvim_open_win(self.buf, self.opts.enter, self:win_opts())
   elseif kind == "tab" then
      vim.cmd("tab sb " .. self.buf)
      self.win = api.nvim_get_current_win()
   elseif kind == "replace" then
      self.prev_buf = api.nvim_get_current_buf()
      api.nvim_set_current_buf(self.buf)
      self.win = api.nvim_get_current_win()
   end

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
end

function M:update()
   if self:valid() and self.opts.kind == "float" then
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
   if self.opts.kind == "replace" then
      api.nvim_buf_delete(self.buf, { force = true })
      if self.prev_buf then
         api.nvim_win_set_buf(self.win, self.prev_buf)
      end
      return
   end

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

---@param fn fun(...): any
---@param ...any
---@return boolean|any
local function try(fn, ...)
   local ok, result = pcall(fn, ...)
   if not ok then
      require("neogit.logger").error(result)
      return false
   else
      return result or true
   end
end

--- Safely close a window
---@param winid integer
---@param force boolean
local function safe_win_close(winid, force)
   local success = try(vim.api.nvim_win_close, winid, force)
   if not success then
      pcall(vim.cmd, "b#")
   end
end

function M:hide()
   if self.opts.kind == "replace" then
      if self.prev_buf and api.nvim_buf_is_loaded(self.prev_buf) then
         api.nvim_set_current_buf(self.prev_buf)
         self.prev_buf = nil
      end
   else
      safe_win_close(self.win, true)
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
