#!/bin/bash

component=$1
env=$2

dnf install ansible -y

cd /home/ec2-user
git clone https://github.com/chellojuramu/ansible-roboshop-roles-tf

cd ansible-roboshop-roles-tf
git pull

ansible-playbook -e "component=$component" -e "env=$env" roboshop.yaml