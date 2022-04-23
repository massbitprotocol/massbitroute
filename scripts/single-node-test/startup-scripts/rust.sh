  #!/bin/bash
  #-------------------------------------------
  #  Update host file for Massbitroute.dev
  #-------------------------------------------
  sudo sed 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf -i
  sudo pkill -f systemd-resolve
  sudo systemctl stop systemd-resolved
  sudo systemctl disable systemd-resolved 
  sudo echo nameserver 8.8.8.8 >/etc/resolv.conf

  #-------------------------------------------
  #  Install VERIFICATION (RUST)
  #-------------------------------------------
  cd /massbit/massbitroute/app/src/sites/services/monitor
  git pull
  cd /massbit/massbitroute/app/src/sites/services/monitor/check_component
  /root/.cargo/bin/cargo build --release
  sudo cp target/release/mbr-check-component /opt/verification/mbr-check-component
  sudo supervisorctl reread
  sudo  supervisorctl update
  sudo supervisorctl restart verification >> /home/check_component.log