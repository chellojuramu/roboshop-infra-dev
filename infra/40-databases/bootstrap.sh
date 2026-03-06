#!/bin/bash

# 1. Capture variables from Terraform
component=$1
environment=$2

# 2. Log start time (Senior DevOps Best Practice for debugging)
echo "Starting bootstrap for ${component} in ${environment} at $(date)"

# 3. Install Ansible
dnf install ansible -y

# 4. Setup Workspace
cd /home/ec2-user
# Use conditional cloning so it doesn't fail if the folder already exists
if [ ! -d "ansible-roboshop-roles-tf" ]; then
    git clone https://github.com/chellojuramu/ansible-roboshop-roles-tf.git
fi

cd ansible-roboshop-roles-tf
git pull

# 5. Execute Playbook with Explicit Variables
# Note: We use double quotes around variables to prevent shell splitting errors
ansible-playbook -e "component=${component}" -e "environment=${environment}" roboshop.yaml