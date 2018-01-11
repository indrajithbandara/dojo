#!/bin/bash
TARGET="$2"
BATS_TEST_SKIPPED=
SCRIPT_DIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"
. "${SCRIPT_DIR}/lib/stub4bats.sh/stub.sh"
. "${SCRIPT_DIR}/../${TARGET}"

