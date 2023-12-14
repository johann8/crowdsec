#!/bin/bash
#
#set -x

#
# --- Set Variable ---
#
TIMESTAMP=$(date +'%Y-%m-%d')

# run backup
docker exec crowdsec cscli config backup /backup/${TIMESTAMP}

# run backup no docker
# cscli config backup /var/backup/crowdsec/${TIMESTAMP}
