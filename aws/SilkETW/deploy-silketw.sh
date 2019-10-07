#!/bin/bash
set -e

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

echo " "
echo "====================="
echo "* Deploying SilkETW *"
echo "====================="
echo " "
echo "[SilkETW-CLOUDFORMATION-INFO] Creating SilkETWNetworkStack .."
echo " "
aws --region us-east-1 cloudformation create-stack --stack-name SilkETWNetworkStack --template-body file://./cfn-templates/ec2-network-template.json --parameters file://./cfn-parameters/ec2-network-parameters.json
echo " "
echo "[SilkETW-CLOUDFORMATION-INFO] EC2 Network stack template has been sent over to AWS and it is being processed remotely .."
echo "[SilkETW-CLOUDFORMATION-INFO] All other instances depend on it."
echo "[SilkETW-CLOUDFORMATION-INFO] Waiting for SilkETWNetworkStack to be created.."
echo " "
aws --region us-east-1 cloudformation wait stack-create-complete --stack-name SilkETWNetworkStack
echo " "
echo "[SilkETW-CLOUDFORMATION-INFO] SilkETWNetworkStack was created."
echo "[SilkETW-CLOUDFORMATION-INFO] Creating SilkETWHELKStack .."
echo "[SilkETW-CLOUDFORMATION-INFO] HELK stack template has been sent over to AWS and it is being processed remotely .."
echo " "
aws --region us-east-1 cloudformation create-stack --stack-name SilkETWHELKStack --template-body file://./cfn-templates/helk-server-template.json --parameters file://./cfn-parameters/helk-server-parameters.json
echo " "
echo "[SilkETW-CLOUDFORMATION-INFO] Creating SilkETWWindowsWorkstationsStack .."
aws --region us-east-1 cloudformation create-stack --stack-name SilkETWWindowsWorkstationsStack --template-body file://./cfn-templates/windows-workstations-template.json --parameters file://./cfn-parameters/windows-workstations-parameters.json
echo " "
echo "[SilkETW-CLOUDFORMATION-INFO] Workstations stack template has been sent over to AWS and it is being processed remotely .."
echo "[SilkETW-CLOUDFORMATION-INFO] You can track deployment progress via your CloudFormation Console"
echo "[SilkETW-CLOUDFORMATION-INFO] CloudFormation Console: https://console.aws.amazon.com/cloudformation/home?region=us-east-1 "