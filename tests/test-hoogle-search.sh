#!/usr/bin/env bash
# test-hoogle-search.sh - Tests for hoogle-search.sh wrapper
#
# Run these tests to verify the hoogle wrapper works correctly.
# Requires a valid Hoogle database to be installed.
#
# Usage: ./tests/test-hoogle-search.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SEARCH_SCRIPT="$PROJECT_DIR/scripts/hoogle-search.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

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
}

run_test() {
    TESTS_RUN=$((TESTS_RUN + 1))
}

# Check prerequisites
check_prerequisites() {
    if ! command -v hoogle &> /dev/null; then
        echo "Error: hoogle not found in PATH"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        echo "Error: jq not found in PATH (required for JSON parsing)"
        exit 1
    fi

    if [ ! -x "$SEARCH_SCRIPT" ]; then
        echo "Error: $SEARCH_SCRIPT not found or not executable"
        exit 1
    fi

    # Check if database is valid
    if ! hoogle search "" --count 1 &>/dev/null; then
        echo "Error: Hoogle database not ready. Run hoogle-init-db.sh first."
        exit 1
    fi
}

# Test: Many results scenario
test_many_results() {
    run_test
    local query="map"
    local output
    output=$("$SEARCH_SCRIPT" "$query" --count 10 2>&1)

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
}

# Test: No results scenario
test_no_results() {
    run_test
    # Use a query that should return no results
    local query="xyzzyNotARealFunction12345"
    local output
    output=$("$SEARCH_SCRIPT" "$query" 2>&1)

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

    # Check results array is empty
    local results_len
    results_len=$(echo "$output" | jq '.results | length')
    if [ "$results_len" -eq 0 ]; then
        pass "No results: empty results array"
    else
        fail "No results: empty array" "0" "$results_len"
    fi
}

# Test: Single result scenario
test_single_result() {
    run_test
    # Use a very specific query that should return exactly 1 result
    local query="Data.List.intersperse"
    local output
    output=$("$SEARCH_SCRIPT" "$query" --count 1 2>&1)

    # Check it's valid JSON
    if ! echo "$output" | jq . &>/dev/null; then
        fail "Single result: valid JSON" "valid JSON" "$output"
        return
    fi

    # Check we got exactly 1 result
    local count
    count=$(echo "$output" | jq '.count')
    if [ "$count" -eq 1 ]; then
        pass "Single result: got exactly 1 result"
    else
        fail "Single result: expected 1" "1" "$count"
    fi
}

# Test: Type signature search
test_type_signature_search() {
    run_test
    local query="a -> b -> a"
    local output
    output=$("$SEARCH_SCRIPT" "$query" --count 5 2>&1)

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

    # Check first result contains 'const' (which has type a -> b -> a)
    local items
    items=$(echo "$output" | jq -r '.results[].item' | head -3)
    if echo "$items" | grep -qi "const"; then
        pass "Type search: found 'const' for 'a -> b -> a'"
    else
        # This might not always be true depending on database
        skip "Type search: const check" "const not in top results (may vary by database)"
    fi
}

# Test: Missing query error
test_missing_query_error() {
    run_test
    local output
    local exit_code=0
    output=$("$SEARCH_SCRIPT" 2>&1) || exit_code=$?

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
    output=$("$SEARCH_SCRIPT" "$query" --count 3 2>&1)

    local count
    count=$(echo "$output" | jq '.count')
    if [ "$count" -le 3 ]; then
        pass "Count parameter: respects --count 3 (got $count)"
    else
        fail "Count parameter: expected <=3" "<=3" "$count"
    fi
}

# Test: Query with special characters
test_special_characters() {
    run_test
    local query="(a -> b) -> [a] -> [b]"
    local output
    output=$("$SEARCH_SCRIPT" "$query" 2>&1)

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

# Test: Package filter
test_package_filter() {
    run_test
    local query="+base map"
    local output
    output=$("$SEARCH_SCRIPT" "$query" --count 5 2>&1)

    # Check it's valid JSON
    if ! echo "$output" | jq . &>/dev/null; then
        fail "Package filter: valid JSON" "valid JSON" "$output"
        return
    fi

    # Check results are from base package
    local packages
    packages=$(echo "$output" | jq -r '.results[].package.name' 2>/dev/null | sort -u)
    if echo "$packages" | grep -q "base"; then
        pass "Package filter: found results from 'base' package"
    else
        fail "Package filter: expected base package" "base" "$packages"
    fi
}

# Main test runner
main() {
    echo "================================"
    echo "Hoogle Search Wrapper Tests"
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
    test_single_result
    test_type_signature_search
    test_missing_query_error
    test_count_parameter
    test_special_characters
    test_package_filter

    echo ""
    echo "================================"
    echo "Results: $TESTS_PASSED/$TESTS_RUN passed, $TESTS_FAILED failed"
    echo "================================"

    if [ $TESTS_FAILED -gt 0 ]; then
        exit 1
    fi
}

main "$@"
