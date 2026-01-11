#!/usr/bin/env bash
# test-hoogle-remote.sh - Tests for hoogle-remote.sh wrapper
#
# Run these tests to verify the remote hoogle wrapper works correctly.
# Requires network connectivity to hoogle.haskell.org.
#
# Usage: ./tests/test-hoogle-remote.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REMOTE_SCRIPT="$PROJECT_DIR/scripts/hoogle-remote.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Helper functions
pass() {
    echo -e "${GREEN}PASS${NC}: $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
    echo -e "${RED}FAIL${NC}: $1"
    echo "  Expected: $2"
    echo "  Got: $3"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

skip() {
    echo -e "${YELLOW}SKIP${NC}: $1 - $2"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
}

run_test() {
    TESTS_RUN=$((TESTS_RUN + 1))
}

# Check prerequisites
check_prerequisites() {
    if ! command -v curl &> /dev/null; then
        echo "Error: curl not found in PATH"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        echo "Error: jq not found in PATH (required for JSON parsing)"
        exit 1
    fi

    if [ ! -x "$REMOTE_SCRIPT" ]; then
        chmod +x "$REMOTE_SCRIPT"
    fi

    # Check network connectivity
    if ! curl -sS --max-time 5 "https://hoogle.haskell.org" &>/dev/null; then
        echo "Warning: Cannot reach hoogle.haskell.org - some tests may fail"
    fi
}

# Test: Many results scenario
test_many_results() {
    run_test
    local query="map"
    local output
    local exit_code=0
    output=$("$REMOTE_SCRIPT" "$query" --count 10 2>&1) || exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        if echo "$output" | jq -e '.error == "network_error"' &>/dev/null; then
            skip "Many results" "network error"
            return
        fi
        fail "Many results: exit code" "0" "$exit_code"
        return
    fi

    # Check it's valid JSON
    if ! echo "$output" | jq . &>/dev/null; then
        fail "Many results: valid JSON" "valid JSON" "$output"
        return
    fi

    # Check we got results array
    local count
    count=$(echo "$output" | jq '.count')
    if [ "$count" -ge 5 ]; then
        pass "Many results: got $count results for '$query'"
    else
        fail "Many results: expected >=5 results" ">=5" "$count"
    fi

    # Check results have expected structure
    local first_item
    first_item=$(echo "$output" | jq '.results[0].item' 2>/dev/null)
    if [ -n "$first_item" ] && [ "$first_item" != "null" ]; then
        pass "Many results: results have 'item' field"
    else
        fail "Many results: item field" "non-null item" "$first_item"
    fi

    # Check source is included
    local source
    source=$(echo "$output" | jq -r '.source')
    if [ "$source" == "https://hoogle.haskell.org" ]; then
        pass "Many results: source URL included"
    else
        fail "Many results: source" "https://hoogle.haskell.org" "$source"
    fi
}

# Test: No results scenario
test_no_results() {
    run_test
    local query="xyzzyNotARealFunction12345"
    local output
    local exit_code=0
    output=$("$REMOTE_SCRIPT" "$query" 2>&1) || exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        if echo "$output" | jq -e '.error == "network_error"' &>/dev/null; then
            skip "No results" "network error"
            return
        fi
    fi

    # Check it's valid JSON
    if ! echo "$output" | jq . &>/dev/null; then
        fail "No results: valid JSON" "valid JSON" "$output"
        return
    fi

    # Check count is 0
    local count
    count=$(echo "$output" | jq '.count')
    if [ "$count" -eq 0 ]; then
        pass "No results: count is 0 for non-existent query"
    else
        fail "No results: expected 0" "0" "$count"
    fi
}

# Test: Type signature search
test_type_signature_search() {
    run_test
    local query="a -> b -> a"
    local output
    local exit_code=0
    output=$("$REMOTE_SCRIPT" "$query" --count 5 2>&1) || exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        if echo "$output" | jq -e '.error == "network_error"' &>/dev/null; then
            skip "Type search" "network error"
            return
        fi
    fi

    # Check it's valid JSON
    if ! echo "$output" | jq . &>/dev/null; then
        fail "Type search: valid JSON" "valid JSON" "$output"
        return
    fi

    # Check we got results
    local count
    count=$(echo "$output" | jq '.count')
    if [ "$count" -ge 1 ]; then
        pass "Type search: got $count results for type signature"
    else
        fail "Type search: expected >=1 results" ">=1" "$count"
    fi
}

# Test: Missing query error
test_missing_query_error() {
    run_test
    local output
    local exit_code=0
    output=$("$REMOTE_SCRIPT" 2>&1) || exit_code=$?

    if [ $exit_code -ne 0 ]; then
        pass "Missing query: returns non-zero exit code"
    else
        fail "Missing query: exit code" "non-zero" "$exit_code"
    fi

    if echo "$output" | jq -e '.error' &>/dev/null; then
        pass "Missing query: returns error JSON"
    else
        fail "Missing query: error JSON" "error field" "$output"
    fi
}

# Test: Count parameter
test_count_parameter() {
    run_test
    local query="filter"
    local output
    local exit_code=0
    output=$("$REMOTE_SCRIPT" "$query" --count 3 2>&1) || exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        if echo "$output" | jq -e '.error == "network_error"' &>/dev/null; then
            skip "Count parameter" "network error"
            return
        fi
    fi

    local count
    count=$(echo "$output" | jq '.count')
    if [ "$count" -le 3 ]; then
        pass "Count parameter: respects --count 3 (got $count)"
    else
        fail "Count parameter: expected <=3" "<=3" "$count"
    fi
}

# Test: Custom URL parameter (with invalid URL to test parameter handling)
test_custom_url_parameter() {
    run_test
    local query="map"
    local output
    local exit_code=0
    # Use the default URL explicitly to verify --url works
    output=$("$REMOTE_SCRIPT" "$query" --url "https://hoogle.haskell.org" --count 1 2>&1) || exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        if echo "$output" | jq -e '.error == "network_error"' &>/dev/null; then
            skip "Custom URL" "network error"
            return
        fi
    fi

    # Check source reflects the URL
    local source
    source=$(echo "$output" | jq -r '.source')
    if [ "$source" == "https://hoogle.haskell.org" ]; then
        pass "Custom URL: --url parameter accepted"
    else
        fail "Custom URL: source" "https://hoogle.haskell.org" "$source"
    fi
}

# Test: Query with special characters
test_special_characters() {
    run_test
    local query="(a -> b) -> [a] -> [b]"
    local output
    local exit_code=0
    output=$("$REMOTE_SCRIPT" "$query" 2>&1) || exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        if echo "$output" | jq -e '.error == "network_error"' &>/dev/null; then
            skip "Special chars" "network error"
            return
        fi
    fi

    # Check it's valid JSON
    if ! echo "$output" | jq . &>/dev/null; then
        fail "Special chars: valid JSON" "valid JSON" "$output"
        return
    fi

    local count
    count=$(echo "$output" | jq '.count')
    if [ "$count" -ge 1 ]; then
        pass "Special chars: handled type with brackets/arrows"
    else
        fail "Special chars: expected results" ">=1" "$count"
    fi
}

# Main test runner
main() {
    echo "================================"
    echo "Hoogle Remote Search Tests"
    echo "================================"
    echo ""

    echo "Checking prerequisites..."
    check_prerequisites
    echo "Prerequisites OK"
    echo ""

    echo "Running tests..."
    echo ""

    test_many_results
    test_no_results
    test_type_signature_search
    test_missing_query_error
    test_count_parameter
    test_custom_url_parameter
    test_special_characters

    echo ""
    echo "================================"
    echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed, $TESTS_SKIPPED skipped (of $TESTS_RUN)"
    echo "================================"

    if [ $TESTS_FAILED -gt 0 ]; then
        exit 1
    fi
}

main "$@"
