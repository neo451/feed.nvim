local Menu = require "nui.menu"

local select = function(items, opts, on_submit)
   local lines = {}
   for _, v in ipairs(items) do
      lines[#lines + 1] = Menu.item(opts.format_item(v))
   end

   local menu = Menu({
      position = "50%",
      size = {
         width = 45,
         height = 10,
      },
      border = {
         style = "single",
         text = {
            top = opts.prompt,
            top_align = "center",
         },
      },
      win_options = {
         winhighlight = "Normal:Normal,FloatBorder:Normal",
      },
   }, {
      lines = lines,
      max_width = 20,
      keymap = {
         focus_next = { "j", "<Down>", "<Tab>" },
         focus_prev = { "k", "<Up>", "<S-Tab>" },
         close = { "q", "<C-c>" },
         submit = { "<CR>", "<Space>" },
      },
      on_submit = on_submit,
   })
   menu:mount()
end

return {
   select = select,
}

-- mount the component
