#!/bin/bash

set -e

# can fail in the case of simlinks
ADMIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${ADMIN_DIR}/functions.sh

echo "CONTAINER INTERFACE IPV4" > /tmp/lkj5l4kj6.txt

for CNAME in $(docker ps --format '{{.Names}}')
do
    IPV4=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CNAME`
    IFLINK=`docker exec -it $CNAME bash -c 'cat /sys/class/net/eth*/iflink'`
    for NET in $IFLINK
    do
        NET=`echo $NET|tr -d '\r'`
        VETH=`grep -l $NET /sys/class/net/veth*/ifindex`
        VETH=`echo $VETH|sed -e 's;^.*net/\(.*\)/ifindex$;\1;'`
        echo "$CNAME $VETH $IPV4" >> /tmp/lkj5l4kj6.txt
        printf "."
    done
done

echo
column -t -s' ' /tmp/lkj5l4kj6.txt
rm /tmp/lkj5l4kj6.txt
