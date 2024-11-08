# Changelog

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
