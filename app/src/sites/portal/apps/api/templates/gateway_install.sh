#!/bin/bash

apt-get update
apt-get -y install apache2-utils supervisor jq

SITE_ROOT=/massbit/massbitroute/app/src/sites/services/gateway
mkdir -p $(dirname $SITE_ROOT)

# git clone -b master http://mbr_gateway:6a796299bb72357770735a79019612af228586e7@git.massbitroute.com/massbitroute/ssl.git -b master /etc/letsencrypt

if [ ! -d "$SITE_ROOT" ]; then
	git clone -b master http://mbr_gateway:6a796299bb72357770735a79019612af228586e7@git.massbitroute.com/massbitroute/gateway.git $SITE_ROOT
fi

cd $SITE_ROOT
git pull origin master
bash init.sh
./mbr gw set USER_ID {{user_id}}
./mbr gw set ID {{id}}
./mbr gw set TOKEN {{token}}
./mbr gw set BLOCKCHAIN {{blockchain}}
./mbr gw set NETWORK {{network}}
./mbr gw set SITE_ROOT "$SITE_ROOT"
./mbr gw register
