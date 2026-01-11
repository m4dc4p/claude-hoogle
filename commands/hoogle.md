---
description: Search Haskell APIs with Hoogle - find functions by name or type signature
allowed-tools: Bash(./scripts/hoogle-search.sh:*), Bash(./scripts/hoogle-init-db.sh:*)
---

# Hoogle Search

Search Haskell APIs using Hoogle. You can search by:
- **Function name**: `map`, `filter`, `foldl`
- **Type signature**: `a -> b -> a`, `(a -> Bool) -> [a] -> [a]`
- **Package-qualified**: `+base map`, `+containers lookup`

## Context

User query: $ARGUMENTS

## Instructions

1. First, check if this is a search query or if the user needs help:
   - If the user asks for help, explain how Hoogle works
   - Otherwise, proceed with the search

2. Run the Hoogle search:
   ```bash
   ./scripts/hoogle-search.sh "$ARGUMENTS" --count 10
   ```

3. If the search fails with a database error:
   - Inform the user that the database needs to be initialized
   - Run `./scripts/hoogle-init-db.sh` to generate it
   - This may take several minutes on first run

4. Present results clearly:
   - Show the function signature prominently
   - Include the module and package
   - Show relevant documentation
   - If the results seem off, suggest alternative search terms

5. For type signature searches, explain what the type means in plain language.

## Output Format

For each relevant result, show:
- **Function**: `functionName :: TypeSignature`
- **From**: `Module.Name` (package-name)
- **Description**: Brief doc summary

If the user asks for details on a specific result, use `--info` to get full documentation.
