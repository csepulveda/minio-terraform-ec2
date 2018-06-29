#!/bin/bash
apt install redis-server unzip jq -y

sed -i "s/127.0.0.1/0.0.0.0/g" /etc/redis/redis.conf
service redis-server restart

curl  -s https://releases.hashicorp.com/consul/1.2.0/consul_1.2.0_linux_amd64.zip -o consul_1.2.0_linux_amd64.zip
unzip consul_1.2.0_linux_amd64.zip
mv consul /usr/local/bin/consul
chmod a+x /usr/local/bin/consul
tmux new-session -d -s minio "/usr/local/bin/consul agent -server -bootstrap -data-dir /tmp/consul -client $(ip a | grep 'inet 172' | awk '{print $2}' | sed 's/\/24//g')"
tmux new-session -d -s mc "bash -x /tmp/mc.sh 2>&1 | tee /tmp/log "
exit 0