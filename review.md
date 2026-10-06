## Real potential bugs

### 1B — Error-path and data-integrity bugs

- Redirect resolution can return nil and overwrite url: lua/feed/fetch.lua:51
- Encoding blacklist appears ineffective because parsed feeds do not expose
  encoding: lua/feed/fetch.lua:52
- Missing feed metadata produces contradictory assert/fallback logic:
  lua/feed/server/init.lua:59-75
- Missing paths can race with uv.fs_stat: lua/feed/db/path.lua:74
- Stale local index entries can break feed filtering:
  lua/feed/db/local.lua:358-371
- Search POST bodies can omit the expected query: lua/feed/server/init.lua:88

## Manual confirmation / redesign decisions

### 2A — UI state lifecycle

lua/feed/ui.lua still has 17 warnings around:

- optional state.entries, state.index, and state.entry
- asynchronous render callbacks referencing mutable global state
- commands callable outside their expected view
- optional layout formatter functions

This should be addressed by defining explicit UI states/transitions rather than
adding assertions independently.

### 2B — Parsed-feed contract

lua/feed/parser.lua and lua/feed/parser/atom.lua disagree over whether feed
links are mandatory.

Decision required:

- reject feeds without links,
- use the source URL as fallback, or
- make links optional throughout storage/rendering.

Making the type optional alone would hide downstream failures.

### 2C — Backend/configuration model

- Unknown protocol backends currently fall through: lua/feed/db/init.lua:5
- TTRSS URL credentials are optional in configuration but required at runtime.
- TTRSS backend has unfinished sync methods and needs an explicit failure
  policy.
- Local tags use metatable-created tables, making some existence checks
  misleading.

A discriminated local/TTRSS configuration and backend interface would resolve
these coherently.

### 2D — Vendored compatibility code

lua/feed/lib/entities.lua accounts for 13 warnings involving LuaJIT/Lua 5.3
branches, numeric coercion, and compile-time constants.

Choose between:

- preserving and excluding the vendored file from strict checks,
- replacing/upgrading the library, or
- modernizing it specifically for Neovim/LuaJIT.

### 2E — I/O contract cleanup

lua/feed/curl.lua:48 has an unreachable nil branch because read_file throws
rather than returning nil. Decide whether file helpers should be throwing or
nullable and make callers consistent.

Suggested implementation order

1. Fix the eight localized bugs in 1A, with regression tests.
2. Harden fetch/server/local persistence error paths.
3. Define the UI state lifecycle.
4. Resolve parsed-feed link requirements.
5. Redesign backend configuration and TTRSS behavior.
6. Decide vendored-library policy.
7. Enable warnings-as-errors once the remaining diagnostics are resolved.

## later

1. Mini picker passes two return values as buffer lines
   lua/feed/pickers/mini/pick.lua:72
   { ui.headline(id) } captures both headline and coordinate table.
