# Changelog

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
