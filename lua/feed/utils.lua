local M = {}
local url = require "feed.url"
local strings = require "plenary.strings"

---porperly align, justify and trucate the title
---@param str any
---@param max_len any
---@param right_justify any
---@return unknown
function M.format_title(str, max_len, right_justify)
   local len = vim.api.nvim_strwidth(str)
   if len < max_len then
      return strings.align_str(str, max_len, right_justify)
   else
      return strings.align_str(strings.truncate(str, max_len), max_len, right_justify)
   end
end

---@param tags string[]
---@return string
function M.format_tags(tags)
   tags = vim.tbl_keys(tags)
   if #tags == 0 then
      return ""
   end
   local buffer = { "(" }
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

local ns = vim.api.nvim_create_namespace "feed"
local normal_grp = vim.api.nvim_get_hl(0, { name = "Normal" })
local light_grp = vim.api.nvim_get_hl(0, { name = "Whitespace" })
vim.api.nvim_set_hl(ns, "feed.bold", { bold = true, fg = normal_grp.fg, bg = normal_grp.bg })
vim.api.nvim_set_hl(ns, "feed.light", { bold = true, fg = light_grp.fg, bg = light_grp.bg })

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
      vim.api.nvim_buf_add_highlight(buf, ns, "Title", i, 0, 10)
      vim.api.nvim_buf_add_highlight(buf, ns, "feed.bold", i, 0, -1)
   end
end

---check if an usercommnad exists, so as a easy way to check if plugin exists
---@param str any
---@return boolean
function M.check_command(str)
   local global_commands = vim.api.nvim_get_commands {}
   if global_commands[str] then
      return true
   end
   return false
end

-- (defun elfeed-looks-like-url-p (string)
--   "Return true if STRING looks like it could be a URL."
--   (and (stringp string)
--        (not (string-match-p "[ \n\t\r]" string))
--        (not (null (url-type (url-generic-parse-url string))))))

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

return M
