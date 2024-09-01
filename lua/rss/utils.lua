local M = {}
local config = require "rss.config"
local utf8 = require "rss.utf8"
local url = require "rss.url"
local date = require "rss.date"
local F = require "plenary.functional"
local lpeg = vim.lpeg
local C, utfR = lpeg.C, lpeg.utfR

-- TODO: handle cjk .. all non-ascii, emojis??
local fullwidth = C(
   (
      utfR(0x4E00, 0x9FFF)
      + utfR(0xFF10, 0xFF19)
      + utfR(0x3000, 0x303F)
      + utfR(0xFF01, 0xFF5E)
      + utfR(0x2000, 0x206F)
      + utfR(0xFF10, 0xFF19)
      - utfR(0x201C, 0x201D)
      - utfR(0x2026, 0x2026) --- TODO: find all exceptions
   ) ^ 1
)

function M.str_len(str)
   local len = 0
   for _, c in utf8.codes(str) do
      if fullwidth:match(c) then
         len = len + 2
      else
         len = len + 1
      end
   end
   return len
end

M.sub = function(str, startidx, endidx)
   local buffer = {}
   local len = 0
   for _, c in utf8.codes(str) do
      len = len + M.str_len(c) -- TODO: wasteful
      buffer[#buffer + 1] = c
      if len >= endidx then
         return table.concat(buffer, "", 1, #buffer - 1)
      end
   end
end

function M.format_title(str, max_len)
   max_len = max_len or 50
   local len = M.str_len(str)
   if len < max_len then
      return str .. string.rep(" ", max_len - len)
   else
      str = M.sub(str, 1, max_len)
      return str .. string.rep(" ", max_len - M.str_len(str))
   end
end

---@param tags string[]
---@return string
function M.format_tags(tags)
   tags = vim.tbl_keys(tags)
   local buffer = { "(" }
   if #tags == 0 then
      return ""
   end
   for i, tag in pairs(tags) do
      buffer[#buffer + 1] = tag
      if i ~= #tags then
         buffer[#buffer + 1] = ", "
      end
   end
   buffer[#buffer + 1] = ")"
   return table.concat(buffer, "")
end

---@param buf integer
---@param lhs string
---@param rhs string | function
function M.push_keymap(buf, lhs, rhs)
   if type(rhs) == "string" then
      vim.api.nvim_buf_set_keymap(buf, "n", lhs, rhs, { noremap = true, silent = true })
   else
      vim.api.nvim_buf_set_keymap(buf, "n", lhs, "", {
         noremap = true,
         silent = true,
         callback = rhs,
      })
   end
end

function M.clamp(min, value, max)
   return math.min(max, math.max(min, value))
end

function M.cycle(i, n)
   return i % n == 0 and n or i % n
end

-- TODO:
function M.looks_like_url(str)
   return type(str) == "string" and not str:find "[ \n\t\r]" and (url.parse(str) ~= nil)
end

local ns = vim.api.nvim_create_namespace "rss"

local normal_grp = vim.api.nvim_get_hl(0, { name = "Normal" })
local light_grp = vim.api.nvim_get_hl(0, { name = "Whitespace" })
vim.api.nvim_set_hl(ns, "rss.bold", { bold = true, fg = normal_grp.fg, bg = normal_grp.bg })
vim.api.nvim_set_hl(ns, "rss.light", { bold = true, fg = light_grp.fg, bg = light_grp.bg })

-- function M.set_text_bold(buf, start_line, start_col, end_col)
-- 	local ns = vim.api.nvim_create_namespace("rss.bold")
-- 	vim.api.nvim_buf_add_highlight(buf, ns, "rss.bold", start_line - 1, start_col, end_col)
-- end
--
-- function M.set_text_light(buf, start_line, start_col, end_col)
-- 	local ns = vim.api.nvim_create_namespace("rss.light")
-- end

---@param buf integer
function M.highlight_entry(buf)
   local len = { 6, 5, 7, 5, 5 }
   for i = 0, 4 do
      vim.highlight.range(buf, ns, "Title", { i, 0 }, { i, len[i + 1] })
   end
end

---@param buf integer
function M.highlight_index(buf)
   local len = #vim.api.nvim_buf_get_lines(buf, 0, -1, true) -- TODO: api??
   for i = 1, len do
      -- vim.highlight.range(buf, ns, "Title", { i, 0 }, { i, 10 })
      vim.api.nvim_buf_add_highlight(buf, ns, "Title", i, 0, 10)
      vim.api.nvim_buf_add_highlight(buf, ns, "rss.bold", i, 0, -1)
      -- vim.highlight.range(buf, 1, "rss.bold", { i, 0 }, { i, 10 })
   end
end

-- (defun elfeed-looks-like-url-p (string)
--   "Return true if STRING looks like it could be a URL."
--   (and (stringp string)
--        (not (string-match-p "[ \n\t\r]" string))
--        (not (null (url-type (url-generic-parse-url string))))))
--
-- (defun elfeed-format-column (string width &optional align)
--   "Return STRING truncated or padded to WIDTH following ALIGNment.
-- Align should be a keyword :left or :right."
--   (if (<= width 0)
--       ""
--     (format (format "%%%s%d.%ds" (if (eq align :left) "-" "") width width)
--             string)))
--
--

--
-- (defun elfeed-cleanup (name)
--   "Trim trailing and leading spaces and collapse multiple spaces."
--   (let ((trim (replace-regexp-in-string "[\f\n\r\t\v ]+" " " (or name ""))))
--     (replace-regexp-in-string "^ +\\| +$" "" trim)))
--
-- (defun elfeed-parse-simple-iso-8601 (string)
--   "Attempt to parse STRING as a simply formatted ISO 8601 date.
-- Examples: 2015-02-22, 2015-02, 20150222"
--   (let* ((re (cl-flet ((re-numbers (num) (format "\\([0-9]\\{%s\\}\\)" num)))
--                (format "^%s-?%s-?%s?\\(T%s:%s:?%s?\\)?"
--                        (re-numbers 4)
--                        (re-numbers 2)
--                        (re-numbers 2)
--                        (re-numbers 2)
--                        (re-numbers 2)
--                        (re-numbers 2))))
--          (matches (save-match-data
--                     (when (string-match re string)
--                       (cl-loop for i from 1 to 7
--                                collect (let ((match (match-string i string)))
--                                          (and match (string-to-number match))))))))
--     (when matches
--       (cl-multiple-value-bind (year month day _ hour min sec) matches
--         (float-time (encode-time (or sec 0) (or min 0) (or hour 0)
--                                  (or day 1) month year t))))))
--
-- (defun elfeed-new-date-for-entry (old-date new-date)
--   "Decide entry date, given an existing date (nil for new) and a new date.
-- Existing entries' dates are unchanged if the new date is not
-- parseable. New entries with unparseable dates default to the
-- current time."
--   (or (elfeed-float-time new-date)
--       old-date
--       (float-time)))
--
-- (defun elfeed-float-time (date)
--   "Like `float-time' but accept anything reasonable for DATE.
-- Defaults to nil if DATE could not be parsed. Date is allowed to
-- be relative to now (`elfeed-time-duration')."
--   (cl-typecase date
--     (string
--      (let ((iso-8601 (elfeed-parse-simple-iso-8601 date)))
--        (if iso-8601
--            iso-8601
--          (let ((duration (elfeed-time-duration date)))
--            (if duration
--                (- (float-time) duration)
--              (let ((time (ignore-errors (date-to-time date))))
--                ;; check if date-to-time failed, silently or otherwise
--                (unless (or (null time) (equal time '(14445 17280)))
--                  (float-time time))))))))
--     (integer date)
--     (otherwise nil)))

-- print(os.date("%Y-%m-%d %H:%M:%S", os.time()))

-- print("123" < "12")

return M
