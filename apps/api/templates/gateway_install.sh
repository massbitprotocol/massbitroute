#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
SERVICE_DIR=/massbit/massbitroute/app/src/sites/services
TYPE=gateway
SITE_ROOT=$SERVICE_DIR/$TYPE
MBR=$SITE_ROOT/mbr
export MBR_ENV={{env}}
SCRIPTS_RUN="$SITE_ROOT/scripts/run"
mkdir -p $(dirname $SITE_ROOT)

_ubuntu() {
	apt-get update
	apt-get install -y \
		supervisor ca-certificates curl rsync apt-utils git python3 python3-pip parallel apache2-utils jq python-is-python2 libssl-dev libmaxminddb-dev fcgiwrap cron xz-utils liburcu-dev libev-dev libsodium-dev libtool libunwind-dev libmaxminddb-dev

}
if [ -f /etc/os-release ]; then
	. /etc/os-release
	OS=$NAME
	VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
	OS=$(lsb_release -si)
	VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
	. /etc/lsb-release
	OS=$DISTRIB_ID
	VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
	OS=Debian
	VER=$(cat /etc/debian_version)

fi
if [ \( "$OS" = "Ubuntu" \) -a \( "$VER" = "20.04" \) ]; then
	_ubuntu
else
	echo "Sorry. Current we only support Ubuntu 20.04. "
	exit 1
fi
tmp=$(mktemp)
curl -ssSfL "{*portal_url*}/mbr/$TYPE/{{id}}/geo?ip=$IP" --header 'Authorization: {{app_key}}' -o $tmp >/dev/null
if [ $? -eq 0 ]; then
	zone=$(cat $tmp | jq .continent_code | sed 's/\"//g')
	if [ "$zone" != "{{zone}}" ]; then
		echo "WARNING: Your IP $IP not in zone {{zone}}"

	fi
fi

rm $tmp

_c_type=node
_c_conf=/etc/supervisor/conf.d/mbr_${_c_type}.conf
_c_dir=$SERVICE_DIR/$_c_type
if [ \( -f "$_c_conf" \) -o \( -d "$_c_dir" \) ]; then
	echo "Detect conflict folder $_c_dir or $_c_conf . Please remove it before install."
	exit 1
fi

git config --global http.sslVerify false
git clone https://github.com/massbitprotocol/massbitroute_$TYPE $SITE_ROOT -b ${MBR_ENV}
sleep 1

cd $SITE_ROOT
rm -f $SITE_ROOT/vars/* $SITE_ROOT/.env*-

#create environment variables

cat >$SITE_ROOT/.env <<EOF
export GIT_PUBLIC_URL="https://github.com"
export MBR_ENV=${MBR_ENV}
EOF

cp $SITE_ROOT/.env $SITE_ROOT/.env_raw

#create environment variables
./mbr node set ENV {{env}}
./mbr node set MBR_ENV {{env}}
./mbr node set PORTAL_URL {*portal_url*}
./mbr gw set USER_ID {{user_id}}
./mbr gw set ID {{id}}
./mbr gw set IP $IP
./mbr gw set TOKEN {{token}}
./mbr gw set BLOCKCHAIN {{blockchain}}
./mbr gw set NETWORK {{network}}
./mbr gw set APP_KEY {{app_key}}
./mbr gw set SITE_ROOT "$SITE_ROOT"

log_install=$SITE_ROOT/logs/install.log
bash -x $SCRIPTS_RUN _install 2>&1 >>$log_install
bash -x $SCRIPTS_RUN _register_node 2>&1 >>$log_install
