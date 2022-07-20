#!/bin/bash
GITHUB_TRIES=10

# _debian() {
# 	apt-get update
# 	apt-get install -y git apache2-utils supervisor jq python2

# }
_ubuntu() {
	apt-get update
	apt-get install -y \
		supervisor ca-certificates curl rsync apt-utils git python3 python3-pip parallel apache2-utils jq python-is-python2 libssl-dev libmaxminddb-dev fcgiwrap cron xz-utils liburcu-dev libev-dev libsodium-dev libtool libunwind-dev libmaxminddb-dev
	# git apache2-utils supervisor libmaxminddb0 libmaxminddb-dev jq python-is-python2

}
# _centos() {
# 	yum update
# 	yum install -y git httpd-tools supervisor jq python2
# }

_nodeverify() {
	res=$($SITE_ROOT/mbr node nodeverify | tail -1 | jq ".status,.message" | sed -z "s/\"//g;")
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
	git -C $dest checkout origin/$repo
	git -C $dest reset --hard
	git -C $dest pull origin $repo
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

fi

if [ \( "$OS" = "Ubuntu" \) -a \( "$VER" = "20.04" \) ]; then
	_ubuntu
else
	echo "Sorry. Current we only support Ubuntu 20.04. "
	exit 1
fi

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

zone=$(curl -ssSfL "{*portal_url*}/mbr/node/{{id}}/geo?ip=$IP" --header 'Authorization: {{app_key}}' | jq .continent_code)
zone=$(echo $zone | sed 's/\"//g')
if [ -z "$zone" ]; then
	echo "Cannot detect zone from IP $IP"
	sleep 3
fi

if [ "$zone" != "{{zone}}" ]; then
	echo "WARNING: Your IP $IP not in zone {{zone}}"
	sleep 3
fi

SERVICE_DIR=/massbit/massbitroute/app/src/sites/services
SITE_ROOT=$SERVICE_DIR/node
if [ \( -f "/etc/supervisor/conf.d/mbr_gateway.conf" \) -o \( -d "$SERVICE_DIR/gateway" \) ]; then
	echo "Detect conflict folder $SERVICE_DIR/gateway or /etc/supervisor/conf.d/mbr_gateway.conf. Please remove it before install."
	exit 0
fi

SCRIPTS_RUN="$SITE_ROOT/scripts/run"
mkdir -p $(dirname $SITE_ROOT)

export ENV={{env}}
export MBR_ENV={{env}}

git config --global http.sslVerify false
if [ ! -d "$SITE_ROOT/.git" ]; then
	rm -rf $SITE_ROOT

	if [ "x$ENV" == "x" ]; then
		_gitclone https://github.com/massbitprotocol/massbitroute_node $SITE_ROOT -b master

	else
		_gitclone https://github.com/massbitprotocol/massbitroute_node $SITE_ROOT -b ${ENV}

	fi
fi

cd $SITE_ROOT

git pull
git reset --hard

#rm -f $SITE_ROOT/vars/* $SITE_ROOT/.env $SITE_ROOT/.env_raw $SITE_ROOT/src/env.lua

cat >.env <<EOF
export GIT_PUBLIC_URL="https://github.com"
export MBR_ENV=${MBR_ENV}
EOF

#create environment variables
./mbr node set ENV {{env}}
./mbr node set MBR_ENV {{env}}

#bash init.sh
./mbr node set PORTAL_URL {*portal_url*}
./mbr node set DATA_URI {*data_url*}
./mbr node set USER_ID {{user_id}}
./mbr node set ID {{id}}
./mbr node set IP $IP
./mbr node set TOKEN {{token}}
./mbr node set BLOCKCHAIN {{blockchain}}
./mbr node set NETWORK {{network}}
./mbr node set APP_KEY {{app_key}}
./mbr node set SITE_ROOT "$SITE_ROOT"

log_install=$SITE_ROOT/logs/install.log
bash -x $SCRIPTS_RUN _install 2>&1 >>$log_install
bash -x $SCRIPTS_RUN _register_node 2>&1 >>$log_install
