<h1 align="center">CrowdSec</h1>

<p align='justify'>

<a href="https://www.crowdsec.net/">CrowdSec</a> - an open source software for identifying and sharing malicious IP addresses.

CrowdSec works by looking for aggressive IP address behavior by reading service, container or server logs. These logs can be local (Linux,  Windows) or directly from a cloud service
</p>

- [Install CrowdSec docker container](#install-crowdsec-docker-container)
- [Install firewall-bouncer on host](#install-firewall-bouncer-on-host)
- [Install sshd collections](#install-sshd-collections)
- [Backup crowdsec docker container](#backup-crowdsec-docker-container)


# Install CrowdSec docker container
- create folders

```bash
mkdir -p /opt/crowdsec/data/crowdsec/{backup,config,dbdata}
mkdir -p /opt/crowdsec/data/crowdsec/config/acquis.d
tree -L 4 /opt/crowdsec/
```

- download files
```bash
cd /opt/crowdsec
wget https://raw.githubusercontent.com/johann8/crowdsec/master/docker-compose.yml
wget https://raw.githubusercontent.com/johann8/crowdsec/master/.env
```

- edit config files
```bash
# edit docker-compose.yml
vim /opt/crowdsec/docker-compose.yml

# edit env file and set rights
vim /opt/crowdsec/.env
chmod 0600 /opt/crowdsec/.env

# add traefik acquis file
vim /opt/crowdsec/data/crowdsec/config/acquis.d/traefik.yaml
-----------------
filenames:
  - /var/log/traefik/*
labels:
  type: traefik
----------------
```

- run docker container
```bash
cd /opt/crowdsec/
docker-compose up -d
docker-compose ps
docker-compose logs
```

- run crowdsec update and upgrade 
```bash

docker exec crowdsec cscli hub update && docker exec crowdsec cscli hub upgrade
docker exec crowdsec cscli collections install crowdsecurity/traefik
```

- update crowdsec via cronjob
```bash
crontab -e
----------
# update crowdsec
0 0,6,12,18 * * * docker exec crowdsec cscli hub update > /dev/null 2>&1 && docker exec crowdsec cscli hub upgrade > /dev/null 2>&1
----------
```

- add traefik bouncer
```bash
# Get api key by running: 
docker exec crowdsec cscli bouncers add bouncer-traefik 

# edit docker-compose.yml
vim /opt/crowdsec/docker-compose.yml
----------
...
  bouncer-traefik:
    image: docker.io/fbonalair/traefik-crowdsec-bouncer:latest
    container_name: bouncer-traefik
    environment:
      # Get this api key by running `docker exec crowdsec cscli bouncers add bouncer-traefik`
      CROWDSEC_BOUNCER_API_KEY: ${CROWDSEC_BOUNCER_API_KEY}
      CROWDSEC_AGENT_HOST: crowdsec:8080
    networks:
      - proxy # same network as traefik + crowdsec
    depends_on:
      - crowdsec
    restart: unless-stopped
...
----------

# edit env file
vim /opt/crowdsec/.env
----------
...
### === Service bouncer-traefik ===
CROWDSEC_BOUNCER_API_KEY=xDI8JV87VxRK9CoH14HUHS2
...
----------
```

- change traefik config as below

```bash
vim /opt/traefik/data/conf/traefik.yml
----------
...
entryPoints:
  web:
    address: :80
    http:
      middlewares:
        - crowdsec-bouncer@file
      redirections:
        entryPoint:
          to: websecure
          scheme: https

  websecure:
    address: :443
    http:
      middlewares:
        - crowdsec-bouncer@file
...
    # Middleware for crowdsec
    crowdsec-bouncer:
      forwardauth:
        address: http://bouncer-traefik:8080/api/v1/forwardAuth
        trustForwardHeader: true
...
----------
```

- change file acquis.yaml as below
```bash

vim /opt/crowdsec/data/crowdsec/config/acquis.yaml
----------
#filenames:
#  - /var/log/nginx/*.log
#  - ./tests/nginx/nginx.log
##this is not a syslog log, indicate which kind of logs it is
#labels:
#  type: nginx
#---
#filenames:
# - /var/log/auth.log
# - /var/log/syslog
#labels:
#  type: syslog
#---
#filename: /var/log/apache2/*.log
#labels:
#  type: apache2
----------
```

- add mail notification
```bash
vim /opt/crowdsec/data/crowdsec/config/notifications/email.yaml
----------
smtp_host: mx01.mydomain.de             # example: smtp.gmail.com
smtp_username: helpdesk@mydomain.de     # Replace with your actual username
smtp_password: MySuperPassWord          # Replace with your actual password
smtp_port: 587                          # Common values are any of [25, 465, 587, 2525]
auth_type: login                        # Valid choices are "none", "crammd5", "login", "plain"
sender_name: "CrowdSec"
sender_email: helpdesk@mydomain.de      # example: foo@gmail.com
email_subject: "CrowdSec Notification"
receiver_emails:
  - admin@mydomain.de
# - email2@gmail.com
----------
```

- enable mail notification
```bash
vim /opt/crowdsec/data/crowdsec/config/profiles.yaml
----------
notifications:
#   - slack_default  # Set the webhook in /etc/crowdsec/notifications/slack.yaml before enabling this.
#   - splunk_default # Set the splunk url and token in /etc/crowdsec/notifications/splunk.yaml before enabling this.
#   - http_default   # Set the required http parameters in /etc/crowdsec/notifications/http.yaml before enabling this.
 - email_default  # Set the required email parameters in /etc/crowdsec/notifications/email.yaml before enabling this.
on_success: break
----------
```

- add host IP to custom-whitelists.yaml
```bash
vim /opt/crowdsec/data/crowdsec/config/parsers/s02-enrich/custom-whitelists.yaml
----------
name: crowdsecurity/whitelists
description: "Whitelist events from my ip addresses"
whitelist:
  reason: "my ip ranges"
  ip:
    - "161.xxx.xxx.12"     # rocky8.mydomain.de
#  cidr:
#    - "192.168.0.0/16" # Local IPs
#    - "10.0.0.0/8"     # Local IPs
#    - "172.16.0.0/12"  # Local/Docker IPs
----------
```

- restart traefik docker container
```bash
cd /opt/traefik
docker-compose down && docker-compose up -d
docker-compose ps
docker-compose logs
```

- restart crowdsec docker container
```bash
cd /opt/crowdsec/
docker-compose down && docker-compose up -d
docker-compose ps
docker-compose logs
```

- some commands
```bash
docker exec crowdsec cscli decisions list
docker exec crowdsec cscli bouncers list
docker exec crowdsec cscli parsers list
docker exec crowdsec cscli metrics
docker exec crowdsec cscli alerts list
docker exec crowdsec cscli alerts inspect 6
docker exec crowdsec cscli collections list

# ban ip
docker exec crowdsec cscli decisions add --ip 192.168.0.101

# unban ip
docker exec crowdsec cscli decisions delete --ip 192.168.0.101
```

# Install firewall-bouncer on host

- add crowdsec repo
```bash
curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.rpm.sh | sudo bash
```

- install firewall-bouncer
```bash
dnf install crowdsec-firewall-bouncer-iptables
```
- generate API Key 
```bash
docker exec crowdsec cscli bouncers add iptablesFirewallBouncer
```
- edit config file
```bash
vim /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml
------------------------------
bevor:
api_url: http://127.0.0.1:8080/
api_key:

after:
api_url: http://127.0.0.1:8085/
api_key: DH6ZT3KD+2GXg
-----------------------------
```
- run services on host
```bash
systemctl start crowdsec-firewall-bouncer 
systemctl enable crowdsec-firewall-bouncer 
systemctl status crowdsec-firewall-bouncer

# show logs
tail -f -n2000 /var/log/crowdsec-firewall-bouncer.log
```
- run test ip ban
```bash
docker exec crowdsec cscli decisions add --ip 46.xxx.xxx.108 --duration 1m
docker exec crowdsec cscli decisions list

iptables -L -n -v |grep crowdsec-blacklists

ipset list crowdsec-blacklists
ipset list crowdsec6-blacklists
```

# Install sshd collections

- install `sshd` collections
```bash
# install sshd collections
docker exec crowdsec cscli collections install crowdsecurity/sshd

# remove sshd collections
docker exec crowdsec cscli collections remove crowdsecurity/sshd

# upgrade sshd collections
docker exec crowdsec cscli collections upgrade crowdsecurity/sshd
```

- add acquis file
```bash
vim /opt/crowdsec/data/crowdsec/config/acquis.d/ssh.yaml
----------
filenames:
  - /var/log/secure
labels:
  type: syslog
----------
```

- add logfile as `volume`
```bash
vim /opt/crowdsec/docker-compose.yml
---------
...
      ### sshd log file rocky linux
      - /var/log/secure:/var/log/secure:ro
...
---------
```

- change file `0hourly` - reduces entries under `/var/log/secure`
```bash
vim /etc/cron.d/0hourly
---------
# Run the hourly jobs
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root
#01 * * * * root run-parts /etc/cron.hourly
*/10 * * * * root run-parts /etc/cron.hourly
---------
```

- restart `crowdsec` docker container
```bash
cd /opt/crowdsec/
docker-compose down && docker-compose up -d
docker-compose ps
docker-compose logs
```

# Backup crowdsec docker container

- backup crowdsec configuration
```bash
# create backup volume
DOCKERDIR=/opt/crowdsec
mkdir -p ${DOCKERDIR}/data/crowdsec/backup

# add volume
vim /opt/crowdsec/docker-compose.yml
----------
...
    volumes:
      - ${DOCKERDIR}/data/crowdsec/backup:/backup
...
----------

# recreate docker container
cd /opt/crowdsec
docker-compose up -d --force-recreate

# download script
wget -P /usr/local/bin https://raw.githubusercontent.com/johann8/crowdsec/master/backup_crowdsec_config.sh

# set rights
chmod 0700 /usr/local/bin/backup_crowdsec_config.sh
```

- create cronjob
```bash
crontab -e
----------
# backup crowdsec
1 1 * * * /usr/local/bin/backup_crowdsec_config.sh > /dev/null 2>&1
----------
```

- delete old backup folder
```bash
# download script
wget -P /usr/local/bin https://raw.githubusercontent.com/johann8/crowdsec/master/delete_crowdsec_old_backups.sh

# set rights
chmod 0700 /usr/local/bin/backup_crowdsec_config.sh

# create cronjob
crontab -e
----------
# backup crowdsec
10 1 * * * /usr/local/bin/delete_crowdsec_old_backups.sh
----------
```


Enjoy!
