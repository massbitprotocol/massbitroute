#!/bin/bash
dir=$(dirname $(realpath $0))
mkdir -p $dir/run
cd $dir
commit=$(git log --oneline | head -1 |cut -d' ' -f1)
_update(){
	git add .
	git commit -m update
	git push origin master
}
_reload(){
/root/.asdf/installs/gdnsd/v3.8.0/bin/gdnsdctl -c $dir replace
}

_do(){
		last_commit=$(cat $dir/run/commit)
		git pull origin master
		cur_commit=$(git log --oneline | head -1 |cut -d' ' -f1)
		if [ "$cur_commit" != "$last_commit" ];then
		echo $cur_commit > $dir/run/commit
			$0 _reload
		fi
		sleep 1
}
_monitor(){
	while true;do
		$0 _do
	done

}
_check(){
/root/.asdf/installs/gdnsd/v3.8.0/sbin/gdnsd -c $dir checkconf 
}
#IP=$(curl icanhazip.com)
IP=$(ifconfig | awk '/inet 10./ {print $2}')
sed "s/LISTEN_IP/$IP/g" config.tmpl > config
if [ $# -gt 0 ];then
	$@
	exit 0
fi

echo $commit > $dir/run/commit
/root/.asdf/installs/gdnsd/v3.8.0/sbin/gdnsd -c $dir -RD start
