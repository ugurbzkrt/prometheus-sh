#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Sorry! Please run as root..."
  exit
fi

OSTYPE=$(uname -m)
USER="prometheus"
NAME="prometheus"

if [ "${OSTYPE}" = "x86_64" ]; then
    BIN="amd64"
else
    BIN="arm64"
fi

LATEST=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep "linux-${BIN}.tar.gz" | cut -d '"' -f 4 | tail -1)

cd /tmp/
curl -s -LJO $LATEST

tar -zxf $NAME-*.tar.gz -C /opt/

mv /opt/$NAME-* /opt/prometheus/
mv /opt/prometheus/prometheus /opt/prometheus/bin

cat << EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Documentation=https://github.com/flightlesstux/prometheus
Wants=network-online.target
After=network-online.target

[Service]
Restart=always
User=prometheus
Group=prometheus
Type=simple
ExecStart=/opt/prometheus/bin \
    --config.file /opt/prometheus/prometheus.yml \
    --storage.tsdb.path /opt/prometheus/tsdb/ \
    --web.console.templates=/opt/prometheus/consoles \
    --web.console.libraries=/opt/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

adduser -r -d /opt/$NAME $USER -s /sbin/nologin
chown -R $USER:$USER /opt/$NAME

systemctl enable $NAME
systemctl start $NAME
systemctl status $NAME
rm -rf /tmp/$NAME-*
