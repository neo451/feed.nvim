local api = require "image"
IMG = nil

api.from_url("https://gist.ro/s/remote.png", {
   -- window = 1000, -- optional, binds image to a window and its bounds
   buffer = vim.api.nvim_get_current_buf(), -- optional, binds image to a buffer (paired with window binding)
   with_virtual_padding = true, -- optional, pads vertically with extmarks, defaults to false

   -- optional, binds image to an extmark which it follows. Forced to be true when
   -- `with_virtual_padding` is true. defaults to false.
   inline = true,
}, function(img)
   if img then
      IMG = img
   end
end)
