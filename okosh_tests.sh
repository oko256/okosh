#!/usr/bin/env test.sh

. ./okosh.bash
TEST_FILE="/tmp/okosh_tests"

setup() {
    # Check the prerequisites for running the tests.
    if ! command -v bc &> /dev/null
    then
        echo "FATAL ERROR: Tests require 'bc' to be installed."
        exit 1
    fi
    if ! command -v xxd &> /dev/null
    then
        echo "FATAL ERROR: Tests require 'xxd' to be installed."
        exit 1
    fi
}

teardown() {
    rm -f "$TEST_FILE"
}

# okosh_log() #####################################################################################

test_okosh_log() {
    # Test that normal logging works and by default we are verbose.
    okosh_log "test_okosh_log" "test1" 2> "$TEST_FILE"
    assert_file_content "$TEST_FILE" "test_okosh_log(): test1"
    # Clear the file and test that logs are not written when we are being quiet.
    echo "" > "$TEST_FILE"
    okosh_quiet
    okosh_log "test_okosh_log" "test2" 2> "$TEST_FILE"
    assert_file_content "$TEST_FILE" ""
    # And try being verbose again to check that function too.
    echo "" > "$TEST_FILE"
    okosh_verbose
    okosh_log "test_okosh_log" "test3" 2> "$TEST_FILE"
    assert_file_content "$TEST_FILE" "test_okosh_log(): test3"
}

# okosh_contains() ################################################################################

test_okosh_contains() {
    assert_returns 1 okosh_contains "aabbcc" "d"
    assert_returns 0 okosh_contains "aabbcc" "a"
    assert_returns 0 okosh_contains "aabbcc" "b"
    assert_returns 0 okosh_contains "aabbcc" "c"
    assert_returns 0 okosh_contains "aabbcc" "ab"
    assert_returns 0 okosh_contains "aabbcc" "cc"
    assert_returns 1 okosh_contains "aabbcc" "ba"
    assert_returns 0 okosh_contains "aabbcc" ""
    assert_returns 0 okosh_contains "" ""
    assert_returns 1 okosh_contains "" "a"
}

# okosh_retry() ###################################################################################

okosh_retry_test_helper_iter=0
okosh_retry_test_helper() {
    local succeed_at_iter="$1"
    okosh_retry_test_helper_iter=$((okosh_retry_test_helper_iter + 1))
    [ "$okosh_retry_test_helper_iter" -eq "$succeed_at_iter" ] && return 0
    return 42
}

test_okosh_retry() {
    # Do some retries and check that the accumulated sleep duration is realistic.
    okosh_retry_test_helper_iter=0
    local start_time end_time expected_time time_diff
    start_time=$(date +%s.%N)
    assert_returns 0 okosh_retry 5 0.1 okosh_retry_test_helper 4
    end_time=$(date +%s.%N)
    expected_time="0.3"
    time_diff=$(echo "define abs(i) { if (i < 0) return (-i); return (i); } abs(($end_time - $start_time - $expected_time) * 1000)" | bc)
    time_diff=${time_diff/\.*/}
    if [ "$time_diff" -gt 30 ] || [ "$time_diff" -lt 5 ]
    then
        die "assert: okosh_retry() duration was unrealistic"
    fi
    # Check failing retries.
    okosh_retry_test_helper_iter=0
    assert_returns 42 okosh_retry 5 0.1 okosh_retry_test_helper 10
    assert_equal 5 "$okosh_retry_test_helper_iter"
}

# okosh_red_stderr() ##############################################################################

okosh_red_stderr_helper() {
    >&2 echo "stderr"
    echo "stdout"
}

test_okosh_red_stderr() {
    local stderr_output
    stderr_output=$({ okosh_red_stderr okosh_red_stderr_helper > "$TEST_FILE"; } 2>&1)
    stderr_output=$(echo "$stderr_output" | xxd -p)
    assert_equal "1b5b33316d7374646572721b5b6d0a" "$stderr_output"
}
