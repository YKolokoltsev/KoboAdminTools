#!/bin/bash

# 3. Check permissions and ownerships

# TODO: check what to do with old mongo_db (more than backup?)

#!/bin/bash

# exit on first error
set -e

# can fail in the case of simlinks
ADMIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${ADMIN_DIR}/functions.sh

# all components shell be runnung except of SRV
if ! koboadm_check_components_up "${FRONTEND_ARR[@]}"; then exit 1; fi
if ! koboadm_check_components_up "${DATABASES_ARR[@]}"; then exit 1; fi

echo -e "${RED}WARNING: you are about to replace ALL KoboToolbox valuable data,${NC}"
echo -e "${RED}         are you sure you made the most recent backup before? (y/n)${NC}"

read answer
if [ "$answer" == "${answer#[Yy]}" ]; then exit 0; fi  

# select user-media backup archive 
echo -e "Enter ${YELLOW}USER-MEDIA${NC} kobocat filename from the list below:"
koboadm_ls kobocat "/srv/backups"
echo ">"
read ARCH_KOBOCAT
ARCH_KOBOCAT="/srv/backups/${ARCH_KOBOCAT}"
if ! koboadm_check_container_file kobocat "${ARCH_KOBOCAT}"; then exit 0; fi
echo

# select mongo backup archive
echo -e "Enter ${YELLOW}MONGO${NC} backup filename from the lis below:"
koboadm_ls mongo "/srv/backups"
echo ">"
read ARCH_MONGO
ARCH_MONGO="/srv/backups/${ARCH_MONGO}"
if ! koboadm_check_container_file mongo "${ARCH_MONGO}"; then exit 0; fi
echo

# sekect postgres backup archive
echo -e "Enter ${YELLOW}POSTGRES${NC} backup filename from the list below:"
koboadm_ls postgres "/srv/backups"
echo ">"
read ARCH_POSTGRES
ARCH_POSTGRES="/srv/backups/${ARCH_POSTGRES}"
if ! koboadm_check_container_file postgres "${ARCH_POSTGRES}"; then exit 0; fi
echo

echo "*******************"
echo "You selected the next backup archives:"
CNAME=`koboadm_cname kobocat`
docker exec -it ${CNAME} bash -c "ls -alh ${ARCH_KOBOCAT}"
CNAME=`koboadm_cname mongo`
docker exec -it ${CNAME} bash -c "ls -alh ${ARCH_MONGO}"
CNAME=`koboadm_cname postgres`
docker exec -it ${CNAME} bash -c "ls -alh ${ARCH_POSTGRES}"
echo
echo -e "${YELLOW}Are you sure these archives belong to the same backup and are consistent?(y/n)${NC}"
read answer
if [ "$answer" == "${answer#[Yy]}" ]; then exit 0; fi

echo "Deploying backup..."

# check for kobotoolbox_old before any deployment

CNAME=`koboadm_cname postgres`
if docker exec -it ${CNAME} \
bash -c "psql --user=postgres -d kobotoolbox_old --single-transaction --command=\"\"" 1> /dev/null
then
    echo -e "${RED}The database kobotoolbox_old already exist, would you like to drop it (y/n)?${NC}"
    read answer
    if [ "$answer" != "${answer#[Yy]}" ]
    then
      QUERY="DROP DATABASE kobotoolbox_old;"
      koboadm_send_psql_query "$QUERY"
    else
      echo "nothing was not modifyed yet, exit"
      exit 0
    fi
fi
echo

# user-media
echo "*******************************"
echo "DEPLOY USER-MEDIA"

koboadm_stop_components "${SRV}"

CNAME=`koboadm_cname kobocat`
docker exec ${CNAME} bash -c "tar xvpf ${ARCH_KOBOCAT} --directory=/srv/src/kobocat/media media"

# postgres (move current database to kobotoolbox_old)
echo "*******************************"
echo "DEPLOY POSTGRES"

koboadm_stop_components "${FRONTEND_ARR[@]}"

QUERY="CREATE DATABASE kobotoolbox_old WITH TEMPLATE kobotoolbox OWNER kobo;"
koboadm_send_psql_query "$QUERY"

docker exec -it ${CNAME} \
bash -c "pg_restore --verbose --clean --no-acl --no-owner -h localhost -U kobo -d kobotoolbox ${ARCH_POSTGRES}"

# mongo
echo "*******************************"
echo "DEPLOY MONGO"

CNAME=`koboadm_cname mongo`

docker exec -it ${CNAME} \
bash -c "mkdir /srv/backups/restore_tmp"

docker exec -it ${CNAME} \
bash -c "tar xfvz ${ARCH_MONGO} --directory=/srv/backups/restore_tmp"

docker exec -it ${CNAME} \
bash -c "cd /srv/backups/restore_tmp && mongorestore"

docker exec -it ${CNAME} \
bash -c "rm -rv /srv/backups/restore_tmp"

# instructions
echo "**********************************************"
echo -e "${YELLOW}Checklist:${NC}"
echo -e "${YELLOW} 1. Run pgquarrel for kobotoolbox/kobotoolbox_old pair${NC}"
echo -e "${YELLOW} 2. Check user-media owner and group.${NC}"
echo -e "${YELLOW} 3. Rename kobotoolbox_old manually if something goes wrong"
