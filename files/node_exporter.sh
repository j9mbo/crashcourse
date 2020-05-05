#/!bin/bash

sudo useradd node_exporter -s /sbin/nologin

#download node exporter file
wget https://github.com/prometheus/node_exporter/releases/download/v1.0.0-rc.0/node_exporter-1.0.0-rc.0.linux-amd64.tar.gz
sudo tar xvfz node_exporter-1.0.0-rc.0.linux-amd64.tar.gz
sudo cp -r node_exporter-1.0.0-rc.0.linux-amd64 /usr/sbin/
sudo cp /usr/sbin/node_exporter-1.0.0-rc.0.linux-amd64/node_exporter /usr/sbin/

#create systemd-service file in /etc/systemd/system/node_exporter.service
sudo touch /etc/systemd/system/node_exporter.service
sudo chmod a+x /etc/systemd/system/node_exporter.service
sudo sh -c 'cat << EOF >> /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
[Service]
User=node_exporter
EnvironmentFile=/etc/sysconfig/node_exporter
ExecStart=/usr/sbin/node_exporter $OPTIONS
[Install]
WantedBy=multi-user.target
EOF'

#create sysconfig file
sudo mkdir -p /etc/sysconfig
sudo touch /etc/sysconfig/node_exporter
sudo sh -c 'cat << EOF >> /etc/sysconfig/node_exporter
OPTIONS="--collector.textfile.directory /var/lib/node_exporter/textfile_collector"
EOF'

#reload systemd and enable node_exporter
sudo systemctl daemon-reload
sudo systemctl enable node_exporter

#start service node_exporter
sudo systemctl start node_exporter
sudo systemctl status node_exporter

#open port 9100
sudo ufw allow 9100
