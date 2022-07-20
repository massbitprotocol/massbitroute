#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
SERVICE_DIR=/massbit/massbitroute/app/src/sites/services
SITE_ROOT=$SERVICE_DIR/node
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

IP="$(curl -ssSfL http://ipv4.icanhazip.com)"

if [ -z "$IP" ]; then
	echo "Your IP is unknown"
	exit 1
# else
# 	n=$(grep -o "\." <<<"$IP" | wc -l)
# 	if [ $n -ne 3 ]; then
# 		echo "Your IP is unknown"
# 		exit 1
# 	fi
fi

tmp=$(mktemp)
curl -ssSfL "{*portal_url*}/mbr/node/{{id}}/geo?ip=$IP" --header 'Authorization: {{app_key}}' -o $tmp >/dev/null
if [ $? -eq 0 ]; then
	zone=$(cat $tmp | jq .continent_code | sed 's/\"//g')
	if [ "$zone" != "{{zone}}" ]; then
		echo "WARNING: Your IP $IP not in zone {{zone}}"

	fi
fi

rm $tmp

_c_type=gateway
_c_conf=/etc/supervisor/conf.d/mbr_${_c_type}.conf
_c_dir=$SERVICE_DIR/$_c_type
if [ \( -f "$_c_conf" \) -o \( -d "$_c_dir" \) ]; then
	echo "Detect conflict folder $_c_dir or $_c_conf . Please remove it before install."
	exit 1
fi

git config --global http.sslVerify false
git clone https://github.com/massbitprotocol/massbitroute_node $SITE_ROOT -b ${MBR_ENV}
sleep 1
# cd $SITE_ROOT

# git pull
# git reset --hard

rm -f $SITE_ROOT/vars/* $SITE_ROOT/.env*-

#create environment variables

cat >$SITE_ROOT/.env <<EOF
export GIT_PUBLIC_URL="https://github.com"
export MBR_ENV=${MBR_ENV}
EOF

cp $SITE_ROOT/.env $SITE_ROOT/.env_raw
$MBR node set MBR_ENV {{env}}

#bash init.sh
$MBR node set PORTAL_URL {*portal_url*}
$MBR node set DATA_URI {*data_url*}
$MBR node set USER_ID {{user_id}}
$MBR node set ID {{id}}
$MBR node set IP $IP
$MBR node set TOKEN {{token}}
$MBR node set BLOCKCHAIN {{blockchain}}
$MBR node set NETWORK {{network}}
$MBR node set APP_KEY {{app_key}}
$MBR node set SITE_ROOT "$SITE_ROOT"

log_install=$SITE_ROOT/logs/install.log
bash -x $SCRIPTS_RUN _install 2>&1 >>$log_install
bash -x $SCRIPTS_RUN _register_node 2>&1 >>$log_install
