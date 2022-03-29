#!/bin/bash
SITE_ROOT=$(realpath $(dirname $(realpath $0))/..)

_load_env() {
	ROOT_DIR=$1
	if [ -f "$ROOT_DIR/.env" ]; then
		source $ROOT_DIR/.env
		_file=$ROOT_DIR/.env
		if [ -z "$MBR_ENV" ]; then
			if [ -f "$ROOT_DIR/vars/ENV" ]; then
				export MBR_ENV=$(cat "$ROOT_DIR/vars/ENV")
			fi
		fi

		if [ -n "$MBR_ENV" ]; then
			_file=$ROOT_DIR/.env.$MBR_ENV
		fi
		source $_file

		mkdir -p $ROOT_DIR/src
		cat $_file | grep -v "^#" | awk -F'=' -v q1="'" -v q2='"' 'BEGIN{cfg="return {\n"}
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
END{print cfg"}"}' >$ROOT_DIR/src/env.lua

	fi

}

_git_config() {
	if [ ! -f "$HOME/.gitconfig" ]; then
		cat >$HOME/.gitconfig <<EOF
    [user]
	email = baysao@gmail.com
	name = Baysao
EOF
	fi

}
_update_sources() {
	_git_config
	is_reload=0
	branch=$MBR_ENV
	if [ -f "$SITE_ROOT/vars/GIT_MODULES" ]; then
		cat $SITE_ROOT/vars/GIT_MODULES | while read _path; do
			echo "git -C $_path pull origin $MBR_ENV"
			git branch --set-upstream-to origin/$branch
			git -C $_path pull origin $branch | grep -i "updating"
			if [ $? -eq 0 ]; then
				is_reload=1
			fi

		done
	fi
	return $is_reload
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
