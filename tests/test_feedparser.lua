local M = require("feed.parser")
local eq = MiniTest.expect.equality

local h = dofile("tests/helpers.lua")
local readfile = h.readfile
local is_url = h.is_url

local is_string = function(v)
   eq("string", type(v))
end

local is_table = function(v)
   eq("table", type(v))
end

local is_number = function(v)
   eq("number", type(v))
end

local check_feed = function(ast)
   is_string(ast.title)
   is_url(ast.link)
   is_table(ast.entries)
   for _, v in ipairs(ast.entries) do
      if not v.link then
         vim.print(ast)
      end
      is_url(v.link)
      is_number(v.time)
      is_string(v.title)
      is_string(v.feed)
   end
end

local check_feed_minimal = function(ast)
   -- assert.is_string(ast.title, "no title")
   is_string(ast.version)
   is_table(ast.entries)
end

local dump_date = function(time)
   return os.date("%Y-%m-%d", time)
end

local T = MiniTest.new_set()

T["rss"] = MiniTest.new_set({
   parametrize = {
      {
         "rss091.xml",
         { version = "rss091" },
      },
      {
         "rss092.xml",
         { version = "rss092" },
      },
      {
         "rss20.xml",
         { version = "rss20" },
      },
      {
         "rdf.xml",
         { version = "rss10" },
      },
      {
         "rdf/rss090_item_title.xml",
         { version = "rss090" },
      },
      {
         "rss_ns.xml",
         {
            version = "rss20",
            desc = "For documentation only",
            [1] = {
               time = "2002-09-04",
               author = "Mark Pilgrim (mark@example.org)",
            },
         },
      },
      {
         "rss_pod.xml",
         {
            version = "rss20",
            [1] = {
               author = "Kris Jenkins",
               link = "https://redirect.zencastr.com/r/episode/6723a17775cd3f17270161ed/size/105689812/audio-files/619e48a9649c44004c5a44e8/5af6e1e2-b4d9-4e98-8301-4b18f77ca296.mp3",
            },
         },
      },
      { "rss_atom.xml", { version = "rss20" } },
   },
})

T["json"] = MiniTest.new_set({
   parametrize = {
      { "json1", "json1" },
   },
})

T["atom"] = MiniTest.new_set({
   parametrize = {
      { "atom03.xml", { version = "atom03" } },
      { "atom10.xml", { version = "atom10" } },
      { "atom_html_content.xml", { version = "atom10" } },
      -- { "reddit.xml", { version = "atom10" } },
   },
})

T["json"] = MiniTest.new_set({
   parametrize = {
      { "json1.json", { version = "json1" } },
      { "json2.json", { version = "json1" } },
   },
})

T["url resolover"] = MiniTest.new_set({
   parametrize = {
      {
         "url_atom.xml",
         {
            link = "http://placehoder.feed/index.html",
            [1] = {
               link = "http://example.org/archives/000001.html",
            },
         },
      },

      {
         "url_atom2.xml",
         {
            link = "http://example.org/index.html",
            [1] = {
               link = "http://example.org/archives/000001.html",
            },
         },
      },

      {
         "url_rss.xml",
         {
            link = "http://example.org",
            [1] = {
               link = "http://example.org/archives/000001.html",
            },
         },
      },
   },
})

-- https://sample-feeds.rowanmanning.com/
T["sample-feeds.com"] = MiniTest.new_set({
   parametrize = {
      {
         "sample/apple_podcast.xml",
         {
            link = "https://www.apple.com/itunes/podcasts/",
            author = "The Sunset Explorers",
            --       desc = [[Love to get outdoors and discover nature&apos;s treasures? Hiking Treks is the
            -- show for you. We review hikes and excursions, review outdoor gear and interview
            -- a variety of naturalists and adventurers. Look for new episodes each week.]],
            [1] = {
               link = "http://example.com/podcasts/everything/AllAboutEverythingEpisode4.mp3",
            },
         },
      },
      {
         "sample/atom.xml",
         {
            title = "Example Feed",
            link = "http://example.org/",
            author = "John Doe",
            [1] = {
               link = "http://example.org/2003/12/13/atom03",
               title = "Atom-Powered Robots Run Amok",
               content = "Some text.",
            },
         },
      },
      {
         "sample/feedforall.xml",
         {
            title = "FeedForAll Sample Feed",
            desc = "RSS is a fascinating technology. The uses for RSS are expanding daily. Take a closer look at how various industries are using the benefits of RSS in their businesses.",
            link = "http://www.feedforall.com/industry-solutions.htm",
            [1] = {
               title = "RSS Solutions for Restaurants",
               link = "http://www.feedforall.com/restaurant.htm",
            },
         },
      },
      --       {
      --          "sample/youtube.xml",
      --          {
      --             title = "Critical Role",
      --             author = "Critical Role",
      --             link = "https://www.youtube.com/channel/UCpXBGqwsBkpvcYjsJBQ7LEQ",
      --             [1] = {
      --                title = "The Aurora Grows | Critical Role | Campaign 3, Episode 49",
      --                linke = "https://www.youtube.com/watch?v=0_NVdZp8haA",
      --                content = [[
      -- This episode is sponsored by Thorum. Enjoy 20% off your Thorum ring with code Criticalrole at https://Thorum.com
      --
      -- Bells Hells travel the aurora-filled skies of the Hellcatch Valley, concocting plans and gathering allies as the days tick down to the apogee solstice...
      --
      -- CAPTION STATUS: CAPTIONED BY OUR EDITORS. The closed captions featured on this episode have been curated by our CR editors. For more information on the captioning process, check out: https://critrole.com/cr-transcript-closed-captions-update
      --
      -- Due to the improv nature of Critical Role and other RPG content on our channels, some themes and situations that occur in-game may be difficult for some to handle. If certain episodes or scenes become uncomfortable, we strongly suggest taking a break or skipping that particular episode.
      -- Your health and well-being is important to us and Psycom has a great list of international mental health resources, in case it’s useful: http://bit.ly/PsycomResources
      --
      -- Watch Critical Role Campaign 3 live Thursdays at 7pm PT on https://twitch.tv/criticalrole and https://youtube.com/criticalrole. To join our live and moderated community chat, watch the broadcast on our Twitch channel.
      --
      -- Twitch subscribers gain instant access to VODs of our shows like Critical Role, Exandria Unlimited, and 4-Sided Dive. But don't worry: Twitch broadcasts will be uploaded to YouTube about 36 hours after airing live, with audio-only podcast versions of select shows on Spotify, Apple Podcasts &amp; Google Podcasts following a week after the initial air date. Twitch subscribers also gain access to our official custom emote set and subscriber badges and the ability to post links in Twitch chat!
      --
      -- &quot;It's Thursday Night (Critical Role Theme Song)&quot; by Peter Habib and Sam Riegel
      -- Original Music by Omar Fadel and Hexany Audio
      -- &quot;Welcome to Marquet&quot; Art Theme by Colm McGuinness
      -- Additional Music by Universal Production Music, Epidemic Sounds, and 5 Alarm
      -- Character Art by Hannah Friederichs
      --
      --
      -- Follow us!
      -- Website: https://www.critrole.com
      -- Newsletter: https://critrole.com/newsletter
      -- Facebook: https://www.facebook.com/criticalrole
      -- Twitter: https://twitter.com/criticalrole
      -- Instagram: https://instagram.com/critical_role
      -- Twitch: https://www.twitch.tv/criticalrole
      --
      -- Shops:
      -- US: https://shop.critrole.com
      -- UK: https://shop.critrole.co.uk
      -- EU: https://shop.critrole.eu
      -- AU: https://shop.critrole.com.au
      -- CA: https://canada.critrole.com
      --
      -- Follow Critical Role Foundation!
      -- Learn More &amp; Donate: https://criticalrolefoundation.org
      -- Twitter: https://twitter.com/CriticalRoleFDN
      -- Facebook: https://facebook.com/CriticalRoleFDN
      --
      -- Want games? Follow Darrington Press
      -- Newsletter: https://darringtonpress.com/newsletter
      -- Twitter: https://twitter.com/DarringtonPress
      -- Facebook: https://www.facebook.com/darringtonpress
      --
      -- Check out our animated series!
      -- The Legend of Vox Machina is available now on Prime Video! Watch: https://amzn.to/3o4nBS5
      -- Listen to The Legend of Vox Machina's official soundtrack here: https://lnk.to/voxmachina
      --
      -- #CriticalRole #BellsHells #DungeonsAndDragons
      --                ]],
      --             },
      --          },
      --       },
   },
})

local function check(filename, checks, debug)
   local f = M.parse(readfile(filename), "http://placehoder.feed")
   assert(f)
   if debug then
      vim.print(f)
   end
   for k, v in pairs(checks) do
      if type(v) == "table" then
         for kk, vv in pairs(v) do
            local res = f.entries[k][kk]
            if kk == "time" then
               eq(vv, dump_date(res)) -- TODO: move date_eq here
            else
               eq(vv, res)
            end
         end
      else
         eq(v, f[k])
      end
   end
   check_feed(f)
end

T["rss"]["works"] = check
T["atom"]["works"] = check
T["json"]["works"] = check
T["url resolover"]["works"] = check
T["sample-feeds.com"]["works"] = check
--
--- TODO: parse the condition in the feed parser test suite, into a check table, and wemo check!!

T["feedparser test suite"] = MiniTest.new_set({
   parametrize = {
      { "/data/atom" },
      { "/data/rss" },
      { "/data/sanitize" },
      { "/data/xml" },
      { "/data/rdf" },
      -- { "/data/itunes" },
   },
})

local function check_suite(dir)
   for f in vim.fs.dir(dir) do
      local str = readfile(f, dir)
      check_feed_minimal(M.parse(str, ""))
   end
end

T["feedparser test suite"]["works"] = check_suite

-- describe("reject encodings that neovim can not handle", function()
--    local d = M.parse(readfile("encoding.xml", "./data/"), "")
--    eq("gb2312", d.encoding)
-- end)
--
return T
