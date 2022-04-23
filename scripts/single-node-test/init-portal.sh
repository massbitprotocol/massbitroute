  #!/bin/bash
  #-------------------------------------------
  #  Update host file for Massbitroute.dev
  #-------------------------------------------
  sudo echo "
sudo wget https://raw.githubusercontent.com/hoanito/hosts/main/test-hosts-file -P /etc/
sudo cp /etc/hosts /etc/hosts.bak
sudo cp /etc/test-hosts-file /etc/hosts" >> /opt/update_hosts.sh

  sudo echo "1 * * * * root sudo bash /opt/update_hosts.sh" >> /etc/crontab

  echo "start" > /home/portal.log
  sudo sed 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf -i
  sudo pkill -f systemd-resolve
  sudo systemctl stop systemd-resolved
  sudo systemctl disable systemd-resolved 
  sudo echo nameserver 8.8.8.8 >/etc/resolv.conf

  #-------------------------------------------
  #  Install packages
  #-------------------------------------------
  sudo apt update
  sudo apt install redis-server npm -y
  sudo systemctl enable redis-server
  sudo npm install --global yarn
  sudo npm cache clean -f
  sudo npm install -g n
  sudo n stable
  sudo yarn global add pm2

  #-------------------------------------------
  #  Install SSH keys
  #-------------------------------------------
  sudo mkdir /opt/ssh-key
  sudo git clone http://$PRIVATE_GIT_SSH_USERNAME:$PRIVATE_GIT_SSH_PASSWORD@$PRIVATE_GIT_DOMAIN/massbitroute/ssh.git -b main /opt/ssh-key
  sudo cp /opt/ssh-key/id_rsa*  /root/.ssh/
  sudo chmod og-rwx /root/.ssh/id_rsa
  sudo cat /opt/ssh-key/ci-ssh-key.pub >> /home/hoang/.ssh/authorized_keys
  
  ssh-keyscan github.com >> ~/.ssh/known_hosts

  #-------------------------------------------
  #  Install PORTAL API
  #-------------------------------------------
  sudo mkdir /opt/user-management
  sudo git clone git@github.com:massbitprotocol/user-management.git -b staging /opt/user-management
  cd /opt/user-management
  cp /opt/ssh-key/.env.portal /opt/user-management/.env
  cp /opt/ssh-key/.env.api /opt/user-management/.env.api
  cp /opt/ssh-key/.env.worker /opt/user-management/.env.worker
  sudo yarn
  sudo yarn build
  sudo pm2 start

  #-------------------------------------------
  #  Install STAKING API
  #-------------------------------------------
  sudo mkdir /opt/test-massbit-staking
  sudo git clone git@github.com:mison201/test-massbit-staking.git  /opt/test-massbit-staking
  cd /opt/test-massbit-staking
  cp /opt/ssh-key/.env.staking /opt/test-massbit-staking/.env
  sudo yarn
  sudo yarn build
  sudo pm2 start

  #-------------------------------------------
  #  Install NGINX
  #-------------------------------------------
  sudo mkdir -p /opt/ssl
  git clone http://$PRIVATE_GIT_SSL_USERNAME:$PRIVATE_GIT_SSL_PASSWORD@$PRIVATE_GIT_DOMAIN/massbitroute/ssl.git /etc/letsencrypt
  sudo apt update && sudo apt upgrade -y && sudo apt install curl nginx -y
  sudo apt install software-properties-common
  cp /opt/ssh-key/portal.nginx /etc/nginx/sites-enabled/portal
  cp /opt/ssh-key/staking.nginx /etc/nginx/sites-enabled/staking
  sudo service nginx reload

  