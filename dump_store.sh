#!/bin/bash

# exit on first error
set -e

# can fail in the case of simlinks
ADMIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${ADMIN_DIR}/functions.sh

# if databases are not running, there is nothing to dump
if ! koboadm_check_components_up "${DATABASES_ARR[@]}"; then exit 1; fi

# the cobocat backup script require the cobocat container running
echo "**********************************************"
echo "Stopping server to the outside world and archiving user media:"
koboadm_stop_components "${SRV}"
sleep 5
docker exec -it kobodocker_kobocat_1 /srv/src/kobocat/docker/backup_media.bash

# stop all frontend containers to disconnect them from databases
# this would guarantee the dump consistency
echo "**********************************************"
echo "Stopping all frontend containers to liberate databases:"
koboadm_stop_components "${FRONTEND_ARR[@]}"

# not critical but desired verification
echo "**********************************************"
echo "Verify exit codes for the frontend containers (all shell be 0):"
docker-compose ps

# dump the databases
echo "**********************************************"
echo "Creating mongo and postgres backups"

docker exec -it kobodocker_mongo_1 /srv/backup_mongo.bash
docker exec -it kobodocker_postgres_1 /srv/backup_postgres.bash

# full server restart
echo "**********************************************"
echo "Full restart of the server..."
docker-compose down
docker-compose up -d

# instructions
echo "**********************************************"
echo -e "${YELLOW}Checklist:${NC}"
echo -e "${YELLOW} 1. Verify ${KOBO_SERVER_ROOT_DIR}/backups subfolders for new backup files.${NC}"
echo -e "${YELLOW} 2. Check that postgres backup has it's size >1Mb.${NC}"
echo -e "${YELLOW} 3. Before migrate this dump to remote Kobo server, first use${NC}"
echo -e "${YELLOW}    import_pgdb.sh and apply pgquarrel test on the remote machine.${NC}"
