#!/bin/bash

###################################################################################################
# OKOSH - Collection of General Purpose Shell Utilities
#
# This script includes some functions that use bashisms and are not as closely POSIX as the
# basic set in `okosh.sh`. Sourcing this file also sources the basic set from the same directory.
#
# https://github.com/oko256/okosh
# SPDX-License-Identifier: MIT
###################################################################################################

OKOSH_SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "$OKOSH_SCRIPT_DIR/okosh.sh"

# okosh_red_stderr() ##############################################################################

okosh_red_stderr() {
    if [ "$#" -lt 1 ]
    then
        okosh_log "okosh_red_stderr" "Usage: okosh_red_stderr <command...>"
        okosh_log "okosh_red_stderr" "Runs <command...> and colors all output to stderr in red."
        return 1
    fi
    (
        set -o pipefail
        "$@" 2> >(sed $'s,.*,\e[31m&\e[m,'>&2)
    )
}
