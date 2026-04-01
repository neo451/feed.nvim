---@class feed.path
---@field save fun(self: feed.path, content: string)
---@field load fun(self: feed.path): table
---@field absolute boolean

local Path = {}
local uv = vim.uv
local ut = require("feed.utils")
local save_file = ut.save_file
local read_file = ut.read_file
local load_file = ut.load_file

-- selene: allow(unused_variable)
local sep = string.sub(package.config, 1, 1)

---@param path string | string[] | feed.path
---@return table
Path.new = function(path)
   if getmetatable(path) and getmetatable(path).__index == Path then
      return path
   end

   local absolute = false
   if type(path) == "string" then
      path = vim.fs.normalize(path)
      absolute = vim.startswith(path, sep)
      path = vim.split(path, sep)
      if absolute and path[1] == "" then
         table.remove(path, 1)
      end
   end
   return setmetatable({ path = path, absolute = absolute }, {
      __index = Path,
      __tostring = function(self)
         local joined = vim.fs.joinpath(unpack(self.path))
         if self.absolute then
            return sep .. joined
         end
         return joined
      end,
      __div = function(self, other)
          local p = vim.deepcopy(self.path)
          table.insert(p, other)
          return setmetatable({ path = p, absolute = self.absolute }, getmetatable(self))
      end,
   })
end

---@param dir string
local function rmdir(dir)
   for name, t in vim.fs.dir(dir) do
      name = dir .. "/" .. name
      local ok = (t == "directory") and uv.fs_rmdir(name) or uv.fs_unlink(name)
      if not ok then
         return ok
      end
   end
   return uv.fs_rmdir(dir)
end

Path.rm = function(self)
   local fp = tostring(self)
   if vim.fs.rm then
      vim.fs.rm(fp, { recursive = true })
   else
      if uv.fs_stat(fp).type == "directory" then
         rmdir(fp)
      else
         uv.fs_unlink(fp)
      end
   end
end

---@param content table | string
Path.save = function(self, content)
   local fp = tostring(self)
   if type(content) == "string" then
      save_file(fp, content, "w")
   else
      save_file(fp, "return " .. vim.inspect(content), "w")
   end
end

---@param line string
Path.append = function(self, line)
   local fp = tostring(self)
   save_file(fp, line, "a")
end

---@return table
Path.load = function(self)
   return load_file(tostring(self))
end

---@return table
Path.read = function(self)
   return read_file(tostring(self))
end

Path.mkdir = function(self)
   vim.fn.mkdir(tostring(self), "p")
end

return setmetatable(Path, {
   __call = function(_, path)
      return Path.new(path)
   end,
})
