#!/usr/bin/env bash
# hoogle-search.sh - Search Hoogle and return JSON results
#
# This script wraps hoogle search to provide consistent JSON output.
# It handles database initialization and provides useful error messages.
#
# Usage: ./hoogle-search.sh QUERY [--count N] [--info]
#   QUERY       The search query (function name or type signature)
#   --count N   Maximum number of results (default: 10)
#   --info      Get detailed info about the first result
#
# Output: JSON object with results or error
#
# Examples:
#   ./hoogle-search.sh "map"
#   ./hoogle-search.sh "a -> b -> a" --count 5
#   ./hoogle-search.sh "foldl" --info

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
COUNT=10
INFO=false
QUERY=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --count)
            COUNT="$2"
            shift 2
            ;;
        --info)
            INFO=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 QUERY [--count N] [--info]"
            echo "  QUERY       Search query (function name or type signature)"
            echo "  --count N   Maximum number of results (default: 10)"
            echo "  --info      Get detailed info about first result"
            exit 0
            ;;
        -*)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
        *)
            if [[ -z "$QUERY" ]]; then
                QUERY="$1"
            else
                QUERY="$QUERY $1"
            fi
            shift
            ;;
    esac
done

# Validate query
if [[ -z "$QUERY" ]]; then
    echo '{"error": "missing_query", "message": "No search query provided"}' >&2
    exit 1
fi

# Check if hoogle is available
if ! command -v hoogle &> /dev/null; then
    echo '{"error": "hoogle_not_found", "message": "Hoogle is not installed or not in PATH"}' >&2
    exit 1
fi

# Build hoogle command
HOOGLE_ARGS=(search "$QUERY" --json --count "$COUNT")

if [[ "$INFO" == "true" ]]; then
    HOOGLE_ARGS+=(--info)
fi

# Run hoogle and capture output
OUTPUT=""
EXIT_CODE=0

if OUTPUT=$(hoogle "${HOOGLE_ARGS[@]}" 2>&1); then
    EXIT_CODE=0
else
    EXIT_CODE=$?
fi

# Handle errors
if [[ $EXIT_CODE -ne 0 ]]; then
    # Check for common errors
    if echo "$OUTPUT" | grep -q "corrupt"; then
        echo '{"error": "database_corrupt", "message": "Hoogle database is corrupt. Run hoogle-init-db.sh to regenerate."}' >&2
        exit 1
    elif echo "$OUTPUT" | grep -q "does not exist"; then
        echo '{"error": "database_missing", "message": "Hoogle database not found. Run hoogle-init-db.sh to generate."}' >&2
        exit 1
    else
        # Generic error with original message
        # Escape special characters for JSON
        ESCAPED_OUTPUT=$(echo "$OUTPUT" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' ' ')
        echo '{"error": "hoogle_error", "message": "'"$ESCAPED_OUTPUT"'"}' >&2
        exit 1
    fi
fi

# Check for empty results or "No results found" message
if [[ -z "$OUTPUT" ]] || [[ "$OUTPUT" == "[]" ]] || [[ "$OUTPUT" == "No results found" ]]; then
    echo '{"results": [], "query": "'"$QUERY"'", "count": 0}'
    exit 0
fi

# Verify output is valid JSON before processing
if ! echo "$OUTPUT" | jq . &>/dev/null; then
    # Not valid JSON - might be an error message
    ESCAPED_OUTPUT=$(echo "$OUTPUT" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' ' ')
    echo '{"error": "invalid_output", "message": "'"$ESCAPED_OUTPUT"'"}' >&2
    exit 1
fi

# Wrap the results in our standard format
# hoogle --json returns an array directly, so we wrap it
echo '{"results": '"$OUTPUT"', "query": "'"$QUERY"'", "count": '"$(echo "$OUTPUT" | jq 'length')"'}'
