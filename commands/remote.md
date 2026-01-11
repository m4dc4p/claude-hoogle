---
description: Search online Hoogle at hoogle.haskell.org (or custom URL)
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/hoogle-remote.sh:*)
---

# Remote Hoogle Search

Search the online Hoogle server for Haskell functions and types.

Search syntax:
- **Function name**: `map`, `filter`, `foldl`
- **Type signature**: `a -> b -> a`, `(a -> Bool) -> [a] -> [a]`
- **Package-qualified**: `+base map`, `+containers lookup`

## Context

User query: $ARGUMENTS

## Instructions

1. Parse the user's query. If they specify a custom URL with `--url`, use it. Otherwise use the default hoogle.haskell.org.

2. Run the remote Hoogle search:
   ```bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/hoogle-remote.sh "$ARGUMENTS" --count 10
   ```

3. Present results clearly:
   - Show the function signature prominently
   - Include the module and package
   - Show relevant documentation
   - Note the source URL if not the default

4. For type signature searches, explain what the type means in plain language.

## Output Format

For each relevant result, show:
- **Function**: `functionName :: TypeSignature`
- **From**: `Module.Name` (package-name)
- **Description**: Brief doc summary

## Custom Hoogle Servers

Users can specify a custom Hoogle server:
```
/hoogle:remote map --url https://custom-hoogle.example.com
```
