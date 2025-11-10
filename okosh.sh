#!/bin/sh

###################################################################################################
# OKOSH - Collection of General Purpose Shell Utilities
#
# This script contains the basic set of functions that should work in pretty much any shell.
#
# https://github.com/oko256/okosh
# SPDX-License-Identifier: MIT
###################################################################################################

# Most shells (bash, ksh, dash, busybox ash, ...) support "local" keyword, so even though it's
# not POSIX feature, we disable that check and assume that it exists.
# shellcheck disable=SC3043

OKOSH_QUIET=false

okosh_quiet() {
    OKOSH_QUIET=true
}
okosh_verbose() {
    OKOSH_QUIET=false
}

okosh_log() {
    if [ "$OKOSH_QUIET" = false ]
    then
        local func="$1"
        local msg="$2"
        >&2 echo "${func}(): ${msg}"
    fi
}

okosh_contains() {
    if [ "$#" -ne 2 ]
    then
        okosh_log "okosh_contains" "Usage: okosh_contains <string> <substring>"
        okosh_log "okosh_contains" "Returns 0 if <string> contains <substring>, otherwise 1."
        return 1
    fi
    local str="$1"
    local substr="$2"
    [ -z "$substr" ] && return 0 # Edge case: Empty substring exists in whatever string.
    [ "${str#*"$substr"}" != "$str" ] && return 0
    return 1
}

okosh_retry() {
    if [ "$#" -lt 3 ]
    then
        okosh_log "okosh_retry" "Usage: okosh_retry <retries> <sleep> <command...>"
        okosh_log "okosh_retry" "Attempts to run <command...> until it succeeds (exit is 0)."
        okosh_log "okosh_retry" "Tries at most <retries> times and waits <sleep> seconds between retries."
        okosh_log "okosh_retry" "Returns 0 on success, and the last exit code from <command...> on failure."
        return 1
    fi
    local retries="$1"
    local sleep="$2"
    shift 2
    local options="$-" # Save current shell set options.

    okosh_log "okosh_retry" "Trying $retries times with $sleep s delay in-between to run: $*"

    while [ "$retries" -gt 0 ]
    do
        # Temporarily disable "set -e" if enabled.
        if okosh_contains "$options" "e"
        then
            set +e
        fi

        okosh_log "okosh_retry" "Running: $*"
        "$@"
        local exit_code=$?

        # Re-enable "set -e" if it was enabled before.
        if okosh_contains "$options" "e"
        then
            set -e
        fi

        if [ "$exit_code" -eq 0 ]
        then
            okosh_log "okosh_retry" "Success"
            return 0
        else
            okosh_log "okosh_retry" "Failed with exit code $exit_code"
            retries=$((retries - 1))
            if [ "$retries" -gt 0 ] && [ -n "$sleep" ]
            then
                sleep "$sleep"
            fi
        fi
    done

    okosh_log "okosh_retry" "Failed with no retries left"
    return "$exit_code"
}

