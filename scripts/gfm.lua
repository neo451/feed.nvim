local function remove_attr(x)
   if x.attr then
      x.attr = pandoc.Attr()
      return x
   end
end

function Writer(doc, opts)
   local ref_counter = 0
   local refs = {}

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
      Link = function(elem)
         ref_counter = ref_counter + 1
         refs[ref_counter] = elem.target

         -- Checks if extension is an image and treats it as such if it is
         local extension = elem.target:match("^.+%.(.+)$")
         if extension == "jpg" or extension == "jpeg" or extension == "png" or extension == "webm" then
            return pandoc.RawInline("markdown", ("![Image %d](%s)"):format(ref_counter, elem.target)) -- added for image rendering
         end

         local text = pandoc.utils.stringify(elem.content)
         return pandoc.RawInline("markdown", "[" .. text .. "][^" .. ref_counter .. "]")
      end,
      Image = function(elem)
         if elem.src:find("data:image/svg%+xml") then
            return pandoc.RawInline("markdown", "![svg](" .. elem.src .. ")")
         end
         ref_counter = ref_counter + 1
         refs[ref_counter] = elem.src
         return pandoc.RawInline("markdown", ("![Image %d](%s)"):format(ref_counter, elem.src)) -- for now for image rendering
      end,
      CodeBlock = function(cb)
         if cb.attr == pandoc.Attr() then
            local delimited = "```\n" .. cb.text .. "\n```"
            return pandoc.RawBlock("markdown", delimited)
         elseif cb.attr.classes[1] ~= nil then
            local delimited = "```" .. cb.attr.classes[1] .. "\n" .. cb.text .. "\n```"
            return pandoc.RawBlock("markdown", delimited)
         end
      end,
   }

   local new_doc = doc:walk(filter)

   -- Add collected references under "## Links"
   local links_blocks = {}
   if ref_counter > 0 then
      table.insert(links_blocks, pandoc.Strong("Links"))
      for i = 1, ref_counter do
         table.insert(links_blocks, pandoc.Para(pandoc.Str(("[^%d] <%s>"):format(i, refs[i]))))
      end
      new_doc.blocks = new_doc.blocks .. links_blocks
   end

   return pandoc.write(new_doc, "gfm", opts)
end

Template = pandoc.template.default("gfm")
