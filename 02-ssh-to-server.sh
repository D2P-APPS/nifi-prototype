#!/bin/bash

PUBLIC_IP=$(terraform output -json worker_instance | jq -r '.public_ip')
PRIVATE_PEM=$(terraform output key_private_file)

# Get the controller's SSH fingerprint.
ssh-keygen -R $PUBLIC_IP > /dev/null 2>&1
ssh-keyscan -H $PUBLIC_IP >> ~/.ssh/known_hosts 2>/dev/null

ssh  -i $PRIVATE_PEM centos@$PUBLIC_IP
