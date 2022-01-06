#!/bin/bash

_debian() {
	apt-get update
	apt-get install -y git apache2-utils supervisor jq python2

}
_ubuntu() {
	apt-get update
	apt-get install -y git apache2-utils supervisor jq python-is-python2

}
_centos() {
	yum update
	yum install -y git httpd-tools supervisor jq python2
}

if [ -f /etc/os-release ]; then
	# freedesktop.org and systemd
	. /etc/os-release
	OS=$NAME
	VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
	# linuxbase.org
	OS=$(lsb_release -si)
	VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
	# For some versions of Debian/Ubuntu without lsb_release command
	. /etc/lsb-release
	OS=$DISTRIB_ID
	VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
	# Older Debian/Ubuntu/etc.
	OS=Debian
	VER=$(cat /etc/debian_version)
# elif [ -f /etc/SuSe-release ]; then
# 	# Older SuSE/etc.

# elif [ -f /etc/redhat-release ]; then
# 	# Older Red Hat, CentOS, etc.
# else
# 	# Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
# 	OS=$(uname -s)
# 	VER=$(uname -r)
fi

case "$OS" in
"Debian GNU/Linux")
	_debian
	;;
"Ubuntu")
	_ubuntu
	;;
"CentOS Linux")
	_centos
	;;
*)
	echo "Your OS not support"
	exit 0
	;;
esac

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
./mbr node set DATA_URI {*data_url*}
./mbr node set USER_ID {{user_id}}
./mbr node set ID {{id}}
./mbr node set TOKEN {{token}}
./mbr node set BLOCKCHAIN {{blockchain}}
./mbr node set NETWORK {{network}}
./mbr node set SITE_ROOT "$SITE_ROOT"
./mbr node register
