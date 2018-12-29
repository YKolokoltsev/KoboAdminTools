#!/bin/bash

# exit on first error
set -e

# can fail in the case of simlinks
ADMIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${ADMIN_DIR}/functions.sh

# the kobocat shell be running
if ! koboadm_check_components_up "kobocat"; then exit 1; fi

echo -e "${RED}WARNING: you are about to overwrite the KoboToolbox USER-MEDIA data,${NC}"
echo -e "${RED}         are you sure you made the most recent backup before? (y/n)${NC}"

read answer
if [ "$answer" == "${answer#[Yy]}" ]; then exit 0; fi

# select user-media backup archive 
echo "Enter user-media kobocat filename from the list below:"
koboadm_ls kobocat "/srv/backups"
echo ">"
read ARCH_KOBOCAT
ARCH_KOBOCAT="/srv/backups/${ARCH_KOBOCAT}"
if ! koboadm_check_container_file kobocat "${ARCH_KOBOCAT}"; then exit 0; fi
echo

# deploy user media
echo "Deploying..."
RESTART_SRV="0"
if koboadm_check_components_up "${SRV}"
then
  RESTART_SRV="1"
  koboadm_stop_components "${SRV}"
fi

CNAME=`koboadm_cname kobocat`
docker exec ${CNAME} bash -c "tar xvpf ${ARCH_KOBOCAT} --directory=/srv/src/kobocat/media media"

if [ "${RESTART_SRV}" == "1" ]
then
  docker-compose start ${SRV}
fi

echo "done"
echo
echo -e "${YELLOW}Check that media-files ownership is correct:${NC}"

echo -e "${YELLOW}UWSGI_USER =" \
$(docker exec ${CNAME} bash -c "printenv UWSGI_USER") "${NC}"

echo -e "${YELLOW}UWSGI_GROUP =" \
$(docker exec ${CNAME} bash -c "printenv UWSGI_GROUP") "${NC}"
