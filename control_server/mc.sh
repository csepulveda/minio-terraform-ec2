#!/bin/bash
curl https://s3.amazonaws.com/mdstrm-builds/mc -o /usr/local/bin/mc
chmod +x /usr/local/bin/mc
export NODES=$(cat /tmp/nodes)
export LOCALIP=$(ip a | grep 'inet 172' | awk '{print $2}' | sed 's/\/24//g')
STOP=0
while [ $STOP -eq 0 ]; do
    TOTALNODES=$(curl -s $LOCALIP:8500/v1/agent/services | jq -c '.[] | select(.Service == "minio") | [.Address,.Port,.Meta.path]' | wc -l)
    if [ $TOTALNODES -eq $NODES ]; then
        let "STOP++"
        SERVERS=$(curl -s $LOCALIP:8500/v1/agent/services | jq -c '.[] | select(.Service == "minio") | "http://"+.Address+":9000"' | tr '\n' ' ' | sed 's/\"//g')
    else
        sleep 10;
    fi
done
sleep 60
for i in $SERVERS; do /usr/local/bin/mc config host add minio $i $(cat /tmp/MINIO_ACCESS_KEY) $(cat /tmp/MINIO_SECRET_KEY) S3v4; done
/usr/local/bin/mc mb minio/testbucket
/usr/local/bin/mc events add minio/testbucket arn:minio:sqs::1:redis
