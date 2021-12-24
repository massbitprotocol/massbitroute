#!/bin/bash

apt-get update
apt-get -y install git apache2-utils supervisor jq


ip="$(curl -ssSfL https://dapi.massbit.io/myip)"

if [ -z "$ip" ]; then
	echo "Your IP is unknown"
	exit 1
fi

zone="$(curl -ssSfL http://api.ipapi.com/api/$ip?access_key=092142b61eed12af33e32fc128295356 | jq .continent_code)"
zone=$(echo $zone | sed 's/\"//g')
if [ -z "$zone" ]; then
	echo "Cannot detect zone from IP $ip"
	exit 1
fi

if [ "$zone" != "{{zone}}" ]; then
	echo "Your IP $ip not in zone {{zone}}"
	exit 1
fi


SITE_ROOT=/massbit/massbitroute/app/src/sites/services/node
mkdir -p $(dirname $SITE_ROOT)

# git clone -b master http://mbr_gateway:6a796299bb72357770735a79019612af228586e7@git.massbitroute.com/massbitroute/ssl.git -b master /etc/letsencrypt

if [ ! -d "$SITE_ROOT" ]; then
	git clone -b master http://mbr_gateway:6a796299bb72357770735a79019612af228586e7@git.massbitroute.com/massbitroute/node.git $SITE_ROOT
fi

cd $SITE_ROOT
git pull origin master
bash init.sh
./mbr node set USER_ID {{user_id}}
./mbr node set ID {{id}}
./mbr node set TOKEN {{token}}
./mbr node set BLOCKCHAIN {{blockchain}}
./mbr node set NETWORK {{network}}
./mbr node set SITE_ROOT "$SITE_ROOT"
./mbr node register
