#!/bin/bash

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

usage(){
    echo " "
    echo "Usage: $0 [option...]" >&2
    echo
    echo "   -k         set Key Pair Name"
    echo "   -p         set Public IP Address"
    echo "   -h         help menu"
    echo
    echo "Examples:"
    echo " $0 -k aws-ubuntu-key -p x.x.x.x"
    echo " "
    exit 1
}

# ************ Mordor Shire **********************
# ************ Command Options **********************
while getopts k:p:h option
do
    case "${option}"
    in
        k) KEY_PAIR_NAME=$OPTARG;;
        p) PUBLIC_IP=$OPTARG;;
        h) usage;;
        \?) usage;;
        :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
        *  ) echo "Unimplemented option: -$OPTARG" >&2; exit 1;;
    esac
done

if ((OPTIND == 1))
then
    echo "No options specified"
    usage
fi

if [[ "$PUBLIC_IP" =~ ^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$ ]]; then
    for i in 1 2 3 4; do
        if [ $(echo "$PUBLIC_IP" | cut -d. -f$i) -gt 255 ]; then
            echo "$PUBLIC_IP is not a valid IP Address"
            usage
        fi
    done
fi

echo " "
echo "[MORDOR-CLOUDFORMATION-INFO] Using Key Pair Name: $KEY_PAIR_NAME ..."
echo "[MORDOR-CLOUDFORMATION-INFO] Allow connections from public IP: $PUBLIC_IP ..."
echo " "
echo "[MORDOR-CLOUDFORMATION-INFO] Deploying EC2 Network resources ..."
echo "[MORDOR-CLOUDFORMATION-INFO] All other instances depend on it."
echo "[MORDOR-CLOUDFORMATION-INFO] EC2 Network teamplate has been sent over to AWS and it is being processed remotely.."
echo " "
aws --region us-east-1 cloudformation deploy --template-file Mordor-Shire-EC2-Network.json --stack-name MordorNetworkStack --parameter-overrides KeyName=$KEY_PAIR_NAME RestrictLocation=$PUBLIC_IP/32

echo " "
echo "[MORDOR-CLOUDFORMATION-INFO] HELK Server template has been send over to AWS and it is being processed remotely ..."
echo " "
aws --region us-east-1 cloudformation create-stack --stack-name MordorHELKStack --template-body file://./Mordor-Shire-HELK-Server.json --parameters ParameterKey=KeyName,ParameterValue=$KEY_PAIR_NAME ParameterKey=NetworkStackName,ParameterValue=MordorNetworkStack

echo " "
echo "[MORDOR-CLOUDFORMATION-INFO] C2 Server template has been send over to AWS and it is being processed remotely ..."
echo " "
aws --region us-east-1 cloudformation create-stack --stack-name MordorC2Stack --template-body file://./Mordor-Shire-C2-Server.json --parameters ParameterKey=KeyName,ParameterValue=$KEY_PAIR_NAME ParameterKey=NetworkStackName,ParameterValue=MordorNetworkStack

echo " "
echo "[MORDOR-CLOUDFORMATION-INFO] Deploying Domain Controller Instance ..."
echo "[MORDOR-CLOUDFORMATION-INFO] All other Windows instances depend on it."
echo "[MORDOR-CLOUDFORMATION-INFO] Domain Controller template has been send over to AWS and it is being processed remotely ..."
echo " "
aws --region us-east-1 cloudformation deploy --template-file Mordor-Shire-Windows-DC.json --stack-name MordorWindowsServersStack --parameter-overrides KeyName=$KEY_PAIR_NAME NetworkStackName=MordorNetworkStack

echo " "
echo "[MORDOR-CLOUDFORMATION-INFO] Windows Workstations and WEC server template has been send over to AWS and it is being processed remotely ..."
echo " "
aws --region us-east-1 cloudformation create-stack --stack-name MordorWindowsWorkstationsStack --template-body file://./Mordor-Shire-Windows-Workstations.json --parameters ParameterKey=KeyName,ParameterValue=$KEY_PAIR_NAME ParameterKey=NetworkStackName,ParameterValue=MordorNetworkStack ParameterKey=DCStackName,ParameterValue=MordorWindowsServersStack

echo " "
echo "[MORDOR-CLOUDFORMATION-INFO] Please go to https://console.aws.amazon.com/cloudformation/home?region=us-east-1 to monitor your Mordor stacks and track deployment progress .."