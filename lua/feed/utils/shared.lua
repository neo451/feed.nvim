local M = {}

local vim = vim
local api, fn = vim.api, vim.fn
local ipairs, pcall, dofile, type = ipairs, pcall, dofile, type
local io = io

M.listify = function(t)
   if type(t) ~= "table" then
      return { t }
   end
   return (#t == 0 and not vim.islist(t)) and { t } or t
end

M.load_file = function(fp)
   local ok, res = pcall(dofile, fp)
   if ok and res then
      return res
   else
      vim.notify(fp .. " not loaded")
      return {}
   end
end

---@param fp string
---@param str string
---@param mode "w" | "a"
---@return boolean
M.save_file = function(fp, str, mode)
   mode = mode or "w"
   local f = io.open(fp, mode)
   if f then
      f:write(str)
      f:close()
      return true
   else
      return false
   end
end

---@param path string
---@return string?
M.read_file = function(path)
   local ret
   local f = io.open(path, "r")
   assert(f, "could not open " .. path)
   ret = f:read("*a")
   f:close()
   return ret
end

M.get_selection = function()
   local mode = api.nvim_get_mode().mode

   if mode == "n" then
      return { fn.expand("<cexpr>") }
   end

   local ok, selection = pcall(function()
      return fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
   end)

   if ok then
      return selection
   end
end

---@return boolean
M.in_index = function()
   return api.nvim_buf_get_name(0):find("FeedIndex") ~= nil
end

---@return boolean
M.in_entry = function()
   return api.nvim_buf_get_name(0):find("FeedEntry") ~= nil
end

---@param choices table | string
---@return string?
M.choose_backend = function(choices)
   local alias = {
      ["mini.pick"] = "pick",
      ["mini.notify"] = "mini",
   }
   if type(choices) == "string" then
      return alias[choices] or choices
   end
   for _, v in ipairs(choices) do
      if pcall(require, v) then
         return alias[v] and alias[v] or v
      end
   end
end

---@param feeds feed.opml
---@param all boolean
---@return string[]
M.feedlist = function(feeds, all)
   return vim.iter(feeds)
      :filter(function(_, v)
         if all then
            return true
         else
            return type(v) == "table"
         end
      end)
      :fold({}, function(acc, k)
         table.insert(acc, k)
         return acc
      end)
end

---@param url string
---@param feeds feed.opml
---@return string
M.url2name = function(url, feeds)
   if feeds[url] then
      local feed = feeds[url]
      if feed.title then
         return feed.title or url
      end
   end
   return url
end

--- Set window-local options.
---@param win number
---@param wo vim.wo
M.wo = function(win, wo)
   for k, v in pairs(wo or {}) do
      api.nvim_set_option_value(k, v, { scope = "local", win = win })
   end
end

--- Set buffer-local options.
---@param buf number
---@param bo vim.bo
M.bo = function(buf, bo)
   for k, v in pairs(bo or {}) do
      api.nvim_set_option_value(k, v, { buf = buf })
   end
end

M.list2lookup = function(list)
   local lookup = {}
   for _, v in ipairs(list) do
      lookup[v] = true
   end
   return lookup
end

---@return boolean
M.is_headless = function()
   return vim.tbl_isempty(api.nvim_list_uis())
end

---1. replace html entities,
---2. replace newline as space,
---3. trims
---@param str string?
---@return string?
M.clean = function(str)
   str = str and require("feed.lib.entities").decode(str)
   str = str and string.gsub(str, "\n", " ")
   str = str and vim.trim(str)
   return str
end

-- https://github.com/f-person/auto-dark-mode.nvim
M.dark_mode = function()
   local state = {}
   local uv = vim.uv
   local os_uname = uv.os_uname()

   if string.match(os_uname.release, "WSL") then
      state.system = "WSL"
   elseif string.match(os_uname.release, "orbstack") then
      state.system = "OrbStack"
   else
      state.system = os_uname.sysname
   end

   if state.system == "Darwin" or state.system == "OrbStack" then
      local query_command = { "defaults", "read", "-g", "AppleInterfaceStyle" }
      if state.system == "OrbStack" then
         query_command = vim.list_extend({ "mac" }, query_command)
      end
      state.query_command = query_command
   elseif state.system == "Linux" then
      if vim.fn.executable("dbus-send") == 0 then
         error(
            "auto-dark-mode.nvim: `dbus-send` is not available. The Linux implementation of auto-dark-mode.nvim relies on `dbus-send` being on the `$PATH`."
         )
      end

      state.query_command = {
         "dbus-send",
         "--session",
         "--print-reply=literal",
         "--reply-timeout=1000",
         "--dest=org.freedesktop.portal.Desktop",
         "/org/freedesktop/portal/desktop",
         "org.freedesktop.portal.Settings.Read",
         "string:org.freedesktop.appearance",
         "string:color-scheme",
      }
   elseif state.system == "Windows_NT" or state.system == "WSL" then
      local reg = "reg.exe"

      -- gracefully handle a bunch of WSL specific errors
      if state.system == "WSL" then
         -- automount not being enabled
         if not uv.fs_stat("/mnt/c/Windows") then
            error(
               "auto-dark-mode.nvim: Your WSL configuration doesn't enable `automount`. Please see https://learn.microsoft.com/en-us/windows/wsl/wsl-config#automount-settings."
            )
         end

         -- binfmt not being provided for windows executables
         if
            not (
               uv.fs_stat("/proc/sys/fs/binfmt_misc/WSLInterop")
               or uv.fs_stat("/proc/sys/fs/binfmt_misc/WSLInterop-late")
            )
         then
            error(
               "auto-dark-mode.nvim: Your WSL configuration doesn't enable `interop`. Please see https://learn.microsoft.com/en-us/windows/wsl/wsl-config#interop-settings."
            )
         end

         -- `appendWindowsPath` being set to false
         if vim.fn.executable("reg.exe") == 0 then
            local hardcoded_path = "/mnt/c/Windows/system32/reg.exe"
            if uv.fs_stat(hardcoded_path) then
               reg = hardcoded_path
            else
               error(
                  "auto-dark-mode.nvim: `reg.exe` cannot be found. To support syncing with the host system, this plugin relies on `reg.exe` being on the `$PATH`."
               )
            end
         end
      end

      state.query_command = {
         reg,
         "Query",
         "HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
         "/v",
         "AppsUseLightTheme",
      }
   else
      return
   end

   -- -- when on a supported unix system, and the userid is root
   if (state.system == "Darwin" or state.system == "Linux") and uv.getuid() == 0 then
      local sudo_user = vim.env.SUDO_USER

      if not sudo_user then
         error(
            "auto-dark-mode.nvim: Running as `root`, but `$SUDO_USER` is not set. Please open an issue to add support for your setup."
         )
      end

      local prefixed_cmd = { "sudo", "--user", sudo_user }
      vim.list_extend(prefixed_cmd, state.query_command)

      state.query_command = prefixed_cmd
   end

   -- Parses the query response for each system, returning the current appearance,
   -- or `nil` if it can't be resolved.
   ---@param stdout string
   ---@param stderr string
   ---@return "dark" | "light"?
   local function parse_query_response(stdout, stderr)
      if state.system == "Linux" then
         -- https://github.com/flatpak/xdg-desktop-portal/blob/c0f0eb103effdcf3701a1bf53f12fe953fbf0b75/data/org.freedesktop.impl.portal.Settings.xml#L32-L46
         -- 0: no preference
         -- 1: dark
         -- 2: light
         if string.match(stdout, "uint32 1") ~= nil then
            return "dark"
         -- else
         elseif string.match(stdout, "uint32 2") ~= nil then
            return "light"
         else
            return "dark"
         end
      elseif state.system == "Darwin" or state.system == "OrbStack" then
         return stdout == "Dark\n" and "dark" or "light"
      elseif state.system == "Windows_NT" or state.system == "WSL" then
         -- AppsUseLightTheme REG_DWORD 0x0 : dark
         -- AppsUseLightTheme REG_DWORD 0x1 : light
         return string.match(stdout, "0x1") and "light" or "dark"
      end

      return nil
   end

   local obj = vim.system(state.query_command, {}):wait()

   return parse_query_response(obj.stdout, obj.stderr)
end

return M
