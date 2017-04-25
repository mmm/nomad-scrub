#!/bin/bash

usage() {
  echo "Usage $0 <role> <server_ip>
  where role is `server` or `client`
  and where server_ip is ipv4 for a consul/nomad server"
  exit 1
}
(( $# == 2 )) || usage

case "$1" in
  server)
    SERVER_ENABLED=true
    CLIENT_ENABLED=false
    ;;
  client)
    SERVER_ENABLED=false
    CLIENT_ENABLED=true
    ;;
esac

SERVER_IP=$2

logger "running nomad provisioner"

install_packages() {
  apt-get -qq update

  apt-get -qq -y install wget curl bash-completion unzip dnsmasq awscli jq
}
install_packages

install_consul() {
  wget -nv -O /tmp/consul_0.8.1_linux_amd64.zip "https://releases.hashicorp.com/consul/0.8.1/consul_0.8.1_linux_amd64.zip"
  unzip /tmp/consul*.zip
  chmod +x consul
  mv consul /usr/bin/consul
  mkdir -p /etc/consul.d/
  mkdir -p /var/lib/consul/
  mkdir -p /usr/share/consul/

cat >/etc/consul.d/consul.json <<EOL
{
  "datacenter": "us-west-2",
  "rejoin_after_leave": true,
  "domain": "consul",
  "server": $SERVER_ENABLED,
  "bootstrap_expect": $([ "$SERVER_ENABLED" == "true" ] && echo 1 || echo 0),
  "data_dir": "/var/lib/consul",
  "ui_dir": "/usr/share/consul",
  "disable_remote_exec": true,
  "http_api_response_headers": {
    "Access-Control-Allow-Origin": "*"
  },
  "dns_config": {
    "allow_stale": true,
    "max_stale": "5s"
  }
}
EOL
cat >/etc/systemd/system/consul.service <<EOL
[Unit]
Description=Consul Agent
After=dnsmasq.service

[Service]
Environment=GOMAXPROCS=`nproc`
ExecStart=/usr/bin/consul agent -config-dir=/etc/consul.d

[Install]
WantedBy=default.target
EOL
  service consul restart
  sleep 5 
  consul join $SERVER_IP
}
install_consul

install_nomad() {
  wget -nv -O /tmp/nomad_0.5.6_linux_amd64.zip "https://releases.hashicorp.com/nomad/0.5.6/nomad_0.5.6_linux_amd64.zip"
  unzip /tmp/nomad*.zip
  chmod +x nomad
  mv nomad /usr/bin/nomad
  mkdir -p /etc/nomad.d/
  mkdir -p /var/lib/nomad/

cat >/etc/nomad.d/nomad.hcl <<EOL
datacenter="us-west-2"
data_dir = "/var/lib/nomad"
bind_addr = "0.0.0.0"
server {
  enabled = $SERVER_ENABLED
  bootstrap_expect = $([ "$SERVER_ENABLED" == "true" ] && echo 1 || echo 0)
}
client {
  enabled = $CLIENT_ENABLED
  options = {
    "driver.raw_exec.enable" = "1"
  }
}
EOL
cat >/etc/systemd/system/nomad.service <<EOL
[Unit]
Description=Nomad Agent
After=consul.service

[Service]
Environment=GOMAXPROCS=`nproc`
ExecStart=/usr/bin/nomad agent -config=/etc/nomad.d/

[Install]
WantedBy=default.target
EOL
service nomad restart
}
install_nomad

logger "done"
