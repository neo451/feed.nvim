# Changelog

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
