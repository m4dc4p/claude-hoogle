#!/usr/bin/env bash
# hoogle-remote.sh - Search remote Hoogle instance and return JSON results
#
# This script queries a remote Hoogle server (default: hoogle.haskell.org)
# to search for Haskell functions and types.
#
# Usage: ./hoogle-remote.sh QUERY [--count N] [--url URL]
#   QUERY       The search query (function name or type signature)
#   --count N   Maximum number of results (default: 10)
#   --url URL   Remote Hoogle URL (default: https://hoogle.haskell.org)
#
# Output: JSON object with results or error
#
# Examples:
#   ./hoogle-remote.sh "map"
#   ./hoogle-remote.sh "a -> b -> a" --count 5
#   ./hoogle-remote.sh "map" --url https://hoogle.example.com

set -euo pipefail

# Default values
COUNT=10
BASE_URL="https://hoogle.haskell.org"
QUERY=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --count)
            COUNT="$2"
            shift 2
            ;;
        --url)
            BASE_URL="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 QUERY [--count N] [--url URL]"
            echo "  QUERY       Search query (function name or type signature)"
            echo "  --count N   Maximum number of results (default: 10)"
            echo "  --url URL   Remote Hoogle URL (default: https://hoogle.haskell.org)"
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

# Check if curl is available
if ! command -v curl &> /dev/null; then
    echo '{"error": "curl_not_found", "message": "curl is not installed or not in PATH"}' >&2
    exit 1
fi

# URL encode the query
ENCODED_QUERY=$(printf '%s' "$QUERY" | jq -sRr @uri)

# Build the URL
URL="${BASE_URL}?mode=json&format=text&hoogle=${ENCODED_QUERY}&start=1&count=${COUNT}"

# Make the request
OUTPUT=""
EXIT_CODE=0
HTTP_CODE=""

# Use curl with error handling
RESPONSE=$(curl -sS -w "\n%{http_code}" "$URL" 2>&1) || EXIT_CODE=$?

if [[ $EXIT_CODE -ne 0 ]]; then
    ESCAPED_OUTPUT=$(echo "$RESPONSE" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' ' ')
    echo '{"error": "network_error", "message": "'"$ESCAPED_OUTPUT"'"}' >&2
    exit 1
fi

# Extract HTTP code (last line) and body (everything else)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
OUTPUT=$(echo "$RESPONSE" | sed '$d')

# Check HTTP status
if [[ "$HTTP_CODE" != "200" ]]; then
    echo '{"error": "http_error", "message": "HTTP '"$HTTP_CODE"' from '"$BASE_URL"'"}' >&2
    exit 1
fi

# Check for empty results
if [[ -z "$OUTPUT" ]] || [[ "$OUTPUT" == "[]" ]]; then
    echo '{"results": [], "query": "'"$QUERY"'", "count": 0, "source": "'"$BASE_URL"'"}'
    exit 0
fi

# Verify output is valid JSON
if ! echo "$OUTPUT" | jq . &>/dev/null; then
    ESCAPED_OUTPUT=$(echo "$OUTPUT" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' ' ')
    echo '{"error": "invalid_json", "message": "'"$ESCAPED_OUTPUT"'"}' >&2
    exit 1
fi

# Wrap the results in our standard format
RESULT_COUNT=$(echo "$OUTPUT" | jq 'length')
echo '{"results": '"$OUTPUT"', "query": "'"$QUERY"'", "count": '"$RESULT_COUNT"', "source": "'"$BASE_URL"'"}'
