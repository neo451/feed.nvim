local ut = require("feed.utils")
local Config = require("feed.config")
local api = vim.api

---@class feed.win.Config: vim.api.keyset.win_config
---@field text? string | string[]
---@field wo? vim.wo|{} window options
---@field bo? vim.bo|{} buffer options
---@field b? table<string, any> buffer local variables
---@field w? table<string, any> window local variables
---@field ft? string
---@field buf? integer
---@field win? integer
---@field zen? boolean
---@field on_open? function
---@field on_leave? function
---@field keys? table
---@field enter boolean

---@class feed.win
---@field opts feed.win.Config
---@field id number
---@field win integer
---@field buf integer
---@field open fun(feed.win: self)
---@field close fun(feed.win: self)
---@field valid fun(feed.win: self): boolean
---@field map fun(feed.win: self, mode: string, lhs: string, rhs: string | function)
---@field backdrop feed.win
local M = {}
M.__index = M
local id = 0

local og = {
   wo = {},
   bo = {},
}

---@param opts feed.win.Config | {}
---@param enter? boolean
---@return table
function M.new(opts, enter)
   local width = opts.zen and Config.zen.width or vim.o.columns
   opts = vim.tbl_deep_extend("force", {
      relative = "editor",
      height = vim.o.lines - 1,
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

   if Config.layout.padding.enabled then
      opts.wo.statuscolumn = " "
   else
      opts.wo.statuscolumn = ""
   end
   id = id + 1
   local self = setmetatable({
      opts = opts,
      id = id,
      backdrop = opts.backdrop or nil,
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
   if not self.backdrop then
      return
   end
   local bg, winblend = "#000000", 60
   local group = ("SnacksBackdrop_%s"):format(bg and bg:sub(2) or "T")
   vim.api.nvim_set_hl(0, group, { bg = bg })

   local wo = {
      winhighlight = "Normal:" .. group,
      winblend = winblend,
      colorcolumn = "",
      cursorline = false,
   }

   for k in pairs(wo) do
      og.wo[k] = vim.api.nvim_get_option_value(k, { win = self.win })
   end

   ut.wo(self.backdrop.win, wo)
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
      self.buf = vim.api.nvim_create_buf(false, true)
   end

   if self.opts.text then
      local lines = type(self.opts.text) == "string" and vim.split(self.opts.text, "\n") or self.opts.text
      vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
   end

   if self.opts.b then
      for k, v in pairs(self.opts.b) do
         vim.api.nvim_buf_set_var(self.buf, k, v)
      end
   end

   if self.opts.on_open then
      api.nvim_create_autocmd("BufEnter", {
         buffer = self.buf,
         callback = self.opts.on_open,
      })
   end

   if self.opts.on_leave then
      api.nvim_create_autocmd("BufLeave", {
         buffer = self.buf,
         callback = self.opts.on_leave,
      })
   end

   self.win = vim.api.nvim_open_win(self.buf, self.opts.enter, self:win_opts())

   ut.bo(self.buf, self.opts.bo)
   ut.wo(self.win, self.opts.wo)

   -- FIX: handle popup windows hide self
   self.augroup = vim.api.nvim_create_augroup("feed.win." .. self.id, { clear = true })

   -- update window size when resizing
   vim.api.nvim_create_autocmd("VimResized", {
      group = self.augroup,
      callback = function()
         self:update()
      end,
   })

   -- swap buffers when opening a new buffer in the same window
   vim.api.nvim_create_autocmd("BufWinEnter", {
      group = self.augroup,
      callback = function()
         -- window closes, so delete the autocmd
         if not self:win_valid() then
            return true
         end

         local buf = vim.api.nvim_win_get_buf(self.win)

         -- same buffer
         if buf == self.buf then
            return
         end

         -- another buffer was opened in this window
         -- find another window to swap with
         for _, win in ipairs(vim.api.nvim_list_wins()) do
            if win ~= self.win and vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "" then
               vim.schedule(function()
                  vim.api.nvim_win_set_buf(self.win, self.buf)
                  vim.api.nvim_win_set_buf(win, buf)
                  vim.api.nvim_set_current_win(win)
                  vim.cmd.stopinsert()
               end)
               return
            end
         end
      end,
   })

   self:maps()
end

function M:maps()
   if self.opts.keys == nil then
      return
   end
   for rhs, lhs in pairs(self.opts.keys) do
      local opts = {}
      opts.buffer = self.buf
      opts.nowait = true
      opts.desc = "Feed " .. rhs
      assert(type(rhs) == "string")
      vim.keymap.set("n", lhs, function()
         vim.cmd.Feed(rhs)
      end, opts)
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
      opts.height = vim.o.lines - 1
      opts.width = self.opts.zen and Config.zen.width or vim.o.columns
      opts.col = (vim.o.columns - opts.width) / 2
      vim.api.nvim_win_set_config(self.win, opts)
   end
end

function M:close()
   local close = function(win, buf)
      if win and vim.api.nvim_win_is_valid(win) then
         vim.api.nvim_win_close(win, true)
      end
      if buf and vim.api.nvim_buf_is_valid(buf) then
         vim.api.nvim_buf_delete(buf, { force = true })
      end
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
      if self.backdrop then
         ut.wo(self.backdrop.win, og.wo)
      end
   end
   vim.schedule(try_close)
end

function M:buf_valid()
   return self.buf and vim.api.nvim_buf_is_valid(self.buf)
end

function M:win_valid()
   return self.win and vim.api.nvim_win_is_valid(self.win)
end

function M:valid()
   return self:win_valid() and self:buf_valid() and vim.api.nvim_win_get_buf(self.win) == self.buf
end

return M
