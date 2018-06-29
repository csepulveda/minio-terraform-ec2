#!/bin/bash
IP=$(ip a | grep 'inet 172' | awk '{print $2}' | sed 's/\/24//g')
HOSTNAME=$(hostname)
CONSUL=$(cat /tmp/consul.ip)
DATAPATH=$(echo data)
mkfs.ext4 /dev/xvdb
apt install jq -y
mkdir /$DATAPATH
mount /dev/xvdb /$DATAPATH
chmod 777 /$DATAPATH
curl https://s3.amazonaws.com/mdstrm-builds/minio -o /usr/local/bin/minio
chmod a+x /usr/local/bin/minio
sed -i  "s/IP/$IP/g" /tmp/minio.json
sed -i "s/hostname/$HOSTNAME/g" /tmp/minio.json
sed -i "s/data/$DATAPATH/g" /tmp/minio.json
sed -i "s/127.0.0.1/$CONSUL/g" /tmp/config.json
curl -X PUT -d @/tmp/minio.json $CONSUL:8500/v1/agent/service/register
tmux new-session -d -s minio "bash -x /tmp/startminio.sh"
exit 0