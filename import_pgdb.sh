#!/bin/bash

# import the given postgres dump into the new database with the given name

# exit on first error
set -e

# can fail in the case of simlinks
ADMIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${ADMIN_DIR}/functions.sh

# check that postgres component is running
if ! koboadm_check_components_up "postgres"; then exit 1; fi

if [ "$#" -ne 2 ]
then
    echo "Usage:"
    echo "import_postgres_dump.sh <new_db_name> <backup_file>"
    echo
    echo "<new_db_name> - name of the new database where a backup will be imported"
    echo "                if this databse already exists, the script will just exit"
    echo "<backup_file> - name of the compressed postgres backup file, that was"
    echo "                obtained using dump_running_server.sh script and was placed"
    echo "                into the ${KOBO_SERVER_ROOT_DIR}/backups/postgres/"
    
    echo
    echo
    echo ">>> Databases:"
    QUERY="SELECT datname FROM pg_database WHERE datistemplate = FALSE;"
    koboadm_send_psql_query "$QUERY"
    
    echo
    echo
    echo ">>> Backups:"
    docker exec -it kobodocker_postgres_1 bash -c "ls /srv/backups/"
    
    exit 0
fi

# check database dump argument
DUMP=${2}

if docker exec -it kobodocker_postgres_1 \
bash -c " if [ -f /srv/backups/${DUMP} ]; then exit 1; else exit 0; fi "
then
    echo "The dump file '${DUMP}' is not present in the /srv/backups/"
    echo "The next dumps are accessible: "
    docker exec -it kobodocker_postgres_1 bash -c "ls /srv/backups/"
    exit 0
else
    echo "Found:"
    docker exec -it kobodocker_postgres_1 \
    bash -c "ls -alh /srv/backups/${DUMP}"
    echo
fi

# check if database already exist
DBNAME=${1}

if docker exec -it kobodocker_postgres_1 \
bash -c "psql --user=postgres -d ${DBNAME} --single-transaction --command=\"\"" 1> /dev/null
then
    if [ "${DBNAME}" == "kobotoolbox" ]; then echo -e "${RED}WARNING: you are about to replace the main KoboToolbox database!${NC}"; fi
    echo -e "${RED}The database '${DBNAME}' already exist, would you like to recreate it (y/n)?${NC}"
    read answer
    if [ "$answer" != "${answer#[Yy]}" ]
    then
      QUERY="DROP DATABASE ${DBNAME};"
      koboadm_send_psql_query "$QUERY"
    else
      exit 0  
    fi
fi
echo

# create new database
QUERY="CREATE DATABASE ${DBNAME} OWNER kobo;"
koboadm_send_psql_query "$QUERY"

# import backup into the new database
docker exec -it kobodocker_postgres_1 \
bash -c "pg_restore --verbose --no-acl --no-owner -U kobo -d $DBNAME /srv/backups/${DUMP}"
