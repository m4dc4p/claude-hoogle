# Hoogle Plugin for Claude Code

Search Haskell APIs using [Hoogle](https://hoogle.haskell.org/) directly from Claude Code.

## Commands

### `/hoogle:search` - Local Search

Search your local Hoogle database:

```
/hoogle:search map
/hoogle:search (a -> Bool) -> [a] -> [a]
/hoogle:search +base foldl
```

Requires `hoogle` executable on PATH. Local database is generated automatically on first use.

### `/hoogle:remote` - Online Search

Search the official Hoogle server at hoogle.haskell.org:

```
/hoogle:remote map
/hoogle:remote (a -> Bool) -> [a] -> [a]
```

Use a custom Hoogle server:
```
/hoogle:remote map --url https://custom-hoogle.example.com
```

### Automatic Skill

The hoogle skill activates automatically when Claude is working with Haskell code and needs to look up functions, type signatures, or documentation.

## Search Examples

| Goal | Query |
|------|-------|
| Find by name | `map`, `filter`, `foldl` |
| Find by type | `a -> b -> a`, `(a -> Bool) -> [a] -> [a]` |
| Filter by package | `+base map`, `+containers lookup` |

## Prerequisites

- `hoogle` executable on PATH (`cabal install hoogle` or `stack install hoogle`)
- `jq` for JSON parsing
- For remote search: `curl`

## Installation

1. Add the marketplace:
   ```
   /plugin marketplace add m4dc4p/claude-hoogle
   ```

2. Install the plugin:
   ```
   /plugin install hoogle@claude-hoogle
   ```
