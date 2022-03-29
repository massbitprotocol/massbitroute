#!/bin/bash
node=/massbit/massbitroute/app/gbc/bin/.asdf/installs/nodejs/16.11.1
chmod +x $node/bin/* $node/lib/node_modules/corepack/shims/*
export PATH=$PATH:$node/bin:$node/lib/node_modules/corepack/shims
cur=$(dirname $(realpath $0))
mbr_app=$cur/../public/mbr-app-prod
if [ ! -f "$cur/../.env" ]; then
	echo "Please set environment variables and reinstall!"
	exit 1
else
	. $cur/../.env
fi
SITE_ROOT=$(realpath $(dirname $(realpath $0))/..)
export HOME=$SITE_ROOT
ROOT_DIR=$SITE_ROOT

source $SITE_ROOT/scripts/base.sh
cd $SITE_ROOT
_load_env $SITE_ROOT

_prod() {
	cd $mbr_app
	type=dapi
	export PORT=3001
	export API_BASE_URL=https://$type.$DOMAIN
	export GATEWAY_INSTALL_URL=https://$type.$DOMAIN/api/v1/gateway_install
	export NODE_INSTALL_URL=https://$type.$DOMAIN/api/v1/node_install
	$@
}
_build_prod() {
	commit=$1
	cd $mbr_app
	type=dapi
	export PORT=3001
	export API_BASE_URL=https://$type.$DOMAIN
	export API_CORE_URL=http://api.$DOMAIN
	export API_USER_URL=https://portal.$DOMAIN
	export API_PORTAL_URL=https://portal.$DOMAIN
	export DAPI_PROVIDER_DOMAIN=$DOMAIN
	export STAT_URL=https://stat.mbr.$DOMAIN/
	export GATEWAY_INSTALL_URL=https://$type.$DOMAIN/api/v1/gateway_install
	export NODE_INSTALL_URL=https://$type.$DOMAIN/api/v1/node_install
	#git submodule update --init --remote mbr-app
	if [ -z "$commit" ]; then
		git checkout staging
		git pull
	else
		git checkout $commit
		git pull
	fi
	#origin master

	rm -rf .nuxt dist
	yarn install && yarn build && yarn generate
}
_start_prod() {
	cd $mbr_app
	type=dapi
	export PORT=3001
	export API_BASE_URL=https://$type.$DOMAIN
	export API_CORE_URL=http://api.$DOMAIN
	export API_USER_URL=https://portal.$DOMAIN
	export API_PORTAL_URL=https://portal.$DOMAIN
	export DAPI_PROVIDER_DOMAIN=$DOMAIN
	export STAT_URL=https://stat.mbr.$DOMAIN/
	export GATEWAY_INSTALL_URL=https://$type.$DOMAIN/api/v1/gateway_install
	export NODE_INSTALL_URL=https://$type.$DOMAIN/api/v1/node_install
	rsync -avz assets dist/
	yarn start
}
_build() {
	cd $cur/public/mbr-app
	type=dapi-staging
	export PORT=3000
	export API_BASE_URL=https://$type.$DOMAIN
	export GATEWAY_INSTALL_URL=https://$type.$DOMAIN/api/v1/gateway_install
	export NODE_INSTALL_URL=https://$type.$DOMAIN/api/v1/node_install
	#git submodule update --init --remote mbr-app
	if [ -z "$commit" ]; then
		git checkout staging
		git pull
	else
		git checkout $commit
	fi
	#origin master
	rm -rf .nuxt dist
	yarn install && yarn build && yarn generate
}
_start() {
	cd $cur/public/mbr-app
	type=dapi-staging
	export PORT=3000
	export API_BASE_URL=https://$type.$DOMAIN
	export GATEWAY_INSTALL_URL=https://$type.$DOMAIN/api/v1/gateway_install
	export NODE_INSTALL_URL=https://$type.$DOMAIN/api/v1/node_install
	rsync -avz assets dist/
	yarn start
}

$@
