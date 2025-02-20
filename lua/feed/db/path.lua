---@class feed.path
---@field save fun(self: feed.path, content: string)
---@field load fun(self: feed.path): table

local Path = {}
local uv = vim.uv
local ut = require("feed.utils")
local save_file = ut.save_file
local read_file = ut.read_file
local load_file = ut.load_file

local sep = package.config:sub(1, 1)

---@param path string | string[]
---@return table
Path.new = function(path)
   if type(path) == "string" then
      path = vim.fs.normalize(path)
      path = vim.split(path, sep)
   end
   return setmetatable({ path = path }, {
      __index = Path,
      __tostring = function(self)
         return vim.fs.joinpath(unpack(self.path))
      end,
      __div = function(self, other)
         local p = vim.deepcopy(self.path)
         table.insert(p, other)
         return Path(p)
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
