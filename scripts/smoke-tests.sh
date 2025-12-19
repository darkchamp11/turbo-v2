#!/bin/bash
# ============================================================================
# Distributed Code Execution System - Smoke Tests
# ============================================================================
# Tests all supported languages with various scenarios:
# - Successful execution
# - Compilation errors
# - Runtime errors
# - Time limit exceeded (TLE)
# - Memory limit exceeded (MLE)
# ============================================================================

set -e

MASTER_URL="${MASTER_URL:-http://172.16.7.253:8080}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0

print_header() {
    echo ""
    echo -e "${BLUE}============================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================================================${NC}"
}

print_test() {
    echo -e "${CYAN}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED++))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED++))
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Submit a job and return the job_id
submit_job() {
    local language="$1"
    local source_code="$2"
    local test_cases="$3"
    local time_limit="${4:-2000}"
    local memory_limit="${5:-128}"
    
    local response=$(curl -s -X POST "$MASTER_URL/submit" \
        -H "Content-Type: application/json" \
        -d "{
            \"language\": \"$language\",
            \"source_code\": $source_code,
            \"test_cases\": $test_cases,
            \"time_limit_ms\": $time_limit,
            \"memory_limit_mb\": $memory_limit
        }")
    
    echo "$response"
}

# Check if master is running
check_master() {
    print_header "Checking Master Connection"
    local health=$(curl -s "$MASTER_URL/health" 2>/dev/null || echo "failed")
    if [[ "$health" == *"ok"* ]]; then
        print_pass "Master is running at $MASTER_URL"
        return 0
    else
        print_fail "Cannot connect to Master at $MASTER_URL"
        echo "Please start the master with: cargo run --bin master"
        return 1
    fi
}

# Check if workers are connected
check_workers() {
    print_header "Checking Worker Connections"
    local workers=$(curl -s "$MASTER_URL/workers")
    local count=$(echo "$workers" | grep -o '"id"' | wc -l)
    
    if [[ $count -gt 0 ]]; then
        print_pass "$count worker(s) connected"
        echo "$workers" | python3 -m json.tool 2>/dev/null || echo "$workers"
        return 0
    else
        print_fail "No workers connected"
        echo "Please start a worker with: cargo run --bin worker"
        return 1
    fi
}

# ============================================================================
# Test Cases
# ============================================================================

test_python_success() {
    print_test "Python - Hello World (Success)"
    
    local code='"print(\"Hello World\")"'
    local tests='[{"id": "1", "input": "", "expected_output": "Hello World\n"}]'
    
    local response=$(submit_job "python" "$code" "$tests")
    echo "Response: $response"
    
    if [[ "$response" == *"job_id"* ]]; then
        print_pass "Python Hello World submitted"
    else
        print_fail "Python Hello World failed"
    fi
}

test_python_runtime_error() {
    print_test "Python - Division by Zero (Runtime Error)"
    
    local code='"x = 1 / 0\nprint(x)"'
    local tests='[{"id": "1", "input": "", "expected_output": "error"}]'
    
    local response=$(submit_job "python" "$code" "$tests")
    echo "Response: $response"
    
    if [[ "$response" == *"job_id"* ]]; then
        print_pass "Python runtime error test submitted"
    else
        print_fail "Python runtime error test failed"
    fi
}

test_python_infinite_loop() {
    print_test "Python - Infinite Loop (Time Limit)"
    
    local code='"while True: pass"'
    local tests='[{"id": "1", "input": "", "expected_output": ""}]'
    
    local response=$(submit_job "python" "$code" "$tests" "1000")
    echo "Response: $response"
    
    if [[ "$response" == *"job_id"* ]]; then
        print_pass "Python TLE test submitted"
    else
        print_fail "Python TLE test failed"
    fi
}

test_javascript_success() {
    print_test "JavaScript - Hello World (Success)"
    
    local code='"console.log(\"Hello World\");"'
    local tests='[{"id": "1", "input": "", "expected_output": "Hello World\n"}]'
    
    local response=$(submit_job "javascript" "$code" "$tests")
    echo "Response: $response"
    
    if [[ "$response" == *"job_id"* ]]; then
        print_pass "JavaScript Hello World submitted"
    else
        print_fail "JavaScript Hello World failed"
    fi
}

test_javascript_runtime_error() {
    print_test "JavaScript - Undefined Variable (Runtime Error)"
    
    local code='"console.log(undefinedVariable.property);"'
    local tests='[{"id": "1", "input": "", "expected_output": "error"}]'
    
    local response=$(submit_job "javascript" "$code" "$tests")
    echo "Response: $response"
    
    if [[ "$response" == *"job_id"* ]]; then
        print_pass "JavaScript runtime error test submitted"
    else
        print_fail "JavaScript runtime error test failed"
    fi
}

test_ruby_success() {
    print_test "Ruby - Hello World (Success)"
    
    local code='"puts \"Hello World\""'
    local tests='[{"id": "1", "input": "", "expected_output": "Hello World\n"}]'
    
    local response=$(submit_job "ruby" "$code" "$tests")
    echo "Response: $response"
    
    if [[ "$response" == *"job_id"* ]]; then
        print_pass "Ruby Hello World submitted"
    else
        print_fail "Ruby Hello World failed"
    fi
}

test_c_success() {
    print_test "C - Hello World (Success)"
    
    local code='"#include <stdio.h>\nint main() { printf(\"Hello World\\n\"); return 0; }"'
    local tests='[{"id": "1", "input": "", "expected_output": "Hello World\n"}]'
    
    local response=$(submit_job "c" "$code" "$tests")
    echo "Response: $response"
    
    if [[ "$response" == *"job_id"* ]]; then
        print_pass "C Hello World submitted"
    else
        print_fail "C Hello World failed"
    fi
}

test_c_compile_error() {
    print_test "C - Missing Semicolon (Compilation Error)"
    
    local code='"#include <stdio.h>\nint main() { printf(\"Hello\") return 0; }"'
    local tests='[{"id": "1", "input": "", "expected_output": ""}]'
    
    local response=$(submit_job "c" "$code" "$tests")
    echo "Response: $response"
    
    if [[ "$response" == *"job_id"* ]]; then
        print_pass "C compile error test submitted"
    else
        print_fail "C compile error test failed"
    fi
}

test_c_segfault() {
    print_test "C - Segmentation Fault (Runtime Error)"
    
    local code='"#include <stdio.h>\nint main() { int *p = 0; *p = 42; return 0; }"'
    local tests='[{"id": "1", "input": "", "expected_output": ""}]'
    
    local response=$(submit_job "c" "$code" "$tests")
    echo "Response: $response"
    
    if [[ "$response" == *"job_id"* ]]; then
        print_pass "C segfault test submitted"
    else
        print_fail "C segfault test failed"
    fi
}

test_cpp_success() {
    print_test "C++ - Hello World (Success)"
    
    local code='"#include <iostream>\nint main() { std::cout << \"Hello World\" << std::endl; return 0; }"'
    local tests='[{"id": "1", "input": "", "expected_output": "Hello World\n"}]'
    
    local response=$(submit_job "cpp" "$code" "$tests")
    echo "Response: $response"
    
    if [[ "$response" == *"job_id"* ]]; then
        print_pass "C++ Hello World submitted"
    else
        print_fail "C++ Hello World failed"
    fi
}

test_cpp_compile_error() {
    print_test "C++ - Undefined Function (Compilation Error)"
    
    local code='"#include <iostream>\nint main() { undefinedFunction(); return 0; }"'
    local tests='[{"id": "1", "input": "", "expected_output": ""}]'
    
    local response=$(submit_job "cpp" "$code" "$tests")
    echo "Response: $response"
    
    if [[ "$response" == *"job_id"* ]]; then
        print_pass "C++ compile error test submitted"
    else
        print_fail "C++ compile error test failed"
    fi
}

test_rust_success() {
    print_test "Rust - Hello World (Success)"
    
    local code='"fn main() { println!(\"Hello World\"); }"'
    local tests='[{"id": "1", "input": "", "expected_output": "Hello World\n"}]'
    
    local response=$(submit_job "rust" "$code" "$tests")
    echo "Response: $response"
    
    if [[ "$response" == *"job_id"* ]]; then
        print_pass "Rust Hello World submitted"
    else
        print_fail "Rust Hello World failed"
    fi
}

test_rust_compile_error() {
    print_test "Rust - Missing Macro (Compilation Error)"
    
    local code='"fn main() { printlnn!(\"Hello\"); }"'
    local tests='[{"id": "1", "input": "", "expected_output": ""}]'
    
    local response=$(submit_job "rust" "$code" "$tests")
    echo "Response: $response"
    
    if [[ "$response" == *"job_id"* ]]; then
        print_pass "Rust compile error test submitted"
    else
        print_fail "Rust compile error test failed"
    fi
}

test_rust_panic() {
    print_test "Rust - Panic (Runtime Error)"
    
    local code='"fn main() { panic!(\"This is a panic!\"); }"'
    local tests='[{"id": "1", "input": "", "expected_output": ""}]'
    
    local response=$(submit_job "rust" "$code" "$tests")
    echo "Response: $response"
    
    if [[ "$response" == *"job_id"* ]]; then
        print_pass "Rust panic test submitted"
    else
        print_fail "Rust panic test failed"
    fi
}

test_go_success() {
    print_test "Go - Hello World (Success)"
    
    local code='"package main\nimport \"fmt\"\nfunc main() { fmt.Println(\"Hello World\") }"'
    local tests='[{"id": "1", "input": "", "expected_output": "Hello World\n"}]'
    
    local response=$(submit_job "go" "$code" "$tests")
    echo "Response: $response"
    
    if [[ "$response" == *"job_id"* ]]; then
        print_pass "Go Hello World submitted"
    else
        print_fail "Go Hello World failed"
    fi
}

test_go_compile_error() {
    print_test "Go - Missing Import (Compilation Error)"
    
    local code='"package main\nfunc main() { fmt.Println(\"Hello\") }"'
    local tests='[{"id": "1", "input": "", "expected_output": ""}]'
    
    local response=$(submit_job "go" "$code" "$tests")
    echo "Response: $response"
    
    if [[ "$response" == *"job_id"* ]]; then
        print_pass "Go compile error test submitted"
    else
        print_fail "Go compile error test failed"
    fi
}

test_java_success() {
    print_test "Java - Hello World (Success)"
    
    local code='"public class Main { public static void main(String[] args) { System.out.println(\"Hello World\"); } }"'
    local tests='[{"id": "1", "input": "", "expected_output": "Hello World\n"}]'
    
    local response=$(submit_job "java" "$code" "$tests")
    echo "Response: $response"
    
    if [[ "$response" == *"job_id"* ]]; then
        print_pass "Java Hello World submitted"
    else
        print_fail "Java Hello World failed"
    fi
}

test_java_compile_error() {
    print_test "Java - Missing Semicolon (Compilation Error)"
    
    local code='"public class Main { public static void main(String[] args) { System.out.println(\"Hello\") } }"'
    local tests='[{"id": "1", "input": "", "expected_output": ""}]'
    
    local response=$(submit_job "java" "$code" "$tests")
    echo "Response: $response"
    
    if [[ "$response" == *"job_id"* ]]; then
        print_pass "Java compile error test submitted"
    else
        print_fail "Java compile error test failed"
    fi
}

test_java_null_pointer() {
    print_test "Java - Null Pointer Exception (Runtime Error)"
    
    local code='"public class Main { public static void main(String[] args) { String s = null; System.out.println(s.length()); } }"'
    local tests='[{"id": "1", "input": "", "expected_output": ""}]'
    
    local response=$(submit_job "java" "$code" "$tests")
    echo "Response: $response"
    
    if [[ "$response" == *"job_id"* ]]; then
        print_pass "Java NPE test submitted"
    else
        print_fail "Java NPE test failed"
    fi
}

test_memory_limit() {
    print_test "Python - Large Array (Memory Limit)"
    
    # Try to allocate a very large list
    local code='"x = [1] * (1024 * 1024 * 200)\nprint(len(x))"'
    local tests='[{"id": "1", "input": "", "expected_output": ""}]'
    
    local response=$(submit_job "python" "$code" "$tests" "5000" "64")
    echo "Response: $response"
    
    if [[ "$response" == *"job_id"* ]]; then
        print_pass "Memory limit test submitted"
    else
        print_fail "Memory limit test failed"
    fi
}

test_multiple_test_cases() {
    print_test "Python - Multiple Test Cases"
    
    local code='"import sys\nfor line in sys.stdin:\n    n = int(line.strip())\n    print(n * 2)"'
    local tests='[
        {"id": "1", "input": "5", "expected_output": "10\n"},
        {"id": "2", "input": "10", "expected_output": "20\n"},
        {"id": "3", "input": "100", "expected_output": "200\n"}
    ]'
    
    local response=$(submit_job "python" "$code" "$tests")
    echo "Response: $response"
    
    if [[ "$response" == *"job_id"* ]]; then
        print_pass "Multiple test cases submitted"
    else
        print_fail "Multiple test cases failed"
    fi
}

# ============================================================================
# Main Test Runner
# ============================================================================

print_header "SMOKE TESTS - Distributed Code Execution System"
echo "Master URL: $MASTER_URL"
echo "Time: $(date)"

# Connection checks
if ! check_master; then
    exit 1
fi

if ! check_workers; then
    exit 1
fi

# Run all tests
print_header "INTERPRETED LANGUAGES"

echo ""
echo -e "${YELLOW}--- Python Tests ---${NC}"
test_python_success
test_python_runtime_error
test_python_infinite_loop

echo ""
echo -e "${YELLOW}--- JavaScript Tests ---${NC}"
test_javascript_success
test_javascript_runtime_error

echo ""
echo -e "${YELLOW}--- Ruby Tests ---${NC}"
test_ruby_success

print_header "COMPILED LANGUAGES"

echo ""
echo -e "${YELLOW}--- C Tests ---${NC}"
test_c_success
test_c_compile_error
test_c_segfault

echo ""
echo -e "${YELLOW}--- C++ Tests ---${NC}"
test_cpp_success
test_cpp_compile_error

echo ""
echo -e "${YELLOW}--- Rust Tests ---${NC}"
test_rust_success
test_rust_compile_error
test_rust_panic

echo ""
echo -e "${YELLOW}--- Go Tests ---${NC}"
test_go_success
test_go_compile_error

echo ""
echo -e "${YELLOW}--- Java Tests ---${NC}"
test_java_success
test_java_compile_error
test_java_null_pointer

print_header "RESOURCE LIMIT TESTS"

echo ""
echo -e "${YELLOW}--- Memory Limit ---${NC}"
test_memory_limit

print_header "BATCH TESTS"

echo ""
echo -e "${YELLOW}--- Multiple Test Cases ---${NC}"
test_multiple_test_cases

# Summary
print_header "TEST SUMMARY"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo ""

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests submitted successfully!${NC}"
    echo ""
    echo "Note: Tests are SUBMITTED, not yet EXECUTED."
    echo "Check job status with: curl $MASTER_URL/status/<job_id>"
else
    echo -e "${RED}Some tests failed to submit.${NC}"
    exit 1
fi
