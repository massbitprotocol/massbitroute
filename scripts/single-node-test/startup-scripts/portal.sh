  #!/bin/bash
  #-------------------------------------------
  #  Update host file for Massbitroute.dev
  #-------------------------------------------
  echo "starting script" >> /home/log
  sudo sed 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf -i
  sudo pkill -f systemd-resolve

  sudo systemctl stop systemd-resolved
  sudo systemctl disable systemd-resolved 
  sudo echo nameserver 8.8.8.8 >/etc/resolv.conf
  
  #-------------------------------------------
  #  Install PORTAL API
  #-------------------------------------------
  cd /opt/user-management
  git pull
  cp .env.admin.sample .env.admin
  cp .env.api.sample .env.api
  cp .env.worker.sample .env.worker
  sudo yarn
  sudo yarn build >> /home/portal.build.log
  sudo pm2 start

  #-------------------------------------------
  #  Install STAKING API
  #-------------------------------------------
  cd /opt/test-massbit-staking
  git pull
  cp .env.sample .env
  sudo yarn
  sudo yarn build >> /home/staking.build.log
  sudo pm2 start