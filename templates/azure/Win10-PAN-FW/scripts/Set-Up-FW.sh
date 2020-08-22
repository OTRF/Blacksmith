#!/bin/bash

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0
# References:
# https://knowledgebase.paloaltonetworks.com/KCSArticleDetail?id=kA10g000000ClexCAC
# https://docs.paloaltonetworks.com/pan-os/9-0/pan-os-panorama-api/pan-os-xml-api-request-types/commit-configuration-api/commit

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
    echo "   -s         All subnets to update XML config (Array)"
    echo "   -a         All private IP addresses to update XML config (Array)"
    echo "   -t         Untrusted and trusted hops IP addresses to update XML config (Array)"
    echo
    echo "Examples:"
    echo " $0 -u wardog -p xxasfsdfsdf -i x.x.x.x -s 10.2.2.0/24,10.2.3.0/24 -a 10.2.1.4,10.2.3.4 -t 10.2.1.1,10.2.2.1"
    echo " "
    exit 1
}

# ************ Command Options **********************
while getopts u:p:i:s:a:t:h option
do
    case "${option}"
    in
        u) ADMIN_USER=$OPTARG;;
        p) ADMIN_PASSWORD=$OPTARG;;
        i) FW_PRIVATE_IP=$OPTARG;;
        s) ALL_SUBNETS=$OPTARG;;
        a) ALL_PRIVATE_IPS=$OPTARG;;
        t) ALL_HOP_IPS=$OPTARG;;
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

######################
# Checking PAN Access
######################

attempt_counter=0
max_attempts=250
echo "$INFO_TAG Checking if PAN access is available.." >> $LOGFILE 2>&1
while [ $(curl -s -k https://$FW_PRIVATE_IP/php/login.php -o /dev/null -w '%{http_code}') != "200" ]; do
    if [ ${attempt_counter} -eq ${max_attempts} ];then
      echo "$ERROR_TAG Max attempts reached" >> $LOGFILE 2>&1
      exit 1
    fi
    echo "$INFO_TAG Waiting for PAN access to be up.." >> $LOGFILE 2>&1
    attempt_counter=$((attempt_counter + 1))
    sleep 5
done

##################
# Getting API Key
##################

echo "$INFO_TAG Getting API Key.." >> $LOGFILE 2>&1
while [ $(curl -s -k -G --data-urlencode "type=keygen" --data-urlencode "user=$ADMIN_USER" --data-urlencode "password=$ADMIN_PASSWORD" "https://$FW_PRIVATE_IP/api/" -o /dev/null -w '%{http_code}') != "200" ]; do
    echo "$INFO_TAG Waiting for API access to be available.." >> $LOGFILE 2>&1
    sleep 5
done

API_RESPONSE=$(curl -s -k -G --data-urlencode "type=keygen" --data-urlencode "user=$ADMIN_USER" --data-urlencode "password=$ADMIN_PASSWORD" "https://$FW_PRIVATE_IP/api/")
API_KEY=$(echo $API_RESPONSE | sed -e 's,.*<key>\([^<]*\)</key>.*,\1,g')

########################
# Getting Password Hash
########################

echo "$INFO_TAG Getting Password Hash.." >> $LOGFILE 2>&1
while [ $(curl -s -k -u $FW_CREDS -G --data-urlencode "type=op" --data-urlencode "cmd=<request><password-hash><password>$ADMIN_PASSWORD</password></password-hash></request>" "https://$FW_PRIVATE_IP/api/" -o /dev/null -w '%{http_code}') != "200" ]; do
    echo "$INFO_TAG Waiting for Password Hash access to be available.." >> $LOGFILE 2>&1
    sleep 5
done

PW_HASH_RESPONSE=$(curl -s -k -u $FW_CREDS -G --data-urlencode "type=op" --data-urlencode "cmd=<request><password-hash><password>$ADMIN_PASSWORD</password></password-hash></request>" "https://$FW_PRIVATE_IP/api/")
PW_HASH=$(echo $PW_HASH_RESPONSE | sed -e 's,.*<phash>\([^<]*\)</phash>.*,\1,g')

######################
# Updating XML Config
######################

echo "$INFO_TAG Updating username and password for XML config.." >> $LOGFILE 2>&1
sed -i "s|DEMO-USER|${ADMIN_USER}|g" azure-sample.xml >> $LOGFILE 2>&1
sed -i "s|DEMO-PASSWORD-HASH|${PW_HASH}|g" azure-sample.xml >> $LOGFILE 2>&1

echo "$INFO_TAG Updating subnet ranges and private IP addresses.." >> $LOGFILE 2>&1
# Subnets
CURRENT_SUBNETS=("10.2.2.0/24" "10.2.3.0/24" "10.2.4.0/24")
IFS=',' read -r -a NEW_ALL_SUBNETS <<< "$ALL_SUBNETS"
ARRAY_INDEX=0
for s in ${CURRENT_SUBNETS[@]}; do 
  echo "$INFO_TAG updating ${s} subnet to ${NEW_ALL_SUBNETS[$ARRAY_INDEX]}" >> $LOGFILE 2>&1
  sed -i "s|${s}|${NEW_ALL_SUBNETS[$ARRAY_INDEX]}|g" azure-sample.xml >> $LOGFILE 2>&1
  ARRAY_INDEX=$((ARRAY_INDEX + 1))
done

# Private IP Addresses
CURRENT_PRIVATE_IP_ADDRESSES=("10.2.1.4" "10.2.3.4" "10.2.4.4")
IFS=',' read -r -a NEW_PRIVATE_IP_ADDRESSES <<< "$ALL_PRIVATE_IPS"
ARRAY_INDEX=0
for p in ${CURRENT_PRIVATE_IP_ADDRESSES[@]}; do 
  echo "$INFO_TAG updating ${p} private ip address to ${NEW_PRIVATE_IP_ADDRESSES[$ARRAY_INDEX]}" >> $LOGFILE 2>&1
  sed -i "s|${p}|${NEW_PRIVATE_IP_ADDRESSES[$ARRAY_INDEX]}|g" azure-sample.xml >> $LOGFILE 2>&1
  ARRAY_INDEX=$((ARRAY_INDEX + 1))
done

# Untrusted and Trusted Hop IP Addresses
CURRENT_HOP_IP_ADDRESSES=("10.2.1.1" "10.2.2.1")
IFS=',' read -r -a NEW_HOP_IP_ADDRESSES <<< "$ALL_HOP_IPS"
ARRAY_INDEX=0
for h in ${CURRENT_HOP_IP_ADDRESSES[@]}; do 
  echo "$INFO_TAG updating ${h} hop ip address to ${NEW_HOP_IP_ADDRESSES[$ARRAY_INDEX]}" >> $LOGFILE 2>&1
  sed -i "s|${h}|${NEW_HOP_IP_ADDRESSES[$ARRAY_INDEX]}|g" azure-sample.xml >> $LOGFILE 2>&1
  ARRAY_INDEX=$((ARRAY_INDEX + 1))
done

##############################
# Checking Auto-Commit Status
##############################

echo "$INFO_TAG Checking Auto-Commit status.." >> $LOGFILE 2>&1
JOB_RESULTS="PEND"
JOB_STATUS="ACT"
JOB_PROGRESS=0  

until [ $JOB_RESULTS = "OK" ] && [ $JOB_STATUS = "FIN" ] && [ $JOB_PROGRESS = 100 ]; do
    echo "$INFO_TAG Waiting for Auto-Commit job.." >> $LOGFILE 2>&1
    JOB_RESPONSE=$(curl -s -k -u $FW_CREDS "https://$FW_PRIVATE_IP/api/?type=op&cmd=<show><jobs><id>1</id></jobs></show>")
    JOB_RESULTS=$(echo $JOB_RESPONSE | sed -e 's,.*<result>\([^<]*\)</result>.*,\1,g')
    JOB_STATUS=$(echo $JOB_RESPONSE | sed -e 's,.*<status>\([^<]*\)</status>.*,\1,g')
    JOB_PROGRESS=$(echo $JOB_RESPONSE | sed -e 's,.*<progress>\([^<]*\)</progress>.*,\1,g')
    echo "$INFO_TAG > Current Results: $JOB_RESULTS" >> $LOGFILE 2>&1
    echo "$INFO_TAG > Current Status: $JOB_STATUS" >> $LOGFILE 2>&1
    echo "$INFO_TAG > Current Progress: $JOB_PROGRESS" >> $LOGFILE 2>&1
    sleep 5
done

############################
# Checking FW Chasis Status
############################

echo "$INFO_TAG Checking FW chasis status.." >> $LOGFILE 2>&1
CHASIS_READY="no"

until [ $CHASIS_READY = "yes" ]; do
    echo "$INFO_TAG Waiting for positive FW chasis status.." >> $LOGFILE 2>&1
    CHASIS_RESPONSE=$(curl -s -k -u $FW_CREDS "https://$FW_PRIVATE_IP/api/?type=op&cmd=<show><chassis-ready></chassis-ready></show>")
    CHASIS_READY=$(echo $CHASIS_RESPONSE | sed -e 's,.*<result><!\[CDATA\[\([^<]*\)\]\]></result>.*,\1,g'| sed 's/ //g')
    echo "$INFO_TAG > Current status: $CHASIS_READY" >> $LOGFILE 2>&1
    sleep 5
done

#######################
# Importing XML Config
#######################

echo "$INFO_TAG Importing PAN config.." >> $LOGFILE 2>&1
curl -k --form file=@"./azure-sample.xml" "https://$FW_PRIVATE_IP/api/?type=import&category=configuration&key=$API_KEY" >> $LOGFILE 2>&1

#####################
# Loading XML Config
#####################

echo "$INFO_TAG Loading config.." >> $LOGFILE 2>&1
curl -k -u $FW_CREDS "https://$FW_PRIVATE_IP/api/?type=op&cmd=<load><config><from>azure-sample.xml</from></config></load>" >> $LOGFILE 2>&1

########################
# Committing XML Config
########################

echo "$INFO_TAG Committing config.." >> $LOGFILE 2>&1
COMMIT_RESPONSE=$(curl -s -k -u $FW_CREDS "https://$FW_PRIVATE_IP/api/?type=commit&cmd=<commit></commit>")
COMMIT_JOB_ID=$(echo $COMMIT_RESPONSE | sed -e 's,.*<job>\([^<]*\)</job>.*,\1,g')
echo "$INFO_TAG > Current Job ID: $COMMIT_JOB_ID" >> $LOGFILE 2>&1

echo "$INFO_TAG Checking on commit status for Job ID: $COMMIT_JOB_ID.." >> $LOGFILE 2>&1
JOB_COMMIT_RESULTS="PEND"
JOB_COMMIT_STATUS="ACT"
JOB_COMMIT_PROGRESS=0 

until [ $JOB_COMMIT_RESULTS = "OK" ] && [ $JOB_COMMIT_STATUS = "FIN" ] && [ $JOB_COMMIT_PROGRESS = 100 ]; do
    echo "$INFO_TAG Waiting for Job $COMMIT_JOB_ID commit.." >> $LOGFILE 2>&1
    JOB_COMMIT_RESPONSE=$(curl -s -k -u $FW_CREDS "https://$FW_PRIVATE_IP/api/?type=op&cmd=<show><jobs><id>$COMMIT_JOB_ID</id></jobs></show>")
    JOB_COMMIT_RESULTS=$(echo $JOB_COMMIT_RESPONSE | sed -e 's,.*<result>\([^<]*\)</result>.*,\1,g')
    JOB_COMMIT_STATUS=$(echo $JOB_COMMIT_RESPONSE | sed -e 's,.*<status>\([^<]*\)</status>.*,\1,g')
    JOB_COMMIT_PROGRESS=$(echo $JOB_COMMIT_RESPONSE | sed -e 's,.*<progress>\([^<]*\)</progress>.*,\1,g')
    echo "$INFO_TAG > Current Results: $JOB_COMMIT_RESULTS" >> $LOGFILE 2>&1
    echo "$INFO_TAG > Current Status: $JOB_COMMIT_STATUS" >> $LOGFILE 2>&1
    echo "$INFO_TAG > Current Progress: $JOB_COMMIT_PROGRESS" >> $LOGFILE 2>&1
    sleep 5
done

echo "$INFO_TAG Adios!.." >> $LOGFILE 2>&1