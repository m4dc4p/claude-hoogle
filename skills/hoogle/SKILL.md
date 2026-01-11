---
name: hoogle
description: Search Haskell APIs using Hoogle. Use this skill when working with Haskell projects to look up function signatures, find functions by type, or discover library documentation. Activate proactively when you need to understand Haskell library APIs, find the right function for a task, or look up type signatures.
---

# Hoogle API Search

Hoogle is a Haskell API search engine. Use it to find functions by name or by type signature.

## When to Use Hoogle

Use Hoogle proactively when:
- Working with Haskell code and need to find a function
- Looking up the type signature of a function
- Searching for functions that match a type signature (e.g., `a -> b -> a`)
- Finding which module exports a particular function
- Looking up documentation for Haskell functions

## Search Methods

### Search by Function Name

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/hoogle-search.sh "map"
```

Returns functions named "map" or containing "map" in their name.

### Search by Type Signature

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/hoogle-search.sh "a -> b -> a"
```

Returns functions matching that type signature. Type variables are automatically generalized.

### Search with Package Filter

Include package names in the query:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/hoogle-search.sh "+base map"
${CLAUDE_PLUGIN_ROOT}/scripts/hoogle-search.sh "+containers Data.Map.lookup"
```

### Get Detailed Info

Use `--info` for the first result's documentation:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/hoogle-search.sh "foldl" --info
```

## Understanding Results

The search returns JSON with this structure:
```json
{
  "results": [
    {
      "url": "https://hackage.haskell.org/package/base/docs/Prelude.html#v:map",
      "module": {"name": "Prelude", "url": "..."},
      "package": {"name": "base", "url": "..."},
      "item": "map :: (a -> b) -> [a] -> [b]",
      "docs": "map f xs is the list obtained by applying f to each element..."
    }
  ],
  "query": "map",
  "count": 10
}
```

Key fields:
- `item`: The function signature
- `docs`: Documentation/description
- `module.name`: The module that exports this function
- `package.name`: The package containing this function

## Database Initialization

Before searching, ensure the Hoogle database exists:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/hoogle-init-db.sh
```

This checks for a valid database and generates one from Stackage if needed. Generation takes several minutes on first run.

### Local Database

For project-specific searches, generate a local database:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/hoogle-init-db.sh --local /path/to/haddock/docs
```

## Common Search Patterns

| Goal | Query Example |
|------|---------------|
| Find function by name | `hoogle-search.sh "filter"` |
| Find by exact type | `hoogle-search.sh "(a -> Bool) -> [a] -> [a]"` |
| Find in specific package | `hoogle-search.sh "+lens view"` |
| Find class methods | `hoogle-search.sh "Monad m => m a -> m b"` |
| Find by partial type | `hoogle-search.sh "Map k v -> k -> Maybe v"` |

## Tips

1. **Type signatures are powerful**: Searching `a -> a` finds `id`, while `[a] -> a` finds `head`.
2. **Use package filters**: Narrow results with `+packagename`.
3. **Check multiple results**: The best match isn't always first.
4. **Look at the module**: Tells you what to import.

## Error Handling

If searches fail with database errors, run:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/hoogle-init-db.sh --force
```

This regenerates the database from scratch.
