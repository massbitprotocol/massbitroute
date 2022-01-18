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
if [ \( "$OS" = "Ubuntu" \) -a \( "$VER" = "20.04" \) ]; then
	_ubuntu
else
	echo "Sorry. Current we only support Ubuntu 20.04. "
	exit 1
fi

# case "$OS" in
# "Debian GNU/Linux")
# 	_debian
# 	;;
# "Ubuntu")
# 	if [ $VER = "20.04" ]
# 	_ubuntu
# 	;;
# "CentOS Linux")
# 	_centos
# 	;;
# *)
# 	echo "Sorry. Your OS not support"
# 	exit 0
# 	;;
# esac

IP="$(curl -ssSfL https://dapi.massbit.io/myip)"

n=$(grep -o "\." <<<"$IP" | wc -l)
if [ $n -ne 3 ]; then
	echo "Your IP is unknown"
	exit 1
fi

if [ -z "$IP" ]; then
	echo "Your IP is unknown"
	exit 1
fi

zone="$(curl -ssSfL http://api.ipapi.com/api/$IP?access_key=092142b61eed12af33e32fc128295356 | jq .continent_code)"
zone=$(echo $zone | sed 's/\"//g')
if [ -z "$zone" ]; then
	echo "Cannot detect zone from IP $IP"
	exit 1
fi

if [ "$zone" != "{{zone}}" ]; then
	echo "Your IP $IP not in zone {{zone}}"
	read -p "Are you sure ? (y/n) " -n 1 -r
	echo # (optional) move to a new line
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		echo "Please install in correct Zone"
		exit 1
	fi

fi

SITE_ROOT=/massbit/massbitroute/app/src/sites/services/gateway
mkdir -p $(dirname $SITE_ROOT)

# git clone -b master http://mbr_gateway:6a796299bb72357770735a79019612af228586e7@git.massbitroute.com/massbitroute/ssl.git -b master /etc/letsencrypt

if [ ! -d "$SITE_ROOT" ]; then
	git clone -b master http://mbr_gateway:6a796299bb72357770735a79019612af228586e7@git.massbitroute.com/massbitroute/gateway.git $SITE_ROOT
fi

cd $SITE_ROOT
git pull origin master
rm -f $SITE_ROOT/http.d/*
rm -f $SITE_ROOT/vars/*
bash init.sh
./mbr gw set USER_ID {{user_id}}
./mbr gw set ID {{id}}
./mbr gw set IP $IP
./mbr gw set TOKEN {{token}}
./mbr gw set BLOCKCHAIN {{blockchain}}
./mbr gw set NETWORK {{network}}
./mbr gw set SITE_ROOT "$SITE_ROOT"

./mbr gw register

verified=$(./mbr gw nodeverify | jq .result)

while [ "$verified" != "true" ]; do
	echo "Install not successul. Please make sure your firewall is open and try run again."
	sleep 3
	verified=$(./mbr gw nodeverify | jq .result)
done
