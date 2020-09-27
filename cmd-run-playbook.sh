#!/bin/bash

if [ ! -f inventory ]
then
    echo "Missing inventory file."
    exit 1
fi

IP=$(cat inventory | tail -n 1)

ANSIBLE_PLAYBOOK=$(which ansible-playbook)
AWS_REGION=us-east-1

INSTANCE_ID=$(terraform output worker_instance_id)
NOW=$(date '+%Y%m%d%H%M%S')
SSH_USER=$(terraform output ssh_user)
VPC_NAME=$(terraform output vpc_name)

export ANSIBLE_HOST_KEY_CHECKING=False

python3 \
  $ANSIBLE_PLAYBOOK \
  -vvv \
  --extra-var aws_region=$AWS_REGION \
  --extra-var instance_id=$INSTANCE_ID \
  --extra-var now=$NOW \
  --extra-var ssh_user=$SSH_USER \
  --extra-var vpc_name=$VPC_NAME \
  -i "$IP," \
  -u centos \
  playbook.worker.yml

aws ec2 create-image \
  --instance-id $INSTANCE_ID \
  --name "$VPC_NAME-base-$NOW" \
  --reboot
