#!/bin/bash
set -e

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

echo " "
echo "====================="
echo "* Deploying Empire *"
echo "====================="
echo " "
echo "[Empire-CLOUDFORMATION-INFO] Creating EmpireNetworkStack .."
echo " "
aws --region us-east-1 cloudformation create-stack --stack-name EmpireNetworkStack --template-body file://./cfn-templates/ec2-network-template.json --parameters file://./cfn-parameters/ec2-network-parameters.json
echo " "
echo "[Empire-CLOUDFORMATION-INFO] EC2 Network stack template has been sent over to AWS and it is being processed remotely .."
echo "[Empire-CLOUDFORMATION-INFO] All other instances depend on it."
echo "[Empire-CLOUDFORMATION-INFO] Waiting for EmpireNetworkStack to be created.."
echo " "
aws --region us-east-1 cloudformation wait stack-create-complete --stack-name EmpireNetworkStack
echo " "
echo "[Empire-CLOUDFORMATION-INFO] EmpireNetworkStack was created."
echo "[Empire-CLOUDFORMATION-INFO] Creating EmpireStack .."
echo "[Empire-CLOUDFORMATION-INFO] Empire stack template has been sent over to AWS and it is being processed remotely .."
echo " "
aws --region us-east-1 cloudformation create-stack --stack-name EmpireStack --template-body file://./cfn-templates/c2-server-template.json --parameters file://./cfn-parameters/c2-server-parameters.json
echo " "
echo "[Empire-CLOUDFORMATION-INFO] You can track deployment progress via your CloudFormation Console"
echo "[Empire-CLOUDFORMATION-INFO] CloudFormation Console: https://console.aws.amazon.com/cloudformation/home?region=us-east-1 "