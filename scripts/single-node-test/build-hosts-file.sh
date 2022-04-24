MASSBITROUTE_CORE_IP=$(cat MASSBITROUTE_CORE_IP)
MASSBITROUTE_PORTAL_IP=$(cat MASSBITROUTE_PORTAL_IP)
MASSBITROUTE_RUST_IP=$(cat MASSBITROUTE_RUST_IP)
whoami
sudo cat hosts-template | \
    sed "s/\[\[MASSBITROUTE_CORE_IP\]\]/$MASSBITROUTE_CORE_IP/g" | \
    sed "s/\[\[MASSBITROUTE_PORTAL_IP\]\]/$MASSBITROUTE_PORTAL_IP/g" | \
    sed "s/\[\[MASSBITROUTE_RUST_IP\]\]/$MASSBITROUTE_RUST_IP/g" > test-hosts-file

# sudo ssh-keyscan -H $MASSBITROUTE_CORE_IP >> /root/.ssh/known_hosts
# sudo ssh-keyscan -H $MASSBITROUTE_PORTAL_IP >> /root/.ssh/known_hosts
# sudo ssh-keyscan -H $MASSBITROUTE_RUST_IP >> /root/.ssh/known_hosts

# cat /root/.ssh/known_hosts

# sudo chmod og-rwx /opt/ssh-key/id_rsa
# sudo chmod og-rwx /root/.ssh/id_rsa


# sudo scp -i /root/.ssh/id_rsa test-hosts-file hoang@$MASSBITROUTE_CORE_IP:/home/hoang/hosts
# sudo ssh -i /root/.ssh/id_rsa  hoang@$MASSBITROUTE_CORE_IP "sudo cp /home/hoang/hosts1 /etc/hosts1"

# sudo scp -i /root/.ssh/id_rsa test-hosts-file hoang@$MASSBITROUTE_PORTAL_IP:/home/hoang/hosts
# sudo ssh -i /root/.ssh/id_rsa hoang@$MASSBITROUTE_PORTAL_IP "sudo cp /home/hoang/hosts1 /etc/hosts1"

# sudo scp -i /root/.ssh/id_rsa test-hosts-file hoang@$MASSBITROUTE_RUST_IP:/home/hoang/hosts
# sudo ssh -i /root/.ssh/id_rsa hoang@$MASSBITROUTE_RUST_IP "sudo cp /home/hoang/hosts1 /etc/hosts1"

sudo cp test-hosts-file /etc/hosts

cat test-hosts-file

git config --global user.email "hoang@codelight.co"
git config --global user.name "hoanito"

rm -rf hosts
sudo git clone git@github.com:hoanito/hosts.git -b main hosts
sudo cp test-hosts-file hosts/test-hosts-file
cd hosts
git config --global --add safe.directory /__w/masbitroute/massbitroute
sudo git add . && sudo git commit -m "Update host file" && sudo git push origin main
