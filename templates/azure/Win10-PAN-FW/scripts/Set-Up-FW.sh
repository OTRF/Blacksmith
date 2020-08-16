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

# Set FW Creds
FW_CREDS="$ADMIN_USER:$ADMIN_PASSWORD"

# *********** Wait for PAN FW ***************
echo "$INFO_TAG Checking if PAN access is available.." >> $LOGFILE 2>&1
attempt_counter=0
max_attempts=100
until $(curl --output /dev/null --insecure --silent --head --fail https://$PRIVATE_IP/php/login.php); do
    if [ ${attempt_counter} -eq ${max_attempts} ];then
      echo "$ERROR_TAG Max attempts reached" >> $LOGFILE 2>&1
      exit 1
    fi
    echo "$INFO_TAG Waiting for PAN access to be up.." >> $LOGFILE 2>&1
    sleep 5
done

# Get API Key
echo "$INFO_TAG Getting API Key.." >> $LOGFILE 2>&1
while [ $(curl -s -k "https://$PRIVATE_IP/api/?type=keygen&user=$ADMIN_USER&password=$ADMIN_PASSWORD" -o /dev/null -w '%{http_code}') != "200" ]; do
    echo "$INFO_TAG Waiting for API access to be available.." >> $LOGFILE 2>&1
    sleep 5
done

API_RESPONSE=$(curl --silent -k "https://$PRIVATE_IP/api/?type=keygen&user=$ADMIN_USER&password=$ADMIN_PASSWORD")
API_KEY=$(echo $API_RESPONSE | sed -e 's,.*<key>\([^<]*\)</key>.*,\1,g')

# Get Admin Password-hash
echo "$INFO_TAG Getting Password Hash.." >> $LOGFILE 2>&1
while [ $(curl -s -k -u $FW_CREDS "https://$PRIVATE_IP/api/?type=op&cmd=<request><password-hash><password>$ADMIN_PASSWORD</password></password-hash></request>" -o /dev/null -w '%{http_code}') != "200" ]; do
    echo "$INFO_TAG Waiting for Password Hash access to be available.." >> $LOGFILE 2>&1
done

PW_HASH_RESPONSE=$(curl -s -k -u $FW_CREDS "https://$PRIVATE_IP/api/?type=op&cmd=<request><password-hash><password>$ADMIN_PASSWORD</password></password-hash></request>")
PW_HASH=$(echo $PW_HASH_RESPONSE | sed -e 's,.*<phash>\([^<]*\)</phash>.*,\1,g')

# Update Azure Sample XML Config (Username & Password-Hash)
echo "$INFO_TAG Updating username and password for XML config.." >> $LOGFILE 2>&1
sed -i "s|DEMO-USER|${ADMIN_USER}|g" azure-sample.xml >> $LOGFILE 2>&1
sed -i "s|DEMO-PASSWORD-HASH|${PW_HASH}|g" azure-sample.xml >> $LOGFILE 2>&1

echo "$INFO_TAG Importing PAN config.." >> $LOGFILE 2>&1
curl -k --form file=@"./azure-sample.xml" "https://$PRIVATE_IP/api/?type=import&category=configuration&key=$API_KEY" >> $LOGFILE 2>&1

echo "$INFO_TAG Loading config.." >> $LOGFILE 2>&1
curl -k -u $FW_CREDS "https://$PRIVATE_IP/api/?type=op&cmd=<load><config><from>azure-sample.xml</from></config></load>" >> $LOGFILE 2>&1

echo "$INFO_TAG Committing config.." >> $LOGFILE 2>&1
#curl -k -u $FW_CREDS "https://$PRIVATE_IP/api/?type=commit&cmd=<commit><force></force></commit>" >> $LOGFILE 2>&1

# Set up PAN FW
echo "$INFO_TAG Executing Config-PW script.." >> $LOGFILE 2>&1
python Config-FW.py $API_KEY $PRIVATE_IP >> $LOGFILE 2>&1