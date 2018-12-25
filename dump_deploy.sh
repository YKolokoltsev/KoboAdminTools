#!/bin/bash

# 1. Do not forget to move old postgres db scheme to within database
# 2. Say that before dump deploy it is good to invoke dump_store.sh first
# 3. Notify to run pgquarrel_test

# 1. Show available dump files in user dialog
# 2. Check mongo recover variant
# 3. Check permissions and ownerships

# TODO: check what to do with old mongo_db (more than backup?)
# TDDO: say ask about previous dump

#!/bin/bash

# exit on first error
set -e

# can fail in the case of simlinks
ADMIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${ADMIN_DIR}/functions.sh

# both frontend and database containers shell be running
#if ! koboadm_check_components_up "${FRONTEND_ARR[@]}"; then exit 1; fi
#if ! koboadm_check_components_up "${DATABASES_ARR[@]}"; then exit 1; fi

echo -e "${RED}WARNING: you are about to replace all KoboToolbox valuable data,${NC}"
echo -e "${RED}         are you sure you made the most recent dump before? (y/n)${NC}"

read answer
if [ "$answer" == "${answer#[Yy]}" ]; then exit 0; fi  

# select user-media backup archive 
echo "Enter user-media kobocat filename from the list:"
CNAME=`koboadm_cname kobocat`
docker exec -it ${CNAME} bash -c "ls -alh /srv/backups"
echo ">"
read ARCH_KOBOCAT
ARCH_KOBOCAT="/srv/backups/${ARCH_KOBOCAT}"
if ! koboadm_check_container_file "${CNAME}" "${ARCH_KOBOCAT}"; then exit 0; fi
echo

# select mongo backup archive
echo "Enter mongo backup filename from the list:"
CNAME=`koboadm_cname mongo`
docker exec -it ${CNAME} bash -c "ls -alh /srv/backups"
echo ">"
read ARCH_MONGO
ARCH_MONGO="/srv/backups/${ARCH_MONGO}"
if ! koboadm_check_container_file "${CNAME}" "${ARCH_MONGO}"; then exit 0; fi
echo

# sekect postgres backup archive
echo "Enter postgres backup filename from the list:"
CNAME=`koboadm_cname postgres`
docker exec -it ${CNAME} bash -c "ls -alh /srv/backups"
echo ">"
read ARCH_POSTGRES
ARCH_POSTGRES="/srv/backups/${ARCH_POSTGRES}"
if ! koboadm_check_container_file "${CNAME}" "${ARCH_POSTGRES}"; then exit 0; fi
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

#do not forget to set current user/group for extracted media
#docker exec -it kobo-docker_kobocat_1 bash -c "printenv UWSGI_USER"
#docker exec -it kobo-docker_kobocat_1 bash -c "printenv UWSGI_GROUP"
