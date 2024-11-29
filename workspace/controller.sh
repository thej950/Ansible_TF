#! bin/bash
apt update -y
apt install -y software-properties-common
apt-add-repository ppa:ansible/ansible
apt update -y
apt install -y ansible

cd /home/ubuntu/
git clone https://github.com/thej950/playbooks01.git

