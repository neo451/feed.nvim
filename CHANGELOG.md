# Changelog

## [1.13.0](https://github.com/neo451/feed.nvim/compare/v1.12.0...v1.13.0) (2024-12-07)


### Features

* **fetch:** use child process + promise to update feeds ([f34b662](https://github.com/neo451/feed.nvim/commit/f34b6621d7e89dc7477af66c99810f513fb882bd))
* grey out entries just opened ([7a6cccd](https://github.com/neo451/feed.nvim/commit/7a6cccd8860f2b6cba43ce8c0460c2509ce45d9c))
* **ui:** ability to fetch full text html ([1efe1fa](https://github.com/neo451/feed.nvim/commit/1efe1fa6e03ff15ee4fb727fb3b0b08be4ab8067))


### Bug Fixes

* **config:** allow config keys and tag2icon ([9510da2](https://github.com/neo451/feed.nvim/commit/9510da291635e590cecaccd18bfc0a9058c4639b))
* decode html entities at feedparser stage ([c499650](https://github.com/neo451/feed.nvim/commit/c499650d1c3f799b8d51caee34d05754eece2037))
* **health:** only check xml parser ([9510da2](https://github.com/neo451/feed.nvim/commit/9510da291635e590cecaccd18bfc0a9058c4639b))
* **opml:** import logic ([7daddeb](https://github.com/neo451/feed.nvim/commit/7daddeb1f084f0078fe9fe1db52390e488e55773))
* **parser:** handle if xml header missing ([1efe1fa](https://github.com/neo451/feed.nvim/commit/1efe1fa6e03ff15ee4fb727fb3b0b08be4ab8067))
* ui and url handling ([1efe1fa](https://github.com/neo451/feed.nvim/commit/1efe1fa6e03ff15ee4fb727fb3b0b08be4ab8067))
* **ui:** async render of feeds, better for preview and fetch full ([47f4891](https://github.com/neo451/feed.nvim/commit/47f489174cad34900800156e78c252aa4830b845))
* **ui:** better full-text fetch, consitant logic of getting entry ([f34b662](https://github.com/neo451/feed.nvim/commit/f34b6621d7e89dc7477af66c99810f513fb882bd))
* **ui:** manage entry_buf better to handle complex actions ([9510da2](https://github.com/neo451/feed.nvim/commit/9510da291635e590cecaccd18bfc0a9058c4639b))
* **ui:** more robust url viewing ([1efe1fa](https://github.com/neo451/feed.nvim/commit/1efe1fa6e03ff15ee4fb727fb3b0b08be4ab8067))
* **ui:** only try sanitize if feed has ts error ([47f4891](https://github.com/neo451/feed.nvim/commit/47f489174cad34900800156e78c252aa4830b845))
* use buf_delete to fix jumplist, better search preview ([5699c51](https://github.com/neo451/feed.nvim/commit/5699c5153a845fc2fdbfba90c9f3dd7be49752db))
* use NuiLine to render entry ([f68f194](https://github.com/neo451/feed.nvim/commit/f68f194badd69c29c009f1ff6e3dcb9b05fe1650))
* use nuiLine to render index, better opml support ([f68f194](https://github.com/neo451/feed.nvim/commit/f68f194badd69c29c009f1ff6e3dcb9b05fe1650))

## [1.12.0](https://github.com/neo451/feed.nvim/compare/v1.11.0...v1.12.0) (2024-12-02)


### Features

* grey out entries just opened ([7a6cccd](https://github.com/neo451/feed.nvim/commit/7a6cccd8860f2b6cba43ce8c0460c2509ce45d9c))


### Bug Fixes

* **ui.search:** proper logic of choosing search backend! telescope/pick/vim.ui ([04d8931](https://github.com/neo451/feed.nvim/commit/04d89310e293703894e96a3ed80f7986358a1854))
* **ui:** no prune_feed, implement sync_feed in the future ([04d8931](https://github.com/neo451/feed.nvim/commit/04d89310e293703894e96a3ed80f7986358a1854))
* use buf_delete to fix jumplist, better search preview ([5699c51](https://github.com/neo451/feed.nvim/commit/5699c5153a845fc2fdbfba90c9f3dd7be49752db))
* use NuiLine to render entry ([f68f194](https://github.com/neo451/feed.nvim/commit/f68f194badd69c29c009f1ff6e3dcb9b05fe1650))
* use nuiLine to render index, better opml support ([f68f194](https://github.com/neo451/feed.nvim/commit/f68f194badd69c29c009f1ff6e3dcb9b05fe1650))

## [1.11.0](https://github.com/neo451/feed.nvim/compare/v1.10.1...v1.11.0) (2024-11-30)


### Features

* **ui:** nui based key hints, feed-tree-view, split-view ([fd67ea1](https://github.com/neo451/feed.nvim/commit/fd67ea1a4bd9dd28ed9ff2b47bda4e18d3d6cbe1))


### Bug Fixes

* allow user to pass in additional curl params ([9d5b2e9](https://github.com/neo451/feed.nvim/commit/9d5b2e9e44805a8eb442ba8e2e3612b9e0cd6ce5))
* **db:** filter by tag also sort by time ([fd67ea1](https://github.com/neo451/feed.nvim/commit/fd67ea1a4bd9dd28ed9ff2b47bda4e18d3d6cbe1))
* **fetch:** proper logic of handling https status code ([fd67ea1](https://github.com/neo451/feed.nvim/commit/fd67ea1a4bd9dd28ed9ff2b47bda4e18d3d6cbe1))
* handle 404 more elegantly ([9d5b2e9](https://github.com/neo451/feed.nvim/commit/9d5b2e9e44805a8eb442ba8e2e3612b9e0cd6ce5))
* **ui.search:** pick backend for feed_search ([5ede8f1](https://github.com/neo451/feed.nvim/commit/5ede8f188365785c0ad5fcbc8fac656c01a5ae1a))
* **ui.search:** proper logic of choosing search backend! telescope/pick/vim.ui ([04d8931](https://github.com/neo451/feed.nvim/commit/04d89310e293703894e96a3ed80f7986358a1854))
* **ui:** dynamic entry buf creation ([5ede8f1](https://github.com/neo451/feed.nvim/commit/5ede8f188365785c0ad5fcbc8fac656c01a5ae1a))
* **ui:** no prune_feed, implement sync_feed in the future ([04d8931](https://github.com/neo451/feed.nvim/commit/04d89310e293703894e96a3ed80f7986358a1854))

## [1.10.1](https://github.com/neo451/feed.nvim/compare/v1.10.0...v1.10.1) (2024-11-27)


### Bug Fixes

* **fetch:** rsshub links as first class citizen ([8af8a22](https://github.com/neo451/feed.nvim/commit/8af8a221cb4e69264fa4e72e80ce25e7c82b8135))
* **parser:** handle rdf in rss090&rss10 ([1ad3877](https://github.com/neo451/feed.nvim/commit/1ad387771f124980808dfe8325e6b7baef5517a4))
* **parser:** handle rss1.0's rdf tag ([3ee96b1](https://github.com/neo451/feed.nvim/commit/3ee96b1a6cdf0e2e10914db4200dffa0869c8f27))

## [1.10.0](https://github.com/neo451/feed.nvim/compare/v1.9.3...v1.10.0) (2024-11-26)


### Features

* **parser.fetch:** support links like rsshub://{route}, DIY power! ([2a052f3](https://github.com/neo451/feed.nvim/commit/2a052f3186e0360d7f695081e74dd747707b5dc4))


### Bug Fixes

* **fetch:** use -D flag to avoid proxy header, handles more feeds! ([656aa4f](https://github.com/neo451/feed.nvim/commit/656aa4f0e1fbd6144cb9231f4e71f1b6605ecb68))
* **render:** better health with version check for curl and pandoc ([2a052f3](https://github.com/neo451/feed.nvim/commit/2a052f3186e0360d7f695081e74dd747707b5dc4))
* **telescope:** open entry on enter ([656aa4f](https://github.com/neo451/feed.nvim/commit/656aa4f0e1fbd6144cb9231f4e71f1b6605ecb68))

## [1.9.3](https://github.com/neo451/feed.nvim/compare/v1.9.2...v1.9.3) (2024-11-23)


### Bug Fixes

* **commands:** make tag/untag dot repeatable and undoable ([1cd5ccb](https://github.com/neo451/feed.nvim/commit/1cd5ccbddedb27eb642999527d7a1381eed34d43))
* format ([b74568a](https://github.com/neo451/feed.nvim/commit/b74568a5d408a2ceec63d8731e31d0b17fd04a32))
* **health:** check for nui.nvim ([4cf7a18](https://github.com/neo451/feed.nvim/commit/4cf7a18209680b1a3e43908183f37ed88734d59d))
* **render:** handle colorscheme change normal ([1cd5ccb](https://github.com/neo451/feed.nvim/commit/1cd5ccbddedb27eb642999527d7a1381eed34d43))

## [1.9.2](https://github.com/neo451/feed.nvim/compare/v1.9.1...v1.9.2) (2024-11-22)


### Bug Fixes

* **date:** handle asctime and try each format possible when parsing ([7af1de7](https://github.com/neo451/feed.nvim/commit/7af1de738f6d3f06b02514f4f76f64ee001800c0))
* **fetch:** recursive impl of fetching ([7af1de7](https://github.com/neo451/feed.nvim/commit/7af1de738f6d3f06b02514f4f76f64ee001800c0))
* **log:** add vlog.nvim for logging ([21e7f6e](https://github.com/neo451/feed.nvim/commit/21e7f6e86438ef948edaed5f6bedc6496c7885fa))
* **parser.fetch:** handle redirects ([21e7f6e](https://github.com/neo451/feed.nvim/commit/21e7f6e86438ef948edaed5f6bedc6496c7885fa))
* **parser.opml:** handle nested opml ([21e7f6e](https://github.com/neo451/feed.nvim/commit/21e7f6e86438ef948edaed5f6bedc6496c7885fa))
* **progress:** show name and success/fail in progress ([21e7f6e](https://github.com/neo451/feed.nvim/commit/21e7f6e86438ef948edaed5f6bedc6496c7885fa))
* **progress:** show used time, progress class ([7af1de7](https://github.com/neo451/feed.nvim/commit/7af1de738f6d3f06b02514f4f76f64ee001800c0))
* **telescope:** render upper bug in telescope search ([75ce6e7](https://github.com/neo451/feed.nvim/commit/75ce6e7bef3b584a23393e8b083359847f9a9af8))

## [1.9.1](https://github.com/neo451/feed.nvim/compare/v1.9.0...v1.9.1) (2024-11-18)


### Bug Fixes

* command line short hand to search with "Feed &lt;query&gt;" ([067b576](https://github.com/neo451/feed.nvim/commit/067b576da2367801d601761593a814018147b9da))
* correct update feed info behavior ([067b576](https://github.com/neo451/feed.nvim/commit/067b576da2367801d601761593a814018147b9da))
* **db:** add entry with a list of tags ([d31df0a](https://github.com/neo451/feed.nvim/commit/d31df0aab00f3abc588ee911669a8d25f3e86f2f))
* **parser:** rss feed dup link ([d31df0a](https://github.com/neo451/feed.nvim/commit/d31df0aab00f3abc588ee911669a8d25f3e86f2f))
* replace entity in rendering! ([9f2c881](https://github.com/neo451/feed.nvim/commit/9f2c88189ce917a4069da3652ac64289713f0683))
* **telscope:** preview html as markdown (in progress) ([d31df0a](https://github.com/neo451/feed.nvim/commit/d31df0aab00f3abc588ee911669a8d25f3e86f2f))
* xhtml sanitize ([6806d35](https://github.com/neo451/feed.nvim/commit/6806d355ee32e69dad8776f97f7358c9ed51adb8))

## [1.9.0](https://github.com/neo451/feed.nvim/compare/v1.8.4...v1.9.0) (2024-11-16)


### Features

* db + telescope search improvements ([43f7eb7](https://github.com/neo451/feed.nvim/commit/43f7eb72f2076e60588815be152816d7b2ca9ffa))
* feedparser overhaul, inlcude test suite and http features! ([43f7eb7](https://github.com/neo451/feed.nvim/commit/43f7eb72f2076e60588815be152816d7b2ca9ffa))


### Bug Fixes

* better tags, use the new converter ([452983d](https://github.com/neo451/feed.nvim/commit/452983d4910bba2c2fb51a0c933102c175da540b))
* lazy load db to speed up startuptime, more native telescope ([4113c15](https://github.com/neo451/feed.nvim/commit/4113c157bbccb67056e6c31bbde19954dc135704))
* save html to local and only convert when render ([05a43d7](https://github.com/neo451/feed.nvim/commit/05a43d7cc7f9fe948eab7f1aa07483f5243c5fe7))

## [1.8.4](https://github.com/neo451/feed.nvim/compare/v1.8.3...v1.8.4) (2024-11-11)


### Bug Fixes

* one db instance, improve loging, mini.notify backend ([ce848be](https://github.com/neo451/feed.nvim/commit/ce848be4abeba95ecf20c92ea988d32e02a57bb2))

## [1.8.3](https://github.com/neo451/feed.nvim/compare/v1.8.2...v1.8.3) (2024-11-10)


### Bug Fixes

* winbar improvement, build.lua, plugin/ ([651b70a](https://github.com/neo451/feed.nvim/commit/651b70a64eff99392bfb6f9ba04c38c75bfd0c98))

## [1.8.2](https://github.com/neo451/feed.nvim/compare/v1.8.1...v1.8.2) (2024-11-09)


### Bug Fixes

* fixed telescope implementation ([376cda7](https://github.com/neo451/feed.nvim/commit/376cda71da1645be41427773be5f8a2db5afe86e))
* use nui.nvim to hanlde rendering, multi-width works! ([376cda7](https://github.com/neo451/feed.nvim/commit/376cda71da1645be41427773be5f8a2db5afe86e))

## [1.8.1](https://github.com/neo451/feed.nvim/compare/v1.8.0...v1.8.1) (2024-11-08)


### Performance Improvements

* take lastBuildDate into account for better update fix: bunch of date parsing bugs fix: implement prune/remove feeds command ([ff4471a](https://github.com/neo451/feed.nvim/commit/ff4471ae63eccb3a6ca641c3453d65f779e42771))

## [1.8.0](https://github.com/neo451/feed.nvim/compare/v1.7.2...v1.8.0) (2024-11-08)


### Features

* a more stable model of fetching ([0fbf290](https://github.com/neo451/feed.nvim/commit/0fbf29049762442e8e853e5a06e59b39e2dd6bdd))
* total rewrite of db to get arround lua constant limit ([0fbf290](https://github.com/neo451/feed.nvim/commit/0fbf29049762442e8e853e5a06e59b39e2dd6bdd))


### Bug Fixes

* fixed missing on_attach in default config ([5effb2d](https://github.com/neo451/feed.nvim/commit/5effb2d564eaf785d34e914f66d419894e0bf904))

## [1.7.2](https://github.com/neo451/feed.nvim/compare/v1.7.1...v1.7.2) (2024-11-07)


### Bug Fixes

* feed grep now only searches the content of the entry ([f3ab1c6](https://github.com/neo451/feed.nvim/commit/f3ab1c6f359b4061ee0fdfbe529102ccde6bccaa))
* sub command completion respects context now ([f3ab1c6](https://github.com/neo451/feed.nvim/commit/f3ab1c6f359b4061ee0fdfbe529102ccde6bccaa))

## [1.7.1](https://github.com/neo451/feed.nvim/compare/v1.7.0...v1.7.1) (2024-11-06)


### Bug Fixes

* complete search grammar ([82ddd8b](https://github.com/neo451/feed.nvim/commit/82ddd8b00678c7a31a2257de8f36991657d95e9d))
* default keymaps ([82ddd8b](https://github.com/neo451/feed.nvim/commit/82ddd8b00678c7a31a2257de8f36991657d95e9d))

## [1.7.0](https://github.com/neo451/feed.nvim/compare/v1.6.3...v1.7.0) (2024-11-06)


### Features

* support for multiple notify backends ([1240969](https://github.com/neo451/feed.nvim/commit/1240969350b2311b5b2c497a788fed8eecd7abee))


### Bug Fixes

* vim.hl/highlight ([21f462a](https://github.com/neo451/feed.nvim/commit/21f462a5f9bc3a6f1058f9cae74c0c884988ce73))
* xml module not rely on treedoc, cleaner impl ([6c704fc](https://github.com/neo451/feed.nvim/commit/6c704fc36a5b94a2abc60c2e9e4f7a1ebca326f5))

## [1.6.3](https://github.com/neo451/feed.nvim/compare/v1.6.2...v1.6.3) (2024-11-02)


### Bug Fixes

* bunch of small fixes, better conventions, less garbage ([c984750](https://github.com/neo451/feed.nvim/commit/c984750308903b4e3bd9343f2fe2baa3632d3a6c))
* fix log file missing ([3a8c8e1](https://github.com/neo451/feed.nvim/commit/3a8c8e1ff37be2e32b6a7c4b728038fce8e1f1f0))
* format to please stylua.. ([ca52700](https://github.com/neo451/feed.nvim/commit/ca5270089ddb98aaac9dde0b4175e7c1b4f588c3))
* put url.lua back for better install in lazy ([3a8c8e1](https://github.com/neo451/feed.nvim/commit/3a8c8e1ff37be2e32b6a7c4b728038fce8e1f1f0))
* use feed.url in utils... ([f1e0ad5](https://github.com/neo451/feed.nvim/commit/f1e0ad527a1eb2b72570b06ae312c286e526fc4f))
* utf8.lua ([6b9cf15](https://github.com/neo451/feed.nvim/commit/6b9cf1580727a42f2f9980f77076d874851dd852))

## [1.6.2](https://github.com/neo451/feed.nvim/compare/v1.6.1...v1.6.2) (2024-10-26)


### Bug Fixes

* fetch should only see 404 as invalid ([f278276](https://github.com/neo451/feed.nvim/commit/f278276316ab33a7cb6763df3eed2d160e9a9e08))
* fix lualine error, fix test file missing ([2b73168](https://github.com/neo451/feed.nvim/commit/2b731684d91814bdae18fe4e4403e95baa85941f))

## [1.6.1](https://github.com/neo451/feed.nvim/compare/v1.6.0...v1.6.1) (2024-10-25)


### Bug Fixes

* batter date api ([74fa69d](https://github.com/neo451/feed.nvim/commit/74fa69df6bf63a4c789193e484bd41f657864616))
* handle podcast links ([74fa69d](https://github.com/neo451/feed.nvim/commit/74fa69df6bf63a4c789193e484bd41f657864616))
* remove some unnecessary commands, prepare for more extensible api ([74fa69d](https://github.com/neo451/feed.nvim/commit/74fa69df6bf63a4c789193e484bd41f657864616))
* use fidget in single feed update ([74fa69d](https://github.com/neo451/feed.nvim/commit/74fa69df6bf63a4c789193e484bd41f657864616))

## [1.6.0](https://github.com/neo451/feed.nvim/compare/v1.5.1...v1.6.0) (2024-10-23)


### Features

* fully functional feedparser, reliable fetching, many ux improvements ([cd06253](https://github.com/neo451/feed.nvim/commit/cd06253f15d804b73091a0448b62d1946fb2c54b))

## [1.5.1](https://github.com/neo451/feed.nvim/compare/v1.5.0...v1.5.1) (2024-10-19)


### Bug Fixes

* imporve opml handling: dups, incomplete.. ([f7c837e](https://github.com/neo451/feed.nvim/commit/f7c837e2c41c86eb01fb1b8d951986a0d89632b4))
* move xml parsing here ([f7c837e](https://github.com/neo451/feed.nvim/commit/f7c837e2c41c86eb01fb1b8d951986a0d89632b4))
* remove the copied url module, use luarock power! ([f7c837e](https://github.com/neo451/feed.nvim/commit/f7c837e2c41c86eb01fb1b8d951986a0d89632b4))
* sort search results by time ([f7c837e](https://github.com/neo451/feed.nvim/commit/f7c837e2c41c86eb01fb1b8d951986a0d89632b4))

## [1.5.0](https://github.com/neo451/feed.nvim/compare/v1.4.2...v1.5.0) (2024-10-18)


### Features

* custom telescope livegrep in all feeds ([148d3b3](https://github.com/neo451/feed.nvim/commit/148d3b320246f6e1530e79ac27189d53442265b2))
* implement search, faster db lookup, more opml support ([7d9eeec](https://github.com/neo451/feed.nvim/commit/7d9eeec1952a6eb5bece4121142e5342267f17f4))


### Bug Fixes

* fix link display problem by removing link and use urlview ([148d3b3](https://github.com/neo451/feed.nvim/commit/148d3b320246f6e1530e79ac27189d53442265b2))
* handle images in urlview ([885083c](https://github.com/neo451/feed.nvim/commit/885083c54821d3df620c03a9be7166838be35c54))
* internal improvements: use autocmds, better render api ([148d3b3](https://github.com/neo451/feed.nvim/commit/148d3b320246f6e1530e79ac27189d53442265b2))

## [1.4.2](https://github.com/neo451/feed.nvim/compare/v1.4.1...v1.4.2) (2024-10-12)


### Bug Fixes

* imporved path handling, used in std data dir ([d6341d2](https://github.com/neo451/feed.nvim/commit/d6341d2803c620ed004ff5567765aa5d326e658a))

## [1.4.1](https://github.com/neo451/feed.nvim/compare/v1.4.0...v1.4.1) (2024-10-12)


### Bug Fixes

* proper integration with vim.ui.select/input for taging and ([e829c84](https://github.com/neo451/feed.nvim/commit/e829c8473bfd18a9ffb9c54ec19828dc5a5ac270))

## [1.4.0](https://github.com/neo451/feed.nvim/compare/v1.3.0...v1.4.0) (2024-10-11)


### Features

* ts/telescope powered link selector ([8c07a42](https://github.com/neo451/feed.nvim/commit/8c07a423410df357d8ef47a9d966d3f6f3d1da5c))

## [1.3.0](https://github.com/neo451/feed.nvim/compare/v1.2.4...v1.3.0) (2024-10-11)


### Features

* resturcture keymaps in config to allow function binding ([36d19a4](https://github.com/neo451/feed.nvim/commit/36d19a40f3bc97fd6cc4b8a6d921c2c6102cd59b))
* urlview integration ([36d19a4](https://github.com/neo451/feed.nvim/commit/36d19a40f3bc97fd6cc4b8a6d921c2c6102cd59b))


### Bug Fixes

* export_opml ([36d19a4](https://github.com/neo451/feed.nvim/commit/36d19a40f3bc97fd6cc4b8a6d921c2c6102cd59b))

## [1.2.4](https://github.com/neo451/feed.nvim/compare/v1.2.3...v1.2.4) (2024-10-11)


### Bug Fixes

* add back a setup function for consistancy ([345f849](https://github.com/neo451/feed.nvim/commit/345f849e83ba5c7395082a90989713044b36f031))
* date parsing for some atom feeds ([345f849](https://github.com/neo451/feed.nvim/commit/345f849e83ba5c7395082a90989713044b36f031))
* wsl specific open in browser ([345f849](https://github.com/neo451/feed.nvim/commit/345f849e83ba5c7395082a90989713044b36f031))

## [1.2.3](https://github.com/neo451/feed.nvim/compare/v1.2.2...v1.2.3) (2024-10-10)


### Bug Fixes

* correct logic of managing buffers, quitting, zenmode, and color ([2b641ef](https://github.com/neo451/feed.nvim/commit/2b641efde4f59cb3e00b5d27e14fedd0b7bfcfdc))

## [1.2.2](https://github.com/neo451/feed.nvim/compare/v1.2.1...v1.2.2) (2024-10-10)


### Bug Fixes

* clean commands impl ([879be2e](https://github.com/neo451/feed.nvim/commit/879be2e1dfd188ed071f5a122813d9d64f6d7596))
* set filetype to markdown ([879be2e](https://github.com/neo451/feed.nvim/commit/879be2e1dfd188ed071f5a122813d9d64f6d7596))
* telescope extension fix db ([879be2e](https://github.com/neo451/feed.nvim/commit/879be2e1dfd188ed071f5a122813d9d64f6d7596))

## [1.2.1](https://github.com/neo451/feed.nvim/compare/v1.2.0...v1.2.1) (2024-10-10)


### Bug Fixes

* api imporvement, better calling conventions ([07ac8cb](https://github.com/neo451/feed.nvim/commit/07ac8cb801ac7017a94dd34ded0835475849ccf5))
* more proper lazy calls ([07ac8cb](https://github.com/neo451/feed.nvim/commit/07ac8cb801ac7017a94dd34ded0835475849ccf5))
* pcall parsing and error handling on fecth ([07ac8cb](https://github.com/neo451/feed.nvim/commit/07ac8cb801ac7017a94dd34ded0835475849ccf5))
* render logic cleanup, refresh command ([07ac8cb](https://github.com/neo451/feed.nvim/commit/07ac8cb801ac7017a94dd34ded0835475849ccf5))

## [1.2.0](https://github.com/neo451/feed.nvim/compare/v1.1.0...v1.2.0) (2024-10-08)


### Features

* implement checkhealth ([5502c0f](https://github.com/neo451/feed.nvim/commit/5502c0f961a6e8c9c02c0d7c8509fefb56e8b9c9))


### Bug Fixes

* add new feed into opml without duplicates by xmlUrl as unique identifier ([f5fdb80](https://github.com/neo451/feed.nvim/commit/f5fdb80e602e27a64d332bb35d411ceed0812e48))
* proper state management in render ([315b2e6](https://github.com/neo451/feed.nvim/commit/315b2e6d6677dd18e4b6885d26435b06fc3e3d90))

## [1.1.0](https://github.com/neo451/feed.nvim/compare/v1.0.1...v1.1.0) (2024-10-06)


### Features

* telescope integration with highted buffer and line wrap ([87afce3](https://github.com/neo451/feed.nvim/commit/87afce33982e532d14931a5c5feecdf97ee9d7d2))


### Bug Fixes

* remove a few test files for treedoc ([87afce3](https://github.com/neo451/feed.nvim/commit/87afce33982e532d14931a5c5feecdf97ee9d7d2))

## [1.0.1](https://github.com/neo451/feed.nvim/compare/v1.0.0...v1.0.1) (2024-10-06)


### Bug Fixes

* proper handling of atom links ([3fef37b](https://github.com/neo451/feed.nvim/commit/3fef37b6615aa47a418596a99c029733242ab99a))

## 1.0.0 (2024-10-05)


### Features

* intial support for atom, unified opml file in nvim/feed folder ([4c2e526](https://github.com/neo451/feed.nvim/commit/4c2e526964899f99d8d2568da85921edb401b96b))
* module for opml centric feed managing ([9e1c267](https://github.com/neo451/feed.nvim/commit/9e1c2676c12a425d6130720bf016fb0d560eb2b2))
* save entry as markdown files instead of raw text ([79b2d04](https://github.com/neo451/feed.nvim/commit/79b2d04d03cc64f743a81fa4f7d3c5adbe78a35a))
* writer for converting to markdown ([92cc6e9](https://github.com/neo451/feed.nvim/commit/92cc6e960bea02057a3405797aa2af26826d37eb))


### Bug Fixes

* clean render logic, idea for a content validater... ([4a58ec7](https://github.com/neo451/feed.nvim/commit/4a58ec7718779623c2060b69961692e502df74b9))
* proper lazy load in whole plugin, fixed bug in intial db mkdir ([11ee5b0](https://github.com/neo451/feed.nvim/commit/11ee5b09ff546e63f1ceb25a187ffee794547046))
