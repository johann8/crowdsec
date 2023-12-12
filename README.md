<h1 align="center">CrowdSec</h1>

<p align='justify'>

<a href="https://www.crowdsec.net/">CrowdSec</a> - an open source software for identifying and sharing malicious IP addresses.

CrowdSec works by looking for aggressive IP address behavior by reading service, container or server logs. These logs can be local (Linux,  Windows) or directly from a cloud service
</p>

- [Install CrowdSec docker container](#install-crowdsec-docker-container)
  - [Setup Timezone](#setup-timezone)
  - [Setup General](#setup-general)

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

- config files

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
- 
```bash

```

```bash

```

```bash

```

```bash

```

```bash

```

```bash

```

```bash

```

