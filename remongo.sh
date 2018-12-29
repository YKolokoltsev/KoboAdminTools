#!/bin/bash

# exit on first error
set -e

# can fail in the case of simlinks
ADMIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${ADMIN_DIR}/functions.sh

# all components shell be running, checking
if ! koboadm_check_components_up ${ALL_ARR[@]}; then exit 1; fi

echo -e "${RED}WARNING: you are about to overwrite the main MONGO databse,${NC}"
echo -e "${RED}         are you sure you made the most recent backup before? (y/n)${NC}"

read answer
if [ "$answer" == "${answer#[Yy]}" ]; then exit 0; fi

# stop server to the outside world
koboadm_stop_components "${SRV}"

echo "Running remongo from kobocat..."
CNAME=`koboadm_cname kobocat`
docker exec -it ${CNAME} python manage.py remongo

echo ""
echo "********************************"
echo "done"
docker-compose ps

