#!/bin/bash
auth=massbit:c671e4ea06280e7a3f6f9aea6e8155fcde9bc703
GITHUB_TRIES=10
_debian() {
	apt-get update
	apt-get install -y git apache2-utils supervisor jq python2

}

_ubuntu() {
	apt-get update
	apt-get install -y git apache2-utils supervisor libmaxminddb0 libmaxminddb-dev jq python-is-python2

}
_centos() {
	yum update
	yum install -y git httpd-tools supervisor jq python2
}
_nodeverify(){
  res=$($SITE_ROOT/mbr node nodeverify | tail -1 | jq .status | sed s/\"//g)
  echo $res
}
_gitclone() {
  repo=$1
  dest=$2
  shift 2
  rem="$@"
  cmd="git clone $repo $dest $rem"
  $cmd
  st=$?
  i=0
  while [ \( $i -lt $GITHUB_TRIES \) -a \( $st -ne 0 \) ]; do
    echo "Can not clone code from github $repo. Retrying ${i}th ... !"
    $cmd
    st=$?
    i=$((i + 1))
  done
  if [ $st -ne 0 ]; then
    echo "Can not clone code from github $repo after $GITHUB_TRIES tries!"
    exit 1
  fi
  git -C $dest remote set-url origin $repo
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

ENV={{env}}
IP="$(curl -ssSfL http://ipv4.icanhazip.com)"

n=$(grep -o "\." <<<"$IP" | wc -l)
if [ $n -ne 3 ]; then
	echo "Your IP is unknown"
	exit 1
fi

if [ -z "$IP" ]; then
	echo "Your IP is unknown"
	exit 1
fi

zone=$(curl -ssSfL "{*portal_url*}/mbr/gateway/{{id}}/geo?ip=$IP" --header 'Authorization: {{app_key}}' | jq .continent_code)
zone=$(echo $zone | sed 's/\"//g')
if [ -z "$zone" ]; then
	echo "Cannot detect zone from IP $IP"
	#exit 1
fi

if [ "$zone" != "{{zone}}" ]; then
	echo "Your IP $IP not in zone {{zone}}"
	read -p "Are you sure ? (y/n) " -n 1 -r
	echo # (optional) move to a new line
	if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
		echo "Please install in correct Zone"
		exit 1
	fi

fi

SITE_ROOT=/massbit/massbitroute/app/src/sites/services/gateway
SCRIPTS_RUN="$SITE_ROOT/scripts/run"
mkdir -p $(dirname $SITE_ROOT)

# git clone -b master http://mbr_gateway:6a796299bb72357770735a79019612af228586e7@git.massbitroute.com/massbitroute/ssl.git -b master /etc/letsencrypt

if [ ! -d "$SITE_ROOT/.git" ]; then
	rm -rf $SITE_ROOT
	#git clone -b master http://$auth@git.massbitroute.dev/massbitroute/gateway.git $SITE_ROOT
  if [ "x$ENV" == "x" ]; then
    _gitclone https://github.com/massbitprotocol/massbitroute_gateway $SITE_ROOT -b master
    #git clone -b master http://github.com/massbitprotocol/massbitroute_gateway $SITE_ROOT
  else
    _gitclone https://github.com/massbitprotocol/massbitroute_gateway $SITE_ROOT -b ${ENV}
    #git clone -b ${ENV} http://github.com/massbitprotocol/massbitroute_gateway $SITE_ROOT
  fi
fi

cd $SITE_ROOT
git pull
rm -f $SITE_ROOT/vars/*

#create environment variables
./mbr node set ENV {{env}}
./mbr node set PORTAL_URL {*portal_url*}
./mbr gw set USER_ID {{user_id}}
./mbr gw set ID {{id}}
./mbr gw set IP $IP
./mbr gw set TOKEN {{token}}
./mbr gw set BLOCKCHAIN {{blockchain}}
./mbr gw set NETWORK {{network}}
./mbr gw set APP_KEY {{app_key}}
./mbr gw set SITE_ROOT "$SITE_ROOT"

$SCRIPTS_RUN _install

rm -f $SITE_ROOT/http.d/*

./mbr gw register

supervisorctl status

$SCRIPTS_RUN _load_config
$SITE_ROOT/cmd_server _update

$SITE_ROOT/cmd_server status


status=$(_nodeverify)
while [ "$status" != "verified" ]; do
	echo "Verifying firewall ... Please make sure your firewall is open and try run again."
	sleep 10
	$SCRIPTS_RUN _load_config
  $SITE_ROOT/cmd_server _update
	status=$(_nodeverify)
done
if [ "$status" = "verified" ]; then
	echo "Installed gateway successfully !"
fi
