#!/bin/bash
set -e

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

echo "[MORDOR-CLOUDFORMATION-INFO] Creating MordorNetworkStack .."
echo " "
aws --region us-east-1 cloudformation create-stack --stack-name MordorNetworkStack --template-body file://./Mordor-EC2-Network.json --parameters file://mordor-shire-parameters/shire-parameters-network.json
echo " "
echo "[MORDOR-CLOUDFORMATION-INFO] EC2 Network stack template has been sent over to AWS and it is being processed remotely .."
echo "[MORDOR-CLOUDFORMATION-INFO] All other instances depend on it."
echo "[MORDOR-CLOUDFORMATION-INFO] Waiting for MordorNetworkStack to be created.."
echo " "
aws --region us-east-1 cloudformation wait stack-create-complete --stack-name MordorNetworkStack
echo " "
echo "[MORDOR-CLOUDFORMATION-INFO] MordorNetworkStack was created."
echo "[MORDOR-CLOUDFORMATION-INFO] Creating MordorHELKStack .."
echo " "
aws --region us-east-1 cloudformation create-stack --stack-name MordorHELKStack --template-body file://./Mordor-HELK-Server.json --parameters file://mordor-shire-parameters/shire-parameters-helk.json
echo " "
echo "[MORDOR-CLOUDFORMATION-INFO] HELK stack template has been sent over to AWS and it is being processed remotely .."
echo "[MORDOR-CLOUDFORMATION-INFO] Creating MordorC2Stack .."
echo " "
aws --region us-east-1 cloudformation create-stack --stack-name MordorC2Stack --template-body file://./Mordor-C2-Server.json --parameters file://mordor-shire-parameters/shire-parameters-c2.json
echo " "
echo "[MORDOR-CLOUDFORMATION-INFO] C2 stack template has been sent over to AWS and it is being processed remotely .."
echo "[MORDOR-CLOUDFORMATION-INFO] Creating MordorWindowsDCStack .."
echo " "
aws --region us-east-1 cloudformation create-stack --stack-name MordorWindowsDCStack --template-body file://./Mordor-Windows-DC.json --parameters file://mordor-shire-parameters/shire-parameters-dc.json
echo " "
echo "[MORDOR-CLOUDFORMATION-INFO] DC stack template has been sent over to AWS and it is being processed remotely .."
echo "[MORDOR-CLOUDFORMATION-INFO] All other Windows instances depend on it."
echo "[MORDOR-CLOUDFORMATION-INFO] Waiting for MordorWindowsDCStack to be created.."
echo " "
aws --region us-east-1 cloudformation wait stack-create-complete --stack-name MordorWindowsDCStack
echo " "
echo "[MORDOR-CLOUDFORMATION-INFO] MordorWindowsDCStack was created."
echo "[MORDOR-CLOUDFORMATION-INFO] Creating MordorWindowsServersStack .."
echo " "
aws --region us-east-1 cloudformation create-stack --stack-name MordorWindowsServersStack --template-body file://./Mordor-Windows-Servers.json --parameters file://mordor-shire-parameters/shire-parameters-servers.json
echo " "
echo "[MORDOR-CLOUDFORMATION-INFO] Servers stack template has been sent over to AWS and it is being processed remotely .."
echo " "
echo "[MORDOR-CLOUDFORMATION-INFO] Creating MordorWindowsWorkstationsStack .."
aws --region us-east-1 cloudformation create-stack --stack-name MordorWindowsWorkstationsStack --template-body file://./Mordor-Windows-Workstations.json --parameters file://mordor-shire-parameters/shire-parameters-workstations.json
echo " "
echo "[MORDOR-CLOUDFORMATION-INFO] Workstations stack template has been sent over to AWS and it is being processed remotely .."
echo "[MORDOR-CLOUDFORMATION-INFO] No other stack depends on Workstations or Servers"
echo "[MORDOR-CLOUDFORMATION-INFO] You can track deployment progress via your CloudFormation Console"
echo "[MORDOR-CLOUDFORMATION-INFO] CloudFormation Console: https://console.aws.amazon.com/cloudformation/home?region=us-east-1 "