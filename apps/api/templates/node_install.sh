#!/bin/bash
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
# 	_ubuntu
# 	;;
# "CentOS Linux")
# 	_centos
# 	;;
# *)
# 	echo "Your OS not support"
# 	exit 0
# 	;;
# esac

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
	#exit 1
fi

if [ "$zone" != "{{zone}}" ]; then
	echo "WARNING: Your IP $IP not in zone {{zone}}"
	# read -p "Are you sure ? (y/n) " -n 1 -r
	# echo # (optional) move to a new line
	# if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	# 	echo "Please install in correct Zone"
	# 	exit 1
	# fi
fi

SERVICE_DIR=/massbit/massbitroute/app/src/sites/services
SITE_ROOT=$SERVICE_DIR/node
if [ \( -f "/etc/supervisor/conf.d/mbr_gateway.conf" \) -o \( -d "$SERVICE_DIR/gateway" \) ]; then
	echo "Detect conflict folder $SERVICE_DIR/gateway or /etc/supervisor/conf.d/mbr_gateway.conf. Please remove it before install."
	exit 0
fi

SCRIPTS_RUN="$SITE_ROOT/scripts/run"
mkdir -p $(dirname $SITE_ROOT)
ENV={{env}}
MBR_ENV={{env}}

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

cat >.env <<EOF
export GIT_PUBLIC_URL="https://github.com"
export MBR_ENV=${ENV}
EOF

git pull
rm -f $SITE_ROOT/vars/*

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

bash -x $SCRIPTS_RUN _install

rm -f $SITE_ROOT/http.d/*

./mbr node register

supervisorctl status

$SCRIPTS_RUN _load_config
$SITE_ROOT/cmd_server _update

$SITE_ROOT/cmd_server status

res=$($SITE_ROOT/mbr node nodeverify)
status=$(echo $res | jq ".status" | sed -z "s/\"//g;")
while [ "$status" != "verified" ]; do
	message=$(echo $res | jq ".message")
	if [ "$message" != "null" ]; then
		echo "Verifying with message: $message"
	fi
	sleep 10
	$SCRIPTS_RUN _load_config
	$SITE_ROOT/cmd_server _update
	res=$($SITE_ROOT/mbr node nodeverify)
	status=$(echo $res | jq ".status" | sed -z "s/\"//g;")
done

if [ "$status" = "verified" ]; then
	echo "Node installed successfully !"
fi
