local M = {}

---@param user_config feed.userConfig
function M.setup(user_config)
  local config = require "feed.config"
  config.resolve(user_config)
  require("feed.db").prepare_db(config.db_dir)

  local render = require "feed.render"
  local ut = require "feed.utils"
  local cmds = require("feed.commands").cmds

  config.og_colorscheme = vim.g.colors_name
  render.prepare_bufs(cmds)

  if ut.check_command "Telescope" then
    pcall(require("telescope").load_extension, "feed")
  end

  vim.api.nvim_create_user_command("Feed", function(opts)
    if #opts.fargs == 0 then
      require("feed.render").show_index()
    else
      require("feed.commands").load_command(opts.fargs)
    end
  end, {
    nargs = "*",
    complete = function(_, line)
      local cmds_list = vim.tbl_keys(require("feed.commands").cmds)
      local l = vim.split(line, "%s+")
      return vim.tbl_filter(function(val)
        return vim.startswith(val, l[#l])
      end, cmds_list)
    end,
  })
end

setmetatable(M, {
  __index = function(self, k)
    if not rawget(self, k) then
      return rawget(require("feed.commands").cmds, k)
    end
  end,
})

return M
