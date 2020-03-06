#!/bin/bash
set -e

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

echo " "
echo "====================="
echo "* Deploying HELK *"
echo "====================="
echo " "
echo "[HELK-CLOUDFORMATION-INFO] Creating HELKNetworkStack .."
echo " "
aws --region us-east-1 cloudformation create-stack --stack-name HELKNetworkStack --template-body file://./cfn-templates/ec2-network-template.json --parameters file://./cfn-parameters/ec2-network-parameters.json
echo " "
echo "[HELK-CLOUDFORMATION-INFO] EC2 Network stack template has been sent over to AWS and it is being processed remotely .."
echo "[HELK-CLOUDFORMATION-INFO] All other instances depend on it."
echo "[HELK-CLOUDFORMATION-INFO] Waiting for HELKNetworkStack to be created.."
echo " "
aws --region us-east-1 cloudformation wait stack-create-complete --stack-name HELKNetworkStack
echo " "
echo "[HELK-CLOUDFORMATION-INFO] HELKNetworkStack was created."
echo "[HELK-CLOUDFORMATION-INFO] Creating HELKStack .."
echo "[HELK-CLOUDFORMATION-INFO] HELK stack template has been sent over to AWS and it is being processed remotely .."
echo " "
aws --region us-east-1 cloudformation create-stack --stack-name HELKStack --template-body file://./cfn-templates/helk-server-template.json --parameters file://./cfn-parameters/helk-server-parameters.json
echo " "
echo "[HELK-CLOUDFORMATION-INFO] Creating WorkstationStack .."
echo "[HELK-CLOUDFORMATION-INFO] Windows workstation stack template has been sent over to AWS and it is being processed remotely .."
echo " "
aws --region us-east-1 cloudformation create-stack --stack-name WorkstationStack --template-body file://./cfn-templates/windows-workstation-template.json --parameters file://./cfn-parameters/windows-workstation-parameters.json
echo " "
echo "[HELK-CLOUDFORMATION-INFO] You can track deployment progress via your CloudFormation Console"
echo "[HELK-CLOUDFORMATION-INFO] CloudFormation Console: https://console.aws.amazon.com/cloudformation/home?region=us-east-1 "