#!/bin/bash
set -e

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

usage(){
    echo " "
    echo "Usage: $0 [option...]" >&2
    echo
    echo "   -e             set mordor environment to build"
    echo "   -h             Prints this message"
    echo
    echo "Examples:"
    echo " $0 -e 'shire'    Deploy Mordor Shire environment"
    echo " $0 -e 'erebor'   Deploy Mordor Erebor environment"
    echo " "
    exit 1
}

# ************ Command Options **********************
while getopts e:h option
do
    case "${option}"
    in
        e) MORDOR_ENVIRONMENT=$OPTARG;;
        h | [?]) usage ; exit;;
    esac
done


# *********** Validating subscription Input ***************
case $MORDOR_ENVIRONMENT in
    shire);;
    erebor);;
    *)
        echo "[-] Not a valid subscription. Valid Options: shire or erebor"
        usage
    ;;
esac

echo " "
echo "================================="
echo "* Deploying $MORDOR_ENVIRONMENT *"
echo "================================="
echo " "
echo "[MORDOR-CLOUDFORMATION-INFO] Creating MordorNetworkStack .."
echo " "
aws --region us-east-1 cloudformation create-stack --stack-name MordorNetworkStack --template-body file://./cfn-templates/ec2-network-template.json --parameters file://./cfn-parameters/$MORDOR_ENVIRONMENT/ec2-network-parameters.json
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
aws --region us-east-1 cloudformation create-stack --stack-name MordorHELKStack --template-body file://./cfn-templates/helk-server-template.json --parameters file://./cfn-parameters/$MORDOR_ENVIRONMENT/helk-server-parameters.json
echo " "
echo "[MORDOR-CLOUDFORMATION-INFO] HELK stack template has been sent over to AWS and it is being processed remotely .."
echo "[MORDOR-CLOUDFORMATION-INFO] Creating MordorC2Stack .."
echo " "
aws --region us-east-1 cloudformation create-stack --stack-name MordorC2Stack --template-body file://./cfn-templates/c2-server-template.json --parameters file://./cfn-parameters/$MORDOR_ENVIRONMENT/c2-server-parameters.json
echo " "
echo "[MORDOR-CLOUDFORMATION-INFO] C2 stack template has been sent over to AWS and it is being processed remotely .."
echo "[MORDOR-CLOUDFORMATION-INFO] Creating MordorWindowsDCStack .."
echo " "
aws --region us-east-1 cloudformation create-stack --stack-name MordorWindowsDCStack --template-body file://./cfn-templates/windows-dc-template.json --parameters file://./cfn-parameters/$MORDOR_ENVIRONMENT/windows-dc-parameters.json
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
aws --region us-east-1 cloudformation create-stack --stack-name MordorWindowsServersStack --template-body file://./cfn-templates/windows-servers-template.json --parameters file://./cfn-parameters/$MORDOR_ENVIRONMENT/windows-servers-parameters.json
echo " "
echo "[MORDOR-CLOUDFORMATION-INFO] Servers stack template has been sent over to AWS and it is being processed remotely .."
echo " "
echo "[MORDOR-CLOUDFORMATION-INFO] Creating MordorWindowsWorkstationsStack .."
aws --region us-east-1 cloudformation create-stack --stack-name MordorWindowsWorkstationsStack --template-body file://./cfn-templates/windows-workstations-template.json --parameters file://./cfn-parameters/$MORDOR_ENVIRONMENT/windows-workstations-parameters.json
echo " "
echo "[MORDOR-CLOUDFORMATION-INFO] Workstations stack template has been sent over to AWS and it is being processed remotely .."
echo "[MORDOR-CLOUDFORMATION-INFO] No other stack depends on Workstations or Servers"
echo "[MORDOR-CLOUDFORMATION-INFO] You can track deployment progress via your CloudFormation Console"
echo "[MORDOR-CLOUDFORMATION-INFO] CloudFormation Console: https://console.aws.amazon.com/cloudformation/home?region=us-east-1 "