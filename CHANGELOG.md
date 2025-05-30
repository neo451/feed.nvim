# Changelog

## [2.18.1](https://github.com/neo451/feed.nvim/compare/v2.18.0...v2.18.1) (2025-05-30)


### Bug Fixes

* **parser:** handles rdf feeds ([82aa402](https://github.com/neo451/feed.nvim/commit/82aa402fe689e3e4e7da7a5b6fb2598e807b79ab))

## [2.18.0](https://github.com/neo451/feed.nvim/compare/v2.17.0...v2.18.0) (2025-05-24)


### Features

* bump minimal version to 0.11 ([c6c035e](https://github.com/neo451/feed.nvim/commit/c6c035e46b43561f3364a3cb4c632e304057e874))
* bump minimal version to 0.11 ([97f9d3c](https://github.com/neo451/feed.nvim/commit/97f9d3c13fcfcc26f94aa86624f81232e35ad584))
* make links correct markdown syntax with [^1] and &lt;auto_link&gt; ([b3b875b](https://github.com/neo451/feed.nvim/commit/b3b875b7f9b9d34c0df93b7be9b24a11503ed296))
* make links correct markdown syntax with [^1] and &lt;auto_link&gt; ([1fe6e43](https://github.com/neo451/feed.nvim/commit/1fe6e432f4d678b40b18b8488c7747c89ecdb831))


### Bug Fixes

* add user-agent info for reddit feeds ([97f9d3c](https://github.com/neo451/feed.nvim/commit/97f9d3c13fcfcc26f94aa86624f81232e35ad584))
* current luarocks version ([3df36ce](https://github.com/neo451/feed.nvim/commit/3df36ce04d6adfcb881c896707b603431bdeb04b))

## [2.17.0](https://github.com/neo451/feed.nvim/compare/v2.16.0...v2.17.0) (2025-03-20)


### Features

* add support for customizing link format ([a9d6a73](https://github.com/neo451/feed.nvim/commit/a9d6a73841268569c327ccd5d6bec88386a1f4ea))
* add support for sub-reddit ([a9d6a73](https://github.com/neo451/feed.nvim/commit/a9d6a73841268569c327ccd5d6bec88386a1f4ea))


### Bug Fixes

* whatever key in config is the internal ref ([079d337](https://github.com/neo451/feed.nvim/commit/079d337d6d424710ac8543a1818cb9863210c752))

## [2.16.0](https://github.com/neo451/feed.nvim/compare/v2.15.0...v2.16.0) (2025-03-16)


### Features

* **bar:** allow specify bar components ([9aab404](https://github.com/neo451/feed.nvim/commit/9aab404e76ea479f6fec4a152c29d92fc27a4036))
* **bar:** use existing lualine highlight for winbar ([9aab404](https://github.com/neo451/feed.nvim/commit/9aab404e76ea479f6fec4a152c29d92fc27a4036))
* **date:** allow passing in locale to format dates ([9aab404](https://github.com/neo451/feed.nvim/commit/9aab404e76ea479f6fec4a152c29d92fc27a4036))
* **progress:** allow progress in winbar and statusline ([9aab404](https://github.com/neo451/feed.nvim/commit/9aab404e76ea479f6fec4a152c29d92fc27a4036))


### Bug Fixes

* **bar:** ensure update has complete lines ([9aab404](https://github.com/neo451/feed.nvim/commit/9aab404e76ea479f6fec4a152c29d92fc27a4036))
* **parser:** not show svg in links ([eddfca8](https://github.com/neo451/feed.nvim/commit/eddfca823cb35a827e8ee60dc832abbf9e3873a3))
* **web:** remove double-width colon ([eddfca8](https://github.com/neo451/feed.nvim/commit/eddfca823cb35a827e8ee60dc832abbf9e3873a3))

## [2.15.0](https://github.com/neo451/feed.nvim/compare/v2.14.0...v2.15.0) (2025-03-11)


### Features

* support snacks.picker ([70b2006](https://github.com/neo451/feed.nvim/commit/70b20060e769005a9a09a78fae18c774c816ba74))
* support snacks.picker ([fff976f](https://github.com/neo451/feed.nvim/commit/fff976fce33b47cc062a76e857950aaf2e1753e9))

## [2.14.0](https://github.com/neo451/feed.nvim/compare/v2.13.0...v2.14.0) (2025-03-10)


### Features

* **api:** export ui functions, parse and db ([8e7fc54](https://github.com/neo451/feed.nvim/commit/8e7fc5403a4c332205cfebfad9bb029d9c59187e))
* **config:** give config feeds structured tag ability ([e1f6662](https://github.com/neo451/feed.nvim/commit/e1f66624d0a75aa6b0dc7b0e03fe8d05dd303908))
* **ui:** lazy.nvim style keymap handler ([e1f6662](https://github.com/neo451/feed.nvim/commit/e1f66624d0a75aa6b0dc7b0e03fe8d05dd303908))
* **web:** HTMX for live search in web app ([218a7b1](https://github.com/neo451/feed.nvim/commit/218a7b1b3a2e7c7b0254172052bd28fe910a54c0))


### Bug Fixes

* config search option for ignorecase ([351700d](https://github.com/neo451/feed.nvim/commit/351700dd1c1fa5dfd940cce5a9a2e6c18d203dc2))
* **config:** config.option.ignorecase defaults to true ([8088335](https://github.com/neo451/feed.nvim/commit/80883354455e1b0c327ab8c959560bdf469ee7c2))
* correct ui buffer management, marking next/prev as read, picker not ([c3993cb](https://github.com/neo451/feed.nvim/commit/c3993cbe0fa9f84fe4b01486901e2d860a011f6f))
* properly removes augroup for window close ([4a22e13](https://github.com/neo451/feed.nvim/commit/4a22e132a0ea42b16111d84a870eba3b2cc75d90))
* properly tag entry with tags, regardless of which first ([351700d](https://github.com/neo451/feed.nvim/commit/351700dd1c1fa5dfd940cce5a9a2e6c18d203dc2))
* use function in gsub to avoid escaping issue ([1208fe2](https://github.com/neo451/feed.nvim/commit/1208fe2707b2c3cca816158e1750b09e641d8dca))

## [2.13.0](https://github.com/neo451/feed.nvim/compare/v2.12.0...v2.13.0) (2025-03-05)


### Features

* floating window now resizes on quickfix and cmdline-window ([660d8d6](https://github.com/neo451/feed.nvim/commit/660d8d6aa82ae57a9aae20a7061fba1f619191b6))


### Bug Fixes

* minimal.lua use the remote ([660d8d6](https://github.com/neo451/feed.nvim/commit/660d8d6aa82ae57a9aae20a7061fba1f619191b6))
* properly remove newlines in some entry titles ([660d8d6](https://github.com/neo451/feed.nvim/commit/660d8d6aa82ae57a9aae20a7061fba1f619191b6))

## [2.12.0](https://github.com/neo451/feed.nvim/compare/v2.11.0...v2.12.0) (2025-03-04)


### Features

* a proper minimal.lua for troubleshooting ([5d2c990](https://github.com/neo451/feed.nvim/commit/5d2c99010fccbd3b5f9b7f7fc86ec90d9be5bad7))


### Bug Fixes

* get_urls pattern matching wrong ([10ebb4a](https://github.com/neo451/feed.nvim/commit/10ebb4a3dc32cbb2bcd93af1431c4111d451170f))
* install html, markdown, markdown_inline in lazy.lua ([5d2c990](https://github.com/neo451/feed.nvim/commit/5d2c99010fccbd3b5f9b7f7fc86ec90d9be5bad7))
* typo in progress native impl ([10ebb4a](https://github.com/neo451/feed.nvim/commit/10ebb4a3dc32cbb2bcd93af1431c4111d451170f))

## [2.11.0](https://github.com/neo451/feed.nvim/compare/v2.10.1...v2.11.0) (2025-03-04)


### Features

* **pandoc:** properly use reference style links and inline links for images ([e48af9e](https://github.com/neo451/feed.nvim/commit/e48af9e43e8bc1177ed5de513612b005ef402b53))
* **ui:** defaults to show tags in entry ([7c5726b](https://github.com/neo451/feed.nvim/commit/7c5726bbf748f832d8fa13cdb9a36f709abcbaa5))


### Bug Fixes

* (ui): componants distinguish abort and empty string ([7c5726b](https://github.com/neo451/feed.nvim/commit/7c5726bbf748f832d8fa13cdb9a36f709abcbaa5))
* **db:** query must_have adding results together ([f383e77](https://github.com/neo451/feed.nvim/commit/f383e7771d2fd09bb8ee2f3f9104478f7622824c))
* **image:** bring snack.image integrations up to date ([e48af9e](https://github.com/neo451/feed.nvim/commit/e48af9e43e8bc1177ed5de513612b005ef402b53))
* **lazy:** lazy.lua ts ensure_installed ([dac277f](https://github.com/neo451/feed.nvim/commit/dac277fec8c46b6c0bcef8be2d3376ad6b030be1))
* **parser:** have image links for now ([dac277f](https://github.com/neo451/feed.nvim/commit/dac277fec8c46b6c0bcef8be2d3376ad6b030be1))
* **parser:** simplify show_url impl, leverage pandoc, inspired by link.vim ([f383e77](https://github.com/neo451/feed.nvim/commit/f383e7771d2fd09bb8ee2f3f9104478f7622824c))

## [2.10.1](https://github.com/neo451/feed.nvim/compare/v2.10.0...v2.10.1) (2025-02-28)


### Bug Fixes

* **db:** method for getting entry content ([46daf03](https://github.com/neo451/feed.nvim/commit/46daf0347c80d9df9c08b6f40812d892d4a18f8f))
* move test data to another repo so the plugin is small ([7acfc84](https://github.com/neo451/feed.nvim/commit/7acfc841aa179bf700260e93a328ff2170b9121d))

## [2.10.0](https://github.com/neo451/feed.nvim/compare/v2.9.0...v2.10.0) (2025-02-27)


### Features

* **commands:** export to any file format with pandoc ([0f92af0](https://github.com/neo451/feed.nvim/commit/0f92af0dc7b9c6e5bbcafed64dff7c5051c616d4))
* **ui:** stream shell output to buffer for less freeze when render ([07fdccc](https://github.com/neo451/feed.nvim/commit/07fdccc439ed47ba553c8116fe73ab1b1e295b89))


### Bug Fixes

* **picker:** picker adapt to stream rendering ([f57f929](https://github.com/neo451/feed.nvim/commit/f57f9295b49be5b42ebdc5476e1e1884053fbb0b))
* **ui:** ensure tags order ([07fdccc](https://github.com/neo451/feed.nvim/commit/07fdccc439ed47ba553c8116fe73ab1b1e295b89))
* **ui:** use ts fold in entries ([07fdccc](https://github.com/neo451/feed.nvim/commit/07fdccc439ed47ba553c8116fe73ab1b1e295b89))
* **update:** child process use the current process args ([0f92af0](https://github.com/neo451/feed.nvim/commit/0f92af0dc7b9c6e5bbcafed64dff7c5051c616d4))

## [2.9.0](https://github.com/neo451/feed.nvim/compare/v2.8.0...v2.9.0) (2025-02-26)


### Features

* add config field for asc/desc sort order ([e53b2ad](https://github.com/neo451/feed.nvim/commit/e53b2ad9d0f607b8e75239c5f38f23a79d0aca4d))


### Bug Fixes

* **commands:** rename server to web ([b642e64](https://github.com/neo451/feed.nvim/commit/b642e64f132f30491bd27aae6be021fa26b75b35))
* ensure commands order, show less sub commands ([492c4ef](https://github.com/neo451/feed.nvim/commit/492c4ef30726def8aa56676cebf16cbec1c40f6f))
* **ui:** map yank_url to Y to allow for normal yanking ([b21ed61](https://github.com/neo451/feed.nvim/commit/b21ed614519ce35c87594a58c4e70f92a9a351fe))
* **ui:** winbar has its own config field ([b21ed61](https://github.com/neo451/feed.nvim/commit/b21ed614519ce35c87594a58c4e70f92a9a351fe))

## [2.8.0](https://github.com/neo451/feed.nvim/compare/v2.7.3...v2.8.0) (2025-02-25)


### Features

* **format:** more customizable format functions ([757b1e6](https://github.com/neo451/feed.nvim/commit/757b1e60416c3f2d91786153dfffd6b26767c948))


### Bug Fixes

* seperate picker layout config ([86ea61d](https://github.com/neo451/feed.nvim/commit/86ea61dfc796421fea0311253a4bdcfc934d07ec))

## [2.7.3](https://github.com/neo451/feed.nvim/compare/v2.7.2...v2.7.3) (2025-02-25)


### Bug Fixes

* **db:** keep ttrss interface up to date ([e66877c](https://github.com/neo451/feed.nvim/commit/e66877c6b366fa75308970113959af5be534e5aa))
* **parser:** resolve links base on htmlUrl ([e66877c](https://github.com/neo451/feed.nvim/commit/e66877c6b366fa75308970113959af5be534e5aa))
* **ui:** well format `Feed list` ([4c02423](https://github.com/neo451/feed.nvim/commit/4c02423bd7d12604357fbb0155a4aafc3ca7d001))

## [2.7.2](https://github.com/neo451/feed.nvim/compare/v2.7.1...v2.7.2) (2025-02-24)


### Bug Fixes

* **db:** ensure field exist before regex matching ([2952662](https://github.com/neo451/feed.nvim/commit/29526622c1c513de98a2d50134df02e7261e34f0))
* **ui:** refresh after every feed update ([1ceb641](https://github.com/neo451/feed.nvim/commit/1ceb641f739d7f0a75f48eb6e25f3bf8ee8571d1))

## [2.7.1](https://github.com/neo451/feed.nvim/compare/v2.7.0...v2.7.1) (2025-02-24)


### Bug Fixes

* **doc:** makefile for gen doc ([dc8333c](https://github.com/neo451/feed.nvim/commit/dc8333c38ffcb4633e9c66432b69de458c583246))

## [2.7.0](https://github.com/neo451/feed.nvim/compare/v2.6.0...v2.7.0) (2025-02-24)


### Features

* **parser:** use ts-html to resolve links ([ab4c4a3](https://github.com/neo451/feed.nvim/commit/ab4c4a3986c1e27151ba804ff59c0035683a0fc4))


### Bug Fixes

* add parser requirements ([8c6fb0e](https://github.com/neo451/feed.nvim/commit/8c6fb0ebbef4ea780fe76271576b5f85c54ce4e3))
* **ui:** remove open_url action, no longer needed ([ab4c4a3](https://github.com/neo451/feed.nvim/commit/ab4c4a3986c1e27151ba804ff59c0035683a0fc4))

## [2.6.0](https://github.com/neo451/feed.nvim/compare/v2.5.1...v2.6.0) (2025-02-23)


### Features

* **date:** support weeks_ago ([89cfff3](https://github.com/neo451/feed.nvim/commit/89cfff32971ab95250ca0bbe1a2c57e3170ad368))


### Bug Fixes

* add health check for markdown parser ([c89d9cc](https://github.com/neo451/feed.nvim/commit/c89d9cc0a9d8a922759efeb39650d9f53c7510cb))
* **parser:** author is optional at parsing, fallback at rendering ([89cfff3](https://github.com/neo451/feed.nvim/commit/89cfff32971ab95250ca0bbe1a2c57e3170ad368))
* **parser:** missing author field ([89cfff3](https://github.com/neo451/feed.nvim/commit/89cfff32971ab95250ca0bbe1a2c57e3170ad368))

## [2.5.1](https://github.com/neo451/feed.nvim/compare/v2.5.0...v2.5.1) (2025-02-22)


### Bug Fixes

* **ui:** resolve links earlier for images ([bd513db](https://github.com/neo451/feed.nvim/commit/bd513db30c5b021cbff16c3a038c499a11716585))

## [2.5.0](https://github.com/neo451/feed.nvim/compare/v2.4.0...v2.5.0) (2025-02-22)


### Features

* allow passing format functions to layout components ([4810f53](https://github.com/neo451/feed.nvim/commit/4810f533eefcc5aa0f290c57d137f37c7ba73efe))
* **ui:** properly handle multi-byte chars! ([e9870d1](https://github.com/neo451/feed.nvim/commit/e9870d17aa85e7c5e94c5c76f7185f5783c40727))
* **ui:** simplify UI, move non-essential to recipes ([1cdcf37](https://github.com/neo451/feed.nvim/commit/1cdcf37661f469ded39a9692de5fc183438f3de5))
* **zenmode:** proper backdrop ([1cdcf37](https://github.com/neo451/feed.nvim/commit/1cdcf37661f469ded39a9692de5fc183438f3de5))


### Bug Fixes

* config layouts and kv pair plus and order to avoid tbl_merge issue ([4810f53](https://github.com/neo451/feed.nvim/commit/4810f533eefcc5aa0f290c57d137f37c7ba73efe))
* **config:** configuration option for zen mode ([e9870d1](https://github.com/neo451/feed.nvim/commit/e9870d17aa85e7c5e94c5c76f7185f5783c40727))
* **config:** remove icons table, give it as a recipe later ([e9870d1](https://github.com/neo451/feed.nvim/commit/e9870d17aa85e7c5e94c5c76f7185f5783c40727))
* **ui:** auto-calc window heght ([1cdcf37](https://github.com/neo451/feed.nvim/commit/1cdcf37661f469ded39a9692de5fc183438f3de5))

## [2.4.0](https://github.com/neo451/feed.nvim/compare/v2.3.0...v2.4.0) (2025-02-21)


### Features

* `sync` and `sync!` command to manage feeds and entries ([d3fd355](https://github.com/neo451/feed.nvim/commit/d3fd35590a3e85a4b4f701a0d5a164ad0e54f74f))
* simple zen mode ([318cc93](https://github.com/neo451/feed.nvim/commit/318cc93c0c4abc5de97169beecf95272dad7b26f))
* zenmode properly dims the background ([973a871](https://github.com/neo451/feed.nvim/commit/973a871ddded8be46d40e472bced656748d4ca5e))


### Bug Fixes

* remove prune_feed ([4fd2211](https://github.com/neo451/feed.nvim/commit/4fd22113ab22c1062caf556f1236de5545b73082))

## [2.3.0](https://github.com/neo451/feed.nvim/compare/v2.2.0...v2.3.0) (2025-02-20)


### Features

* **ui:** implement undo/redo in index for tag/untag/search ([227abe1](https://github.com/neo451/feed.nvim/commit/227abe189ab72cd8389dbbb9a9e532b8acafd04b))


### Bug Fixes

* **db:** proper AND/OR logic for multiple regex ([6e92a96](https://github.com/neo451/feed.nvim/commit/6e92a964474b05ff2bce405fe72b8826e93f0e6b))
* properly namespace highlights, greys out just read entries ([105a1a1](https://github.com/neo451/feed.nvim/commit/105a1a155baa024336c1fd10e0f3240cb5f9b230))
* **ui:** make it ok to press &lt;esc&gt; in ui.input ([227abe1](https://github.com/neo451/feed.nvim/commit/227abe189ab72cd8389dbbb9a9e532b8acafd04b))
* **web:** web port config ([9f4c8b6](https://github.com/neo451/feed.nvim/commit/9f4c8b659bbba0684e1592b653c6683994a1c2df))

## [2.2.0](https://github.com/neo451/feed.nvim/compare/v2.1.0...v2.2.0) (2025-02-20)


### Features

* entries inherit tags from feed ([d84d31b](https://github.com/neo451/feed.nvim/commit/d84d31b742e69146e2253eb12bd8366f1f800c68))


### Bug Fixes

* remove check for pathlib ([b2c700e](https://github.com/neo451/feed.nvim/commit/b2c700e76075bdc8ba34f958d0c16552355e5d6d))

## [2.1.0](https://github.com/neo451/feed.nvim/compare/v2.0.2...v2.1.0) (2025-02-19)


### Features

* query syntax support for `!`, meaning inverse regex match ([8d48ccc](https://github.com/neo451/feed.nvim/commit/8d48ccc0f588f24c149b7614ca93bcbde4dbb719))
* query syntax support for `~`, meaning not matching a feed ([c949c05](https://github.com/neo451/feed.nvim/commit/c949c05e7d28e6003ed60c51615e9e5744f1bd5b))
* regex also matches a feed's link like in elfeed ([293b022](https://github.com/neo451/feed.nvim/commit/293b0226f6784c5ff550ec5a05bdb420495d3eea))

## [2.0.2](https://github.com/neo451/feed.nvim/compare/v2.0.1...v2.0.2) (2025-02-19)


### Bug Fixes

* more functional get_urls + remove_urls ([e1169b5](https://github.com/neo451/feed.nvim/commit/e1169b5b6a02701e1422234b4fd93cce62054a5b))

## [2.0.1](https://github.com/neo451/feed.nvim/compare/v2.0.0...v2.0.1) (2025-02-19)


### Bug Fixes

* **curl:** incorrect pass of cb resulting in progress stall ([45a1798](https://github.com/neo451/feed.nvim/commit/45a17980ee502d23effe58c5d08265f2a3de9802))
* **progress:** remove nvim-notify for now ([45a1798](https://github.com/neo451/feed.nvim/commit/45a17980ee502d23effe58c5d08265f2a3de9802))

## [2.0.0](https://github.com/neo451/feed.nvim/compare/v1.19.0...v2.0.0) (2025-02-18)


### ⚠ BREAKING CHANGES

* save html on fetch for performance & web interface

### Features

* save html on fetch for performance & web interface ([6e1d6c2](https://github.com/neo451/feed.nvim/commit/6e1d6c2b06a6e62de54e8214159dc27ad2538cc9))
* **server:** web interface to view entries! ([6e1d6c2](https://github.com/neo451/feed.nvim/commit/6e1d6c2b06a6e62de54e8214159dc27ad2538cc9))
* **web:** dark mode ([696a3ed](https://github.com/neo451/feed.nvim/commit/696a3ed309f1eef773948a0fcb64343536659317))


### Bug Fixes

* **config:** resolve defalult_query properly ([42d7f41](https://github.com/neo451/feed.nvim/commit/42d7f41ec5f1ff18ce07ab5eedd1c3ce98830ecd))

## [1.19.0](https://github.com/neo451/feed.nvim/compare/v1.18.0...v1.19.0) (2025-02-18)


### Features

* support image rendering with snacks.image ([6bd7ab9](https://github.com/neo451/feed.nvim/commit/6bd7ab98dd71328facfaae36134e38fa87bf0dab))


### Bug Fixes

* avoid error on last empty index line ([cf64692](https://github.com/neo451/feed.nvim/commit/cf64692470ac05fcfee7d128e39572a57e56a523))

## [1.18.0](https://github.com/neo451/feed.nvim/compare/v1.17.0...v1.18.0) (2025-02-17)


### Features

* **ui:** use za to toggle list fold, better ts fold ([afcdc6b](https://github.com/neo451/feed.nvim/commit/afcdc6b47893c6fbbd9d3e445c9639b25394d28e))


### Bug Fixes

* **db:** fix field name mismatch between db and parser ([afcdc6b](https://github.com/neo451/feed.nvim/commit/afcdc6b47893c6fbbd9d3e445c9639b25394d28e))
* **ui:** add back entry highlights ([afcdc6b](https://github.com/neo451/feed.nvim/commit/afcdc6b47893c6fbbd9d3e445c9639b25394d28e))
* **ui:** better handling of custom colorscheme ([afcdc6b](https://github.com/neo451/feed.nvim/commit/afcdc6b47893c6fbbd9d3e445c9639b25394d28e))

## [1.17.0](https://github.com/neo451/feed.nvim/compare/v1.16.4...v1.17.0) (2025-02-17)


### Features

* remove pathlib.nvim as dependency ([4df67b5](https://github.com/neo451/feed.nvim/commit/4df67b58d36eb9708bdfa65001115312db120934))


### Bug Fixes

* **curl:** properly quote req headers ([0a9d415](https://github.com/neo451/feed.nvim/commit/0a9d415f22b55b7a8fb811ab3c746a9a16e9aa38))
* remove some tests for now.. ([142ef75](https://github.com/neo451/feed.nvim/commit/142ef75e28c1a729436e115216bb0a1955753e0b))
* use content_type in curl headers to check valid feed ([7d0034d](https://github.com/neo451/feed.nvim/commit/7d0034de87ec62e15151cebbd285147885fdf099))
* use copcall to get err msg in task ([7d0034d](https://github.com/neo451/feed.nvim/commit/7d0034de87ec62e15151cebbd285147885fdf099))

## [1.16.4](https://github.com/neo451/feed.nvim/compare/v1.16.3...v1.16.4) (2025-01-24)


### Bug Fixes

* **parser:** entry content fallback to empty string ([0917c8c](https://github.com/neo451/feed.nvim/commit/0917c8cd69c2bc1f844c0b4e4e78e3805d1deec2))
* remove wrong validate call for back compatibility ([22316e0](https://github.com/neo451/feed.nvim/commit/22316e05bfdeef1d2ea9a33871f879076b07dd60))
* **ui:** correct hl range for vim 0.10 ([0917c8c](https://github.com/neo451/feed.nvim/commit/0917c8cd69c2bc1f844c0b4e4e78e3805d1deec2))
* **url:** pcall get_buf_urls for now because of api difference ([0917c8c](https://github.com/neo451/feed.nvim/commit/0917c8cd69c2bc1f844c0b4e4e78e3805d1deec2))

## [1.16.3](https://github.com/neo451/feed.nvim/compare/v1.16.2...v1.16.3) (2025-01-15)


### Bug Fixes

* **format:** remove plenary require ([60b2003](https://github.com/neo451/feed.nvim/commit/60b20030c5052fa86be84bfdfe2663cf7608f73a))

## [1.16.2](https://github.com/neo451/feed.nvim/compare/v1.16.1...v1.16.2) (2025-01-12)


### Bug Fixes

* **ui:** list feeds info with markdown instead of nui.Tree ([bbb702f](https://github.com/neo451/feed.nvim/commit/bbb702f3475e564601bd2d2871853cd1b63ca327))

## [1.16.1](https://github.com/neo451/feed.nvim/compare/v1.16.0...v1.16.1) (2025-01-11)


### Bug Fixes

* **ui:** mark last visted entry as grey ([79ed4e2](https://github.com/neo451/feed.nvim/commit/79ed4e2c1995e7b44cfc42dec32dba2a19dbd027))
* **ui:** ui.input with noautocmd win_config, no colorscheme blinking ([b06bdbe](https://github.com/neo451/feed.nvim/commit/b06bdbeaa55b1a55bdf263b3ea08ca668434df60))
* **ui:** use vim.hl + my own alignment to render index ([c566fc6](https://github.com/neo451/feed.nvim/commit/c566fc64cce8d19866b0632d707b22b47448a7a2))
* **url:** fix github link handling when not using short links ([b06bdbe](https://github.com/neo451/feed.nvim/commit/b06bdbeaa55b1a55bdf263b3ea08ca668434df60))

## [1.16.0](https://github.com/neo451/feed.nvim/compare/v1.15.1...v1.16.0) (2025-01-11)


### Features

* **curl:** shorthand to subscribe to github repos ([adcd768](https://github.com/neo451/feed.nvim/commit/adcd768cd55cbd541f406679adab4ee436439ced))


### Bug Fixes

* **ui:** move ui.state as a module ([adcd768](https://github.com/neo451/feed.nvim/commit/adcd768cd55cbd541f406679adab4ee436439ced))
* **ui:** open_url action with &lt;cfile&gt; ([adcd768](https://github.com/neo451/feed.nvim/commit/adcd768cd55cbd541f406679adab4ee436439ced))
* **ui:** proper handle of colorschemes ([adcd768](https://github.com/neo451/feed.nvim/commit/adcd768cd55cbd541f406679adab4ee436439ced))

## [1.15.1](https://github.com/neo451/feed.nvim/compare/v1.15.0...v1.15.1) (2025-01-01)


### Bug Fixes

* **config:** drop validate for now ([38c6c0a](https://github.com/neo451/feed.nvim/commit/38c6c0a3e94f82d2a93e1130753b50d805d53ab8))
* **date:** fix new year months ago problem, happy new year ([38c6c0a](https://github.com/neo451/feed.nvim/commit/38c6c0a3e94f82d2a93e1130753b50d805d53ab8))
* **fetch:** use concurrent task with coop.nvim ([38c6c0a](https://github.com/neo451/feed.nvim/commit/38c6c0a3e94f82d2a93e1130753b50d805d53ab8))

## [1.15.0](https://github.com/neo451/feed.nvim/compare/v1.14.5...v1.15.0) (2024-12-30)


### Features

* **nui:** nui based input with normal mode! ([de1bc63](https://github.com/neo451/feed.nvim/commit/de1bc63b559bc38e18852fcf9b7a6d18897dd2b3))
* **ui.bar:** show keyhints ([b4f5418](https://github.com/neo451/feed.nvim/commit/b4f54180f81b2f392c28cd56b5c4e9124c000e3d))
* **ui.bar:** show progress ([4fd6a93](https://github.com/neo451/feed.nvim/commit/4fd6a93208e376b44a94e66a804f9102c8974f55))
* **ui.markdown:** grammarly correct header in yaml format with pandoc ([2b43cbb](https://github.com/neo451/feed.nvim/commit/2b43cbbcce0a4490c0af5743ff6f717d7fc99d16))
* **ui.split:** use floating window for list, hints, split... ([2b43cbb](https://github.com/neo451/feed.nvim/commit/2b43cbbcce0a4490c0af5743ff6f717d7fc99d16))
* **ui:** manage window and buf with a single obj ([de1bc63](https://github.com/neo451/feed.nvim/commit/de1bc63b559bc38e18852fcf9b7a6d18897dd2b3))


### Bug Fixes

* **config:** concealcursor in entry ([9ec065f](https://github.com/neo451/feed.nvim/commit/9ec065f3c83d9cbb59b20feeadb87648018b3637))
* **config:** option to choose whether fill in last search ([e3ea9de](https://github.com/neo451/feed.nvim/commit/e3ea9de32b04691078267ebb489cadaa7c63f090))
* **fetch:** cleanup fetch ([a898db5](https://github.com/neo451/feed.nvim/commit/a898db57b7ac19c81d74bba181fc1ddcf7065136))
* **paser.opml:** replace rsshub links when exporting ([de118fd](https://github.com/neo451/feed.nvim/commit/de118fde1e1a19e80c258dea0d679304c05eff22))
* **ui.bar:** correct winbar truncate ([9ec065f](https://github.com/neo451/feed.nvim/commit/9ec065f3c83d9cbb59b20feeadb87648018b3637))
* **ui.bar:** properly truncate right parts ([d8fe2c3](https://github.com/neo451/feed.nvim/commit/d8fe2c39ae8e79d85059294d35478962cf0ccd1e))
* **ui.bar:** returns a string and sets vim.wo.winbar ([e3ea9de](https://github.com/neo451/feed.nvim/commit/e3ea9de32b04691078267ebb489cadaa7c63f090))
* **ui.config:** add option to have padding ([4fd6a93](https://github.com/neo451/feed.nvim/commit/4fd6a93208e376b44a94e66a804f9102c8974f55))
* **ui.window:** augroup and keymaps for window class ([d8fe2c3](https://github.com/neo451/feed.nvim/commit/d8fe2c39ae8e79d85059294d35478962cf0ccd1e))
* **ui:** reliable buffer state ([ce9c602](https://github.com/neo451/feed.nvim/commit/ce9c60285e2b2293c51b701233b490065a5497db))

## [1.14.5](https://github.com/neo451/feed.nvim/compare/v1.14.4...v1.14.5) (2024-12-22)


### Bug Fixes

* **db:** remove metatable when saving tags.lua ([e5d14bd](https://github.com/neo451/feed.nvim/commit/e5d14bdb3715ebf885cf4c4016a64a8f3133c09b))
* **fetch:** add cb fetch back ... ([bbce910](https://github.com/neo451/feed.nvim/commit/bbce910671ca0828ab585f434eb3a5e4d62e29fb))
* **tag:** use vim.defaulttable for tags ([bbce910](https://github.com/neo451/feed.nvim/commit/bbce910671ca0828ab585f434eb3a5e4d62e29fb))

## [1.14.4](https://github.com/neo451/feed.nvim/compare/v1.14.3...v1.14.4) (2024-12-21)


### Bug Fixes

* **db:** method to update in memory contents ([adea32b](https://github.com/neo451/feed.nvim/commit/adea32babc39aec0e8c6d34873d0f7cc57a37be3))
* **fetch:** rewrite fetch with coop.nvim ([895576e](https://github.com/neo451/feed.nvim/commit/895576e5ae2d33b96dd5463545d52baa271137d4))
* **fzf:** proper fzf ui select ([895576e](https://github.com/neo451/feed.nvim/commit/895576e5ae2d33b96dd5463545d52baa271137d4))
* **ttrss:** lastupdated method ([955e210](https://github.com/neo451/feed.nvim/commit/955e210dc5d6d1b4d342ddaf00e5e41519d2b1d7))
* **ttrss:** use vim.defaultable for tags ([895576e](https://github.com/neo451/feed.nvim/commit/895576e5ae2d33b96dd5463545d52baa271137d4))
* **ui.bar:** move bar rendering to bar.lua ([1602fe7](https://github.com/neo451/feed.nvim/commit/1602fe7e88e5f87e65880b5643327c121ea35fca))
* **ui:** restore window options ([1602fe7](https://github.com/neo451/feed.nvim/commit/1602fe7e88e5f87e65880b5643327c121ea35fca))
* **utils:** vim.startwith for looks_like_url ([895576e](https://github.com/neo451/feed.nvim/commit/895576e5ae2d33b96dd5463545d52baa271137d4))

## [1.14.3](https://github.com/neo451/feed.nvim/compare/v1.14.2...v1.14.3) (2024-12-18)


### Bug Fixes

* **commands:** redo prune feed command ([37c727c](https://github.com/neo451/feed.nvim/commit/37c727cb8bf3b1e415e08c764ec534049a46f5a6))
* **opml:** only export if type is table, avoid pruned and redirects ([37c727c](https://github.com/neo451/feed.nvim/commit/37c727cb8bf3b1e415e08c764ec534049a46f5a6))
* **parser:** fix encolsure parsing for podcasts ([3ffceab](https://github.com/neo451/feed.nvim/commit/3ffceabc930c8f2cea3e1ba6a3cf05ea7914d8c8))
* **pick:** initial grep impl, as menu interface ([37c727c](https://github.com/neo451/feed.nvim/commit/37c727cb8bf3b1e415e08c764ec534049a46f5a6))
* **progress:** more consitency ([37c727c](https://github.com/neo451/feed.nvim/commit/37c727cb8bf3b1e415e08c764ec534049a46f5a6))
* **ui:** consistent index cursor position on refresh ([3ffceab](https://github.com/neo451/feed.nvim/commit/3ffceabc930c8f2cea3e1ba6a3cf05ea7914d8c8))
* **ui:** move commands impl to ui for testing and away from vim.ui stuff ([3ffceab](https://github.com/neo451/feed.nvim/commit/3ffceabc930c8f2cea3e1ba6a3cf05ea7914d8c8))

## [1.14.2](https://github.com/neo451/feed.nvim/compare/v1.14.1...v1.14.2) (2024-12-17)


### Bug Fixes

* **config:** option to enable tag2icon ([106acd2](https://github.com/neo451/feed.nvim/commit/106acd2f3f8357841aae55598c41e287a3459a15))
* **feedparser:** output fulltext when rsshub ([8112665](https://github.com/neo451/feed.nvim/commit/81126652cc6f9b1b929fb061c923258961e78def))
* **fetch:** save entry content with pandoc for stability ([7857bfb](https://github.com/neo451/feed.nvim/commit/7857bfbec7bd4a0d64d26fee82fef2fa958e10a8))
* **ui.format:** use id to get format ([106acd2](https://github.com/neo451/feed.nvim/commit/106acd2f3f8357841aae55598c41e287a3459a15))
* **ui:** correct buffer and colorscheme management ([106acd2](https://github.com/neo451/feed.nvim/commit/106acd2f3f8357841aae55598c41e287a3459a15))
* **ui:** disable spell and list in entry ([106acd2](https://github.com/neo451/feed.nvim/commit/106acd2f3f8357841aae55598c41e287a3459a15))

## [1.14.1](https://github.com/neo451/feed.nvim/compare/v1.14.0...v1.14.1) (2024-12-16)


### Bug Fixes

* **db:** lastUpdated method with getftime ([6bc1520](https://github.com/neo451/feed.nvim/commit/6bc1520c0cc8d5d2e1aa3f8f68631973357011ec))
* **feedparser:** entries has url as feed field for syncing ([6bc1520](https://github.com/neo451/feed.nvim/commit/6bc1520c0cc8d5d2e1aa3f8f68631973357011ec))
* **feedparser:** rss entries' link is resolved properly ([6bc1520](https://github.com/neo451/feed.nvim/commit/6bc1520c0cc8d5d2e1aa3f8f68631973357011ec))
* **ui:** entry buffer set spell to false ([6bc1520](https://github.com/neo451/feed.nvim/commit/6bc1520c0cc8d5d2e1aa3f8f68631973357011ec))
* **ui:** use custom highlight groups in index/winbar ([6bc1520](https://github.com/neo451/feed.nvim/commit/6bc1520c0cc8d5d2e1aa3f8f68631973357011ec))

## [1.14.0](https://github.com/neo451/feed.nvim/compare/v1.13.3...v1.14.0) (2024-12-14)


### Features

* **ui:** serve as a client to ttrss, sees ttrss as db ([c03fb33](https://github.com/neo451/feed.nvim/commit/c03fb333513c8946440b02f1661d5fd68262e1a8))


### Bug Fixes

* **api:** export functions after setup ([a5a3e42](https://github.com/neo451/feed.nvim/commit/a5a3e429eec140025c46a65960bd3d9d1591ea1d))
* **db:** convert to markdown at fetch, not in db ([b2befbc](https://github.com/neo451/feed.nvim/commit/b2befbce0fc7a6ab018211f1b03b4e676ec18e9c))
* **db:** proper tests, rm method ([b66e8ed](https://github.com/neo451/feed.nvim/commit/b66e8edbf9630e472acd3c84993b90b3c605ae5a))
* **fetch:** use json whenever it is rsshub source ([5ff1e75](https://github.com/neo451/feed.nvim/commit/5ff1e759a8977140742f4b0cab85b9e43684f4f5))
* **fzf-lua:** fzf-lua as menu backend ([fc534dc](https://github.com/neo451/feed.nvim/commit/fc534dc73abe2c3e6fa5c22f604259cb4eca8c72))
* **markdown:** gets the pandoc filter with api.nvim_get_runtime_files ([8375a57](https://github.com/neo451/feed.nvim/commit/8375a574780a75a5ab430317d4727b65d0008099))
* **parser.opml:** use description + title instead of text in feeds.lua ([b66e8ed](https://github.com/neo451/feed.nvim/commit/b66e8edbf9630e472acd3c84993b90b3c605ae5a))
* **parser:** calc sha in db instead of parser ([b66e8ed](https://github.com/neo451/feed.nvim/commit/b66e8edbf9630e472acd3c84993b90b3c605ae5a))
* **parser:** opml tags from parent outline should be deepcopied ([0f129d1](https://github.com/neo451/feed.nvim/commit/0f129d185819501641bfc744d1a2ec70594e12f5))
* **telescope:** feed grep redone ([2c62692](https://github.com/neo451/feed.nvim/commit/2c62692211201f8d6453ee3728e5a723f4628583))
* **telescope:** native picker for telescope ([2c62692](https://github.com/neo451/feed.nvim/commit/2c62692211201f8d6453ee3728e5a723f4628583))
* **ui:** ability to render entry from content function ([7e67fb9](https://github.com/neo451/feed.nvim/commit/7e67fb95ec765ed0878e8ed27cee3627e31655b8))
* **ui:** align header and index, no listchars in entry ([5ff1e75](https://github.com/neo451/feed.nvim/commit/5ff1e759a8977140742f4b0cab85b9e43684f4f5))
* **ui:** custom higlight groups ([5ff1e75](https://github.com/neo451/feed.nvim/commit/5ff1e759a8977140742f4b0cab85b9e43684f4f5))
* **ui:** fix entry buffer not named ([8375a57](https://github.com/neo451/feed.nvim/commit/8375a574780a75a5ab430317d4727b65d0008099))
* **ui:** markdown converter accepts src html ([7e67fb9](https://github.com/neo451/feed.nvim/commit/7e67fb95ec765ed0878e8ed27cee3627e31655b8))
* **ui:** properly clears lines when rerendering ([fc534dc](https://github.com/neo451/feed.nvim/commit/fc534dc73abe2c3e6fa5c22f604259cb4eca8c72))
* **ui:** put cursor back to top on every render ([7e67fb9](https://github.com/neo451/feed.nvim/commit/7e67fb95ec765ed0878e8ed27cee3627e31655b8))

## [1.13.3](https://github.com/neo451/feed.nvim/compare/v1.13.2...v1.13.3) (2024-12-09)


### Bug Fixes

* hl for metadata ([f1614d1](https://github.com/neo451/feed.nvim/commit/f1614d15d9121776a2f7bf62b5013db3cd45fb90))
* set ft early to trigger image.nvim/render-markdown.nvim... ([f1614d1](https://github.com/neo451/feed.nvim/commit/f1614d15d9121776a2f7bf62b5013db3cd45fb90))

## [1.13.2](https://github.com/neo451/feed.nvim/compare/v1.13.1...v1.13.2) (2024-12-07)


### Bug Fixes

* rename bunch of commands shorter for clarity ([aac4240](https://github.com/neo451/feed.nvim/commit/aac4240103ccfa7809149474a80925dde3c99963))
* update_feed fixed ([aac4240](https://github.com/neo451/feed.nvim/commit/aac4240103ccfa7809149474a80925dde3c99963))

## [1.13.1](https://github.com/neo451/feed.nvim/compare/v1.13.0...v1.13.1) (2024-12-07)


### Bug Fixes

* **ui:** fix winbar alignment ([cd79bfb](https://github.com/neo451/feed.nvim/commit/cd79bfbb6def42e4a9eb38da415cfd3d217296c2))
* **ui:** handle text alignment without plenary ([cd79bfb](https://github.com/neo451/feed.nvim/commit/cd79bfbb6def42e4a9eb38da415cfd3d217296c2))
* **ui:** remove integration for formatters, autocmd and pandoc power! ([3ccd7af](https://github.com/neo451/feed.nvim/commit/3ccd7af8056d8be5612707a6e6513d8746e86922))
* **ui:** show_full using the -r of pandoc ([cd79bfb](https://github.com/neo451/feed.nvim/commit/cd79bfbb6def42e4a9eb38da415cfd3d217296c2))

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
