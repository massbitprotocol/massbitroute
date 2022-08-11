#!/bin/bash
SITE_ROOT=$(realpath $(dirname $(realpath $0))/..)
export HOME=$SITE_ROOT
_git_config() {
	cat >$HOME/.gitconfig <<EOF
   [http]
        sslverify = false
    [user]
	email = baysao@gmail.com
	name = Baysao
EOF
}
_env() {
	if [ -z "$MBR_ENV" ]; then
		echo "MBR_ENV missing"
		return 1
	fi
	if [ -z "$GIT_PRIVATE_READ_URL" ]; then
		echo "GIT_PRIVATE_READ_URL missing"
		return 1
	fi
	export ENV_BRANCH=${ENV_BRANCH:-$MBR_ENV}
	if [ ! -d "$SITE_ROOT/env/.git" ]; then
		_git_clone $GIT_PRIVATE_READ_URL/massbitroute/env.git $SITE_ROOT/env $ENV_BRANCH
	fi
	if [ -f "$SITE_ROOT/env/env.sh" ]; then
		source $SITE_ROOT/env/env.sh
	fi
	if [ -f "$SITE_ROOT/env/env.lua" ]; then
		cp $SITE_ROOT/env/env.lua $SITE_ROOT/src/
	fi

}
_git_clone() {
	_url=$1
	_dir=$2
	_branch=$3
	_force=$4
	if [ -z "$_force" ]; then _force=0; fi
	if [ -z "$_branch" ]; then _branch=$MBR_ENV; fi
	_clone_status=0

	if [ $_force -eq 1 ]; then
		if [ -d "$_dir" ]; then
			if [ -d "${_dir}.backup" ]; then rm -rf ${_dir}.backup; fi
			mv $_dir ${_dir}.backup
		fi
	fi

	mkdir -p $_dir

	if [ ! -d "$_dir/.git" ]; then
		git clone --depth 1 -b $_branch $_url $_dir
		_clone_status=1

	fi

	git -C $_dir pull origin $_branch | grep -i "updating" >/dev/null
	if [ $? -eq 0 ]; then
		_clone_status=1
	fi

	return $_clone_status

}

_install_sources() {
	_git_config
	# _env
	_install_sources_status=0
	for _pathgit in $@; do
		# _repo
		# _env
		_dir=$(echo $_pathgit | cut -d'|' -f1)
		_url=$(echo $_pathgit | cut -d'|' -f2)
		_branch=$(echo $_pathgit | cut -d'|' -f3)
		if [ -z "$_branch" ]; then _branch=$MBR_ENV; fi
		_git_clone $_url $_dir $_branch 1
		_st=$?

		if [ $_install_sources_status -eq 0 ]; then
			_install_sources_status=$_st
		fi
		_env
	done
	return $_install_sources_status
}
_update_sources() {
	_git_config
	_env
	_update_sources_status=0
	for _pathgit in $@; do
		_dir=$(echo $_pathgit | cut -d'|' -f1)
		# git config --global --add safe.directory $_path
		_url=$(echo $_pathgit | cut -d'|' -f2)
		_branch=$(echo $_pathgit | cut -d'|' -f3)
		if [ -z "$_branch" ]; then _branch=$MBR_ENV; fi
		_git_clone $_url $_dir $_branch
		_st=$?

		if [ $_update_sources_status -eq 0 ]; then
			_update_sources_status=$_st
		fi
		_env
	done
	return $_update_sources_status
}
_commit_sources() {
	_git_config
	_env
	_commit_sources_status=0
	for _pathgit in $@; do
		_dir=$(echo $_pathgit | cut -d'|' -f1)
		# git config --global --add safe.directory $_path
		_url=$(echo $_pathgit | cut -d'|' -f2)
		_branch=$(echo $_pathgit | cut -d'|' -f3)
		if [ -z "$_branch" ]; then _branch=$MBR_ENV; fi
		cd $_dir
		git pull origin $_branch
		git add .
		git commit -m "$(date)"
		git push origin $_branch
		_st=$?

		if [ $_commit_sources_status -eq 0 ]; then
			_commit_sources_status=$_st
		fi
		_env
	done
	return $_commit_sources_status
}
loop() {
	while true; do
		$0 $@
		sleep 3
	done

}
_timeout() {
	t=$1
	if [ -n "$t" ]; then
		shift
		timeout $t $0 $@
	else
		$0 $@
	fi
}
