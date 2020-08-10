#!/usr/bin/env bash

set -o pipefail
set -o nounset
set -o errexit

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

export PROJECT_DIR="${SCRIPT_DIR}/.."

$SCRIPT_DIR/configure-product $1 pivotal-mysql $2

