#!/bin/bash
export NODES=$(cat /tmp/nodes)
export MINIO_ACCESS_KEY=$(cat /tmp/MINIO_ACCESS_KEY)
export MINIO_SECRET_KEY=$(cat /tmp/MINIO_SECRET_KEY)
STOP=0
while [ $STOP -eq 0 ]; do
    TOTALNODES=$(curl -s $(cat /tmp/consul.ip):8500/v1/agent/services | jq -c '.[] | select(.Service == "minio") | [.Address,.Port,.Meta.path]' | wc -l)
    if [ $TOTALNODES -eq $NODES ]; then
        let "STOP++"
        SERVERS=$(curl -s $(cat /tmp/consul.ip):8500/v1/agent/services | jq -c '.[] | select(.Service == "minio") | "http://"+.Address+"/"+.Meta.path' | tr '\n' ' ' | sed 's/\"//g')
    else
        sleep 30;
    fi
done
mkdir ~/.minio
cp /tmp/config.json ~/.minio/config.json
/usr/local/bin/minio server $SERVERS