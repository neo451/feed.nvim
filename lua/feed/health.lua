local M = {}
local health = vim.health

local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error = health.error or health.report_error

local is_win = vim.api.nvim_call_function("has", { "win32" }) == 1

local dependencies = {
   { name = "curl", optional = false, min_ver = 8 },
   { name = "pandoc", optional = false, min_ver = 3 },
}

local plugins = {
   { lib = "plenary", optional = false, info = "required for feed.nvim to work" },
   { lib = "pathlib", optional = false, info = "required for handling path" },
   { lib = "nui", optional = false, info = "required for text rendering" },
   --- TODO: optional and good if one is found
   { lib = "nvim-treesitter", optional = true, info = "required for installing TS parsers if you don't use rocks.nvim" },
}

local parsers = {
   "markdown",
   "xml",
   "html",
}

local function check_treesitter_parser(name)
   local res, _ = pcall(vim.treesitter.language.inspect, name)
   if res then
      ok(name .. " installed")
   else
      local lib_not_installed = name .. " not found."
      error(lib_not_installed)
   end
end

local function check_lualib_installed(plugin)
   local res, _ = pcall(require, plugin.lib)
   if res then
      ok(plugin.lib .. " installed")
   else
      local lib_not_installed = plugin.lib .. " not found."
      if plugin.optional then
         warn(("%s %s"):format(lib_not_installed, plugin.info))
      else
         error(("%s %s"):format(lib_not_installed, plugin.info))
      end
   end
end

local check_binary_installed = function(package)
   local binary = package.name
   local found = vim.fn.executable(binary) == 1
   if not found and is_win then
      binary = binary .. ".exe"
      found = vim.fn.executable(binary) == 1
   end
   if found then
      local results = vim.system({ binary, "--version" }):wait()
      local version = vim.version.parse(results.stdout)
      if version then
         if version.major < package.min_ver then
            warn(binary .. " found: but version is too old", "Please install " .. package.min_ver .. ".xx")
            return false
         else
            ok(binary .. " " .. version.major .. "." .. version.minor .. " found")
            return true
         end
      end
   end
end

M.check_binary_installed = check_binary_installed

M.check = function()
   vim.health.start "feed report"
   for _, binary in ipairs(dependencies) do
      check_binary_installed(binary)
   end
   for _, plug in ipairs(plugins) do
      check_lualib_installed(plug)
   end
   for _, name in ipairs(parsers) do
      check_treesitter_parser(name)
   end
   return true
end

return M
