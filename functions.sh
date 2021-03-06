# gate to the outside world
SRV="nginx"

# an ordered array of the frontend containers 
# the order is significant because of dependency between them
# check 'links:' sections in the current docker-compose.yml file
declare -a FRONTEND_ARR=("kobocat" "kpi" "enketo_express" "rabbit")

# list of the backend databases
# these database servers work independently from each other
declare -a DATABASES_ARR=("postgres" "mongo" "redis_main" "redis_cache")

# all KoboToolbox components
declare -a ALL_ARR=("${SRV}" "${FRONTEND_ARR[@]}" "${DATABASES_ARR[@]}")

# color text output constants
# usage example:
# echo -e "${RED} red${NC}"
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# check for the KOBO_SERVER_ROOT_DIR environment variable
export KOBO_SERVER_ROOT_DIR=`readlink -f kobo-server.lnk`
koboadm_check_server_root(){
    if [ ! -f "${KOBO_SERVER_ROOT_DIR}/docker-compose.yml" ] && [ ! -f "${KOBO_SERVER_ROOT_DIR}/docker-compose.yaml" ]
    then 
        echo "KOBO_SERVER_ROOT_DIR environment variable is not defined"
        echo "or the KoboToolbox is not configured, exit."
        return 1
    else 
        return 0
    fi
}

# the KOBO_SERVER_ROOT_DIR environment variable shell be defined
if ! koboadm_check_server_root; then exit 1; fi
cd "${KOBO_SERVER_ROOT_DIR}"

echo
echo "KoboToolboxAdmin functions loaded"
echo -e "KOBO_SERVER_ROOT_DIR = ${YELLOW}${KOBO_SERVER_ROOT_DIR}${NC}"
echo

# check that each server component is running
# report all not running components and return 0 if at least 
# one component is not running
koboadm_check_components_up(){
    
    local let ret=0
    local COMPONENTS_ARR=("$@")
    
    if [ -z "$(docker-compose top)" ]
    then
        echo "The Kobo server is not running at all"
        return 1
    else
        for COMPONENT in "${COMPONENTS_ARR[@]}"
        do
            if [ -z "$(docker-compose top $COMPONENT)" ]
            then
                echo "$COMPONENT component is not running"
                let ret=1
            fi
        done
    fi
    
    return $ret
}

# stop selected components
koboadm_stop_components(){
    local COMPONENTS_ARR=("$@")
    
    for COMPONENT in "${COMPONENTS_ARR[@]}"
    do
        if [ ! -z "$(docker-compose top $COMPONENT)" ]
        then
            docker-compose stop "$COMPONENT"
        else
            echo "WARNING: the $COMPONENT container was not running"
        fi
    done
}

# find real component name
koboadm_cname(){
    docker-compose ps | grep ${1} | awk '{ print $1 }'
}

# send postgres query
koboadm_send_psql_query(){
    CNAME=`koboadm_cname postgres`
    local QUERY="$@"
    docker exec -it ${CNAME} \
    bash -c "psql --user postgres -P pager=off --single-transaction --command=\"$QUERY\""
}

# check if the file given by second parameter is reachable 
# on the container (first parameter)
koboadm_check_container_file(){
    CNAME=`koboadm_cname ${1}`
    FILE_PATH="${2}"
    if docker exec -it ${CNAME} bash -c "[ ! -f \"${FILE_PATH}\" ]"
    then
        echo "File ${FILE_PATH} is not accessible on the ${CNAME} container"
        return 1
    fi
    return 0
}

# list files that are stored in the specified container folder
koboadm_ls(){
    CNAME=`koboadm_cname ${1}`
    FOLDER_PATH="${2}"
    if docker exec -it ${CNAME} bash -c "[ ! -d \"${FOLDER_PATH}\" ]"
    then
        echo "Folder ${FOLDER_PATH} not present in container ${CNAME}"
        return 1
    else
        docker exec -it ${CNAME} bash -c "ls -alh /srv/backups"
    fi
    return 0
}
