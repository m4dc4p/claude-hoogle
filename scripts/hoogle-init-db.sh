#!/usr/bin/env bash
# hoogle-init-db.sh - Check and initialize Hoogle database
#
# This script ensures a valid Hoogle database exists. It:
# 1. Checks if hoogle is on PATH
# 2. Checks if the default database exists and is valid
# 3. Generates a new database if needed
#
# Usage: ./hoogle-init-db.sh [--local PATH] [--force]
#   --local PATH  Generate database from local Haddock docs at PATH
#   --force       Force regeneration even if database exists
#
# Exit codes:
#   0 - Success (database is ready)
#   1 - Error (hoogle not found, generation failed, etc.)

set -euo pipefail

# Configuration
HOOGLE_DIR="${HOME}/.hoogle"
MIN_DB_SIZE=1000  # Minimum valid database size in bytes

# Parse arguments
LOCAL_PATH=""
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --local)
            LOCAL_PATH="$2"
            shift 2
            ;;
        --force)
            FORCE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--local PATH] [--force]"
            echo "  --local PATH  Generate database from local Haddock docs"
            echo "  --force       Force regeneration even if database exists"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Check if hoogle is available
check_hoogle() {
    if ! command -v hoogle &> /dev/null; then
        echo '{"error": "hoogle not found", "message": "Hoogle is not installed or not in PATH. Please install hoogle first."}' >&2
        exit 1
    fi
    echo "Found hoogle at: $(command -v hoogle)" >&2
}

# Find the current database file
find_database() {
    # Hoogle uses versioned database names
    local version
    version=$(hoogle --numeric-version 2>/dev/null || echo "unknown")
    echo "${HOOGLE_DIR}/default-haskell-${version}.hoo"
}

# Check if database exists and is valid
check_database() {
    local db_file="$1"

    if [[ ! -f "$db_file" ]]; then
        echo "Database file not found: $db_file" >&2
        return 1
    fi

    local size
    size=$(stat -c%s "$db_file" 2>/dev/null || stat -f%z "$db_file" 2>/dev/null || echo "0")

    if [[ "$size" -lt "$MIN_DB_SIZE" ]]; then
        echo "Database file is too small (${size} bytes), likely corrupt or incomplete" >&2
        return 1
    fi

    # Quick validation: try a simple search
    if ! hoogle search "" --count=1 &>/dev/null; then
        echo "Database validation failed - cannot perform search" >&2
        return 1
    fi

    echo "Database is valid: $db_file (${size} bytes)" >&2
    return 0
}

# Generate the database
generate_database() {
    echo "Generating Hoogle database..." >&2

    mkdir -p "$HOOGLE_DIR"

    if [[ -n "$LOCAL_PATH" ]]; then
        echo "Generating from local path: $LOCAL_PATH" >&2
        if ! hoogle generate --local="$LOCAL_PATH" 2>&1; then
            echo '{"error": "generation_failed", "message": "Failed to generate Hoogle database from local path"}' >&2
            exit 1
        fi
    else
        echo "Generating from Stackage (this may take a while)..." >&2
        if ! hoogle generate 2>&1; then
            echo '{"error": "generation_failed", "message": "Failed to generate Hoogle database"}' >&2
            exit 1
        fi
    fi

    echo "Database generation complete" >&2
}

# Main logic
main() {
    check_hoogle

    local db_file
    db_file=$(find_database)

    if [[ "$FORCE" == "true" ]]; then
        echo "Force regeneration requested" >&2
        generate_database
    elif ! check_database "$db_file"; then
        echo "Database needs to be generated" >&2
        generate_database
    else
        echo "Database is ready" >&2
    fi

    # Output success as JSON
    echo '{"status": "ready", "database": "'"$db_file"'"}'
}

main "$@"
