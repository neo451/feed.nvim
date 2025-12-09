local function remove_attr(x)
   if x.attr then
      x.attr = pandoc.Attr()
      return x
   end
end

local COMMON_LANGS = {
   bash = "bash",
   sh = "bash",
   zsh = "bash",
   python = "python",
   py = "python",
   javascript = "javascript",
   js = "javascript",
   typescript = "typescript",
   ts = "typescript",
   lua = "lua",
   c = "c",
   cpp = "cpp",
   ["c++"] = "cpp",
   java = "java",
   go = "go",
   rust = "rust",
   rs = "rust",
   html = "html",
   xml = "xml",
   json = "json",
   yaml = "yaml",
   toml = "toml",
   sql = "sql",
}

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
         -- helper: normalize a candidate language name

         local function normalize(c)
            if not c then
               return nil
            end
            c = c:lower()

            -- match language-foo
            local m = c:match("^language%-(.+)")
            if m then
               c = m
            end

            -- match hljs language-foo
            local h = c:match("^hljs%-(.+)")
            if h then
               c = h
            end

            -- strip unsafe chars
            c = c:gsub("[^%w%+%-]", "")

            -- direct match
            if COMMON_LANGS[c] then
               return COMMON_LANGS[c]
            end

            return nil
         end

         local lang = nil

         -- 1) check classes if present (most common)
         if cb.attr and cb.attr.classes then
            for _, c in ipairs(cb.attr.classes) do
               local candidate = normalize(c)
               if candidate then
                  lang = candidate
                  break
               end
            end
         end

         -- 2) check key/value attributes like lang= or language=
         if not lang and cb.attr and cb.attr.attributes then
            -- cb.attr.attributes is a table of key -> value in many pandoc lua versions
            for k, v in pairs(cb.attr.attributes) do
               if k:lower() == "lang" or k:lower() == "language" then
                  lang = v
                  break
               end
            end
         end

         -- 3) fallback: use first class if it exists (less strict)
         if not lang and cb.attr and cb.attr.classes and cb.attr.classes[1] then
            lang = cb.attr.classes[1]
         end
         -- Build fenced codeblock markdown
         if lang and lang ~= "" then
            local delimited = "```" .. lang .. "\n" .. cb.text .. "\n```"
            return pandoc.RawBlock("markdown", delimited)
         else
            local delimited = "```\n" .. cb.text .. "\n```"
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
