#!/bin/bash
SITE_ROOT=$(realpath $(dirname $(realpath $0))/..)

_load_env() {
	ROOT_DIR=$1
	cd $ROOT_DIR
	if [ -z "$MBR_ENV" ]; then
		if [ -f "$ROOT_DIR/.env" ]; then
			source $ROOT_DIR/.env
		fi
	fi

	if [ -z "$MBR_ENV" ]; then
		if [ -f "$ROOT_DIR/vars/MBR_ENV" ]; then
			export MBR_ENV=$(cat "$ROOT_DIR/vars/MBR_ENV")
		fi
	fi

	if [ -n "$MBR_ENV" ]; then
		_file="$ROOT_DIR/.env.$MBR_ENV"
		if [ ! -f "$_file" ]; then return; fi
		mkdir -p $ROOT_DIR/src

		tmp=$(mktemp)
		echo "export MBR_ENV=$MBR_ENV" >$tmp
		cat $_file | awk 'NF > 0 && !/^\s*source/ && !/^\s*#/' >>$tmp
		# echo >>$tmp
		cat $_file | awk '/^\s*source/ {print $2}' | while read f; do cat $f; done | awk "NF > 0 && !/^#/" >>$tmp
		source $tmp
		cat $tmp
		cat $tmp | sed 's/export\s*//g' | awk -F '=' '{print $1}' | while read k; do
			#	echo "export $k=$((k))"
			if [ -z "$k" ]; then continue; fi
			echo "export $k=${!k}"
		done >${tmp}.1
		cat ${tmp}.1
		mv ${tmp}.1 $ROOT_DIR/.env_raw

		awk -F'=' -v q1="'" -v q2='"' 'BEGIN{cfg="return {\n"}
		{
		        sub(/^export\s*/,"",$1);
		        if(length($2) == 0)
		        cfg=cfg"[\""$1"\"]""=\""$2"\",\n";
		else {
		        val_1=substr($2,0,1);
		        if(val_1 == q1 || val_1 == q2)
		        cfg=cfg"[\""$1"\"]""="$2",\n";
		        else
		        cfg=cfg"[\""$1"\"]""=\""$2"\",\n";
		}

		}
		END{print cfg"}"}' $ROOT_DIR/.env_raw >$ROOT_DIR/src/env.lua

		rm ${tmp}*
	fi
}

_git_config() {
	if [ ! -f "$HOME/.gitconfig" ]; then
		cat >$HOME/.gitconfig <<EOF
   [http]
        sslverify = false
    [user]
	email = baysao@gmail.com
	name = Baysao
EOF
	fi

}
_git_clone() {
	_url=$1
	_dir=$2
	_branch=$3
	if [ -z "$_branch" ]; then _branch=$MBR_ENV; fi
	# if [ -d "$_dir" ]; then rm -rf $_dir; fi
	mkdir -p $_dir
	git clone $_url $_dir -b $_branch
	git branch --set-upstream-to=origin/$_branch
}
_update_sources() {
	_git_config
	_is_reload=0
	branch=$MBR_ENV
	for _pathgit in $@; do
		_path=$(echo $_pathgit | cut -d'|' -f1)
		timeout 60 git -C $_path pull | grep -i "updating"
		st=$?
		echo $_path $st
		if [ $st -eq 0 ]; then
			_is_reload=1
		fi
	done
	return $_is_reload
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
