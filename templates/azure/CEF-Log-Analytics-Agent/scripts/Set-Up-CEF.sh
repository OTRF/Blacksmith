#!/bin/bash

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# *********** log tagging variables ***********
INFO_TAG="[INSTALLATION-INFO]"
ERROR_TAG="[INSTALLATION-ERROR]"

# *********** Set Log File ***************
LOGFILE="/var/log/FW-SETUP.log"
echoerror() {
    printf "${RC} * ERROR${EC}: $@\n" 1>&2;
}

# *********** helk function ***************
usage(){
    echo " "
    echo "Usage: $0 [option...]" >&2
    echo
    echo "   -w         Azure Sentinel Workspace ID"
    echo "   -k         Azure Sentinel Workspace Key"
    echo
    echo "Examples:"
    echo " $0 -w xxxxx -k xxxxxx"
    echo " "
    exit 1
}

# ************ Command Options **********************
while getopts w:k:h option
do
    case "${option}"
    in
        w) WORKSPACE_ID=$OPTARG;;
        k) WORKSPACE_KEY=$OPTARG;;
        h) usage;;
        \?) usage;;
        :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
        *  ) echo "Unimplemented option: -$OPTARG" >&2; exit 1;;
    esac
done

if ((OPTIND == 1))
then
    echo "$ERROR_TAG No options specified"
    usage
fi

######################
# SYSLOG SERVER SETUP
######################
python cef_installer.py $WORKSPACE_ID $WORKSPACE_KEY