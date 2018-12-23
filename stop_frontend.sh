#!/bin/bash

# exit on first error
set -e

# can fail in the case of simlinks
ADMIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${ADMIN_DIR}/functions.sh

# stop all frontend containers to disconnect them from databases
# this would guarantee the dump consistency
echo "**********************************************"
echo "Stopping all frontend containers:"
koboadm_stop_components "${SRV}"
koboadm_stop_components "${FRONTEND_ARR[@]}"
