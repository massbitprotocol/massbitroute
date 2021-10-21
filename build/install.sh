apt-get -y install --no-install-recommends wget gnupg ca-certificates \
build-essential libpcre3-dev libssl-dev git-core unzip python make zip unzip \
supervisor
wget -O - https://openresty.org/package/pubkey.gpg | sudo apt-key add -
echo "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main" \
	    | sudo tee /etc/apt/sources.list.d/openresty.list

apt-get update
apt-get -y install openresty
systemctl disable openresty
systemctl stop openresty
cat <<EOF >/etc/supervisor/conf.d/mbr_gateway.conf
[program:mbr_gateway]
command=/massbit/massbitroute/app/src/start_server
EOF
supervisorctl update
