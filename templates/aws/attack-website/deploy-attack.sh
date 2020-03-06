#!/bin/bash
set -e

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

echo " "
echo "====================="
echo "* Deploying ATTACK *"
echo "====================="
echo " "
echo "[ATTACK-CLOUDFORMATION-INFO] Creating ATTACKNetworkStack .."
echo " "
aws --region us-east-1 cloudformation create-stack --stack-name ATTACKNetworkStack --template-body file://./cfn-templates/ec2-network-template.json --parameters file://./cfn-parameters/ec2-network-parameters.json
echo " "
echo "[ATTACK-CLOUDFORMATION-INFO] EC2 Network stack template has been sent over to AWS and it is being processed remotely .."
echo "[ATTACK-CLOUDFORMATION-INFO] All other instances depend on it."
echo "[ATTACK-CLOUDFORMATION-INFO] Waiting for ATTACKNetworkStack to be created.."
echo " "
aws --region us-east-1 cloudformation wait stack-create-complete --stack-name ATTACKNetworkStack
echo " "
echo "[ATTACK-CLOUDFORMATION-INFO] ATTACKNetworkStack was created."
echo "[ATTACK-CLOUDFORMATION-INFO] Creating ATTACKStack .."
echo "[ATTACK-CLOUDFORMATION-INFO] ATTACK stack template has been sent over to AWS and it is being processed remotely .."
echo " "
aws --region us-east-1 cloudformation create-stack --stack-name ATTACKStack --template-body file://./cfn-templates/attack-server-template.json --parameters file://./cfn-parameters/ATTACK-server-parameters.json
echo " "
echo "[ATTACK-CLOUDFORMATION-INFO] You can track deployment progress via your CloudFormation Console"
echo "[ATTACK-CLOUDFORMATION-INFO] CloudFormation Console: https://console.aws.amazon.com/cloudformation/home?region=us-east-1 "