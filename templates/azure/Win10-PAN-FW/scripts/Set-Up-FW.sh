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
    echo "   -u         Admin Username"
    echo "   -p         Admin Password"
    echo "   -i         FW Private IP Address"
    echo
    echo "Examples:"
    echo " $0 -u wardog -p xxasfsdfsdf -i x.x.x.x"
    echo " "
    exit 1
}

# ************ Command Options **********************
while getopts u:p:i:h option
do
    case "${option}"
    in
        u) ADMIN_USER=$OPTARG;;
        p) ADMIN_PASSWORD=$OPTARG;;
        i) PRIVATE_IP=$OPTARG;;
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
# PAN FIREWALL SETUP
######################

# Set FW Creds
FW_CREDS="$ADMIN_USER:$ADMIN_PASSWORD"

# *********** Wait for PAN FW ***************
until curl --silent -k -X GET curl -k -X GET "https://$PRIVATE_IP/api/?type=keygen&user=$ADMIN_USER&password=$ADMIN_PASSWORD" --output /dev/null; do
    echo "$INFO_TAG Waiting for PAN FW to be up.." >> $LOGFILE 2>&1
    sleep 5
done

# Get API Key
echo "$INFO_TAG Getting API Key.." >> $LOGFILE 2>&1
API_RESPONSE=$(curl --silent -k -X GET curl -k -X GET "https://$PRIVATE_IP/api/?type=keygen&user=$ADMIN_USER&password=$ADMIN_PASSWORD")
API_KEY=$(echo $API_RESPONSE | sed -e 's,.*<key>\([^<]*\)</key>.*,\1,g')

# Get Admin Password-hash
echo "$INFO_TAG Getting Password Hash.." >> $LOGFILE 2>&1
PW_HASH_RESPONSE=$(curl --silent -k -u $FW_CREDS -X GET "https://$PRIVATE_IP/api/?type=op&cmd=<request><password-hash><password>$ADMIN_PASSWORD</password></password-hash></request>")
PW_HASH=$(echo $PW_HASH_RESPONSE | sed -e 's,.*<phash>\([^<]*\)</phash>.*,\1,g')

# Update Azure Sample XML Config (Username & Password-Hash)
echo "$INFO_TAG Updating username and password for XML config.." >> $LOGFILE 2>&1
sed -i "s|DEMO-USER|${ADMIN_USER}|g" azure-sample.xml >> $LOGFILE 2>&1
sed -i "s|DEMO-PASSWORD-HASH|${PW_HASH}|g" azure-sample.xml >> $LOGFILE 2>&1

# Set up PAN FW
echo "$INFO_TAG Executing Config-PW script.." >>$LOGFILE 2>&1
python Config-FW.py $API_KEY $PRIVATE_IP >> $LOGFILE 2>&1