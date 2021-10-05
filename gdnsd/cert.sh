#apt-add-repository ppa:certbot/certbot
#apt install certbot
#wget https://github.com/joohoi/acme-dns-certbot-joohoi/raw/master/acme-dns-auth.py
##!/usr/bin/env python3
#chmod +x acme-dns-auth.py
#mv acme-dns-auth.py /etc/letsencrypt/
#certbot certonly --manual --manual-auth-hook /etc/letsencrypt/acme-dns-auth.py --preferred-challenges dns --debug-challenges -d \*.admoncdn.com -d admoncdn.com
certbot renew
