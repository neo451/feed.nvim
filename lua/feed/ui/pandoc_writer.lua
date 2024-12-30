local image_c = 0

local function remove_attr(x)
   if x.attr then
      x.attr = pandoc.Attr()
      return x
   end
end

function Writer(doc, opts)
   local filter = {
      Inline = remove_attr,
      Block = remove_attr,
      Div = function(elem)
         return elem.content
      end,
      Span = function(elem)
         return elem.content
      end,
      Figure = function(elem)
         return elem.content[1]
      end,
      Image = function(elem)
         image_c = image_c + 1
         return ("![Image %d](%s)"):format(image_c, elem.src)
      end,
      CodeBlock = function(cb)
         -- only modify if code block has no attributes
         if cb.attr == pandoc.Attr() then
            local delimited = "```\n" .. cb.text .. "\n```"
            return pandoc.RawBlock("markdown", delimited)
         elseif cb.attr.classes[1] ~= nil then
            local delimited = "```" .. cb.attr.classes[1] .. "\n" .. cb.text .. "\n```"
            return pandoc.RawBlock("markdown", delimited)
         end
      end,
   }
   return pandoc.write(doc:walk(filter), "gfm", opts)
end

Template = pandoc.template.default "gfm"
