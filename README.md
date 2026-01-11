# Hoogle Plugin for Claude Code

Search Haskell APIs using [Hoogle](https://hoogle.haskell.org/) directly from Claude Code.

## Usage

### Slash Command

Use `/hoogle:search` to search for Haskell functions:

```
/hoogle:search map
/hoogle:search (a -> Bool) -> [a] -> [a]
/hoogle:search +base foldl
```

### Automatic Skill

The hoogle skill activates automatically when Claude is working with Haskell code and needs to look up functions, type signatures, or documentation.

## Search Examples

| Goal | Query |
|------|-------|
| Find by name | `map`, `filter`, `foldl` |
| Find by type | `a -> b -> a`, `(a -> Bool) -> [a] -> [a]` |
| Filter by package | `+base map`, `+containers lookup` |

## Requirements

- `hoogle` executable must be on PATH
- Database is generated automatically on first use (may take several minutes)

## Installation

Add this plugin to your Claude Code configuration.
