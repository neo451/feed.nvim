local M = {}
local health = vim.health

local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error = health.error or health.report_error

local is_win = vim.api.nvim_call_function("has", { "win32" }) == 1

local dependencies = {
   { name = "curl", optional = false },
}

local plugins = {
   { lib = "plenary", optional = false, info = "required for feed.nvim to work" },
   { lib = "conform", optional = true, info = "required for formatting markdowns" },
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
      local handle = io.popen(binary .. " --version")
      if handle then
         local binary_version = handle:read "*a"
         handle:close()
         return true, binary_version
      end
   end
end

M.check = function()
   vim.health.start "feed report"
   if check_binary_installed(dependencies[1]) then
      ok "curl installed"
   else
      warn "curl not found"
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
