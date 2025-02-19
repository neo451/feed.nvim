local M = {}

for k, v in pairs(require("feed.utils.shared")) do
   M[k] = v
end

for k, v in pairs(require("feed.utils.url")) do
   M[k] = v
end

for k, v in pairs(require("feed.utils.treesitter")) do
   M[k] = v
end

for k, v in pairs(require("feed.utils.strings")) do
   M[k] = v
end

return M
