#!/bin/bash

component=$1
environment=$2
app_version=$3
dnf install ansible -y

cd /home/ec2-user
git clone https://github.com/chellojuramu/ansible-roboshop-roles-tf

cd ansible-roboshop-roles-tf
git pull
ansible-playbook -e component=$component -e env=$environment -e app_version=$app_version roboshop.yaml