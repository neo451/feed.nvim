local ut = require("feed.utils")
local Config = require("feed.config")

local Win = {}
local id = 0

---@class feed.win
---@field opts feed.win.Config
---@field id number
---@field win integer
---@field buf integer
---@field open fun(feed.win: self)
---@field close fun(feed.win: self)
---@field valid fun(feed.win: self): boolean
---@field map fun(feed.win: self, mode: string, lhs: string, rhs: string | function)

---@class feed.win.Config: vim.api.keyset.win_config
---@field text? string | string[]
---@field wo? vim.wo|{} window options
---@field bo? vim.bo|{} buffer options
---@field b? table<string, any> buffer local variables
---@field w? table<string, any> window local variables
---@field ft? string

---@param opts feed.win.Config | {}
---@param enter? boolean
---@return table
function Win.new(opts, enter)
   opts = vim.tbl_deep_extend("force", {
      relative = "editor",
      height = vim.o.lines - 1,
      width = vim.o.columns,
      row = 0,
      col = 0,
      zindex = 5,
      wo = {
         winhighlight = "Normal:Normal,FloatBorder:Normal",
      },
      bo = {},
      w = {},
      b = {},
   }, opts)

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
   }, { __index = Win })

   if opts.show ~= false then
      self:show()
   end

   return self
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

function Win:win_opts()
   local opts = {}
   for _, k in ipairs(win_opts) do
      opts[k] = self.opts[k]
   end
   return opts
end

local split_minimal_wo = {
   cursorcolumn = false,
   cursorline = false,
   cursorlineopt = "both",
   fillchars = "eob: ,lastline:…",
   list = false,
   listchars = "extends:…,tab:  ",
   number = false,
   relativenumber = false,
   signcolumn = "no",
   spell = false,
   winbar = "",
   statuscolumn = "",
   wrap = false,
   sidescrolloff = 0,
}

function Win:show()
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

   self.augroup = vim.api.nvim_create_augroup("feed_win_" .. self.id, { clear = true })

   if self.opts.autocmds then
      for k, cb in pairs(self.opts.autocmds) do
         vim.api.nvim_create_autocmd(k, {
            -- group = self.augroup,
            buffer = self.buf,
            callback = function()
               cb(self)
            end,
         })
      end
   end

   self.win = vim.api.nvim_open_win(self.buf, self.opts.enter, self:win_opts())

   ut.bo(self.buf, self.opts.bo)
   ut.wo(self.win, self.opts.wo)

   -- FIX: handle popup windows hide self

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

function Win:maps()
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

--- like vim.api.nvim_buf_set_keymap but with buffer set to self.buf
---@param mode string | string[]
---@param lhs string
---@param rhs string | function
function Win:map(mode, lhs, rhs)
   local set = vim.keymap.set
   if type(lhs) == "table" then
      for _, l in ipairs(lhs) do
         set(mode, l, rhs, { buffer = self.buf, nowait = true })
      end
   else
      set(mode, lhs, rhs, { buffer = self.buf, nowait = true })
   end
end

function Win:update()
   if self:valid() then
      ut.bo(self.buf, self.opts.bo)
      ut.wo(self.win, self.opts.wo)
      local opts = self:win_opts()
      opts.noautocmd = nil
      opts.height = vim.o.lines - 1
      opts.width = vim.o.columns
      vim.api.nvim_win_set_config(self.win, opts)
   end
end

function Win:close(opts)
   opts = opts or {}
   local win = self.win
   local buf = self.buf

   self.win = nil
   self.buf = nil

   local close = function()
      if win and vim.api.nvim_win_is_valid(win) then
         vim.api.nvim_win_close(win, true)
      end
      if buf and vim.api.nvim_buf_is_valid(buf) then
         vim.api.nvim_buf_delete(buf, { force = true })
      end
      if self.augroup then
         pcall(vim.api.nvim_del_augroup_by_id, self.augroup)
         self.augroup = nil
      end
      vim.api.nvim_set_current_win(self.opts.prev_win or 0)
   end
   local try_close
   try_close = function()
      local ok, err = pcall(close)
      if not ok and err and err:find("E565") then
         vim.defer_fn(try_close, 50)
      end
   end
   vim.schedule(try_close)
end

function Win:buf_valid()
   return self.buf and vim.api.nvim_buf_is_valid(self.buf)
end

function Win:win_valid()
   return self.win and vim.api.nvim_win_is_valid(self.win)
end

function Win:valid()
   return self:win_valid() and self:buf_valid() and vim.api.nvim_win_get_buf(self.win) == self.buf
end

return Win
