local ut = require "feed.utils"

local M = {}
local id = 0

---@class feed.win.Config: vim.api.keyset.win_config
---@field wo? vim.wo|{} window options
---@field bo? vim.bo|{} buffer options
---@field b? table<string, any> buffer local variables
---@field w? table<string, any> window local variables
---@field ft? string filetype to use for treesitter/syntax highlighting. Won't override existing filetype

---@param opts feed.win.Config | {}
---@return table
function M.new(opts)
   opts = vim.tbl_extend("keep", opts, {
      relative = "editor",
      height = vim.o.lines,
      width = vim.o.columns,
      row = 0,
      col = 0,
      zindex = 50,
      wo = {},
      bo = {},
      w = {},
      b = {},
   })
   id = id + 1
   local self = setmetatable({
      opts = opts,
      id = id,
   }, { __index = M })

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


function M:win_opts()
   local opts = {}
   for _, k in ipairs(win_opts) do
      opts[k] = self.opts[k]
   end
   opts.height = vim.o.lines
   opts.width = vim.o.columns
   return opts
end

function M:show()
   if self.opts.buf then
      self.buf = self.opts.buf
   else
      self.buf = vim.api.nvim_create_buf(false, true)
   end

   if self.opts.b then
      for k, v in pairs(self.opts.b) do
         vim.api.nvim_buf_set_var(self.buf, k, v)
      end
   end

   self.augroup = vim.api.nvim_create_augroup("feed_win_" .. self.id, { clear = true })

   if self.opts.autocmds then
      for k, v in pairs(self.opts.autocmds) do
         vim.api.nvim_create_autocmd(k, {
            -- group = self.augroup,
            buffer = self.buf,
            callback = v
         })
      end
   end

   self.win = vim.api.nvim_open_win(self.buf, true, self:win_opts())

   ut.wo(self.win, self.opts.wo)
   ut.bo(self.buf, self.opts.bo)

   -- TODO: handle popup windows hide self

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

         self:map()

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
   self:map()
end

function M:map()
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

function M:update()
   if self:valid() then
      ut.bo(self.buf, self.opts.bo)
      ut.wo(self.win, self.opts.wo)
      local opts = self:win_opts()
      opts.noautocmd = nil
      vim.api.nvim_win_set_config(self.win, opts)
   end
end

---@param opts? { buf: boolean }
function M:close(opts)
   opts = opts or {}

   local win = self.win
   local buf = self.buf

   self.win = nil
   if buf then
      self.buf = nil
   end
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
