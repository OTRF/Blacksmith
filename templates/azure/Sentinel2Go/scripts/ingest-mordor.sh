#!/bin/bash

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

usage(){
    echo " "
    echo "Usage: $0 [option...]" >&2
    echo
    echo "   -n         EventHub Namespace"
    echo "   -c         EventHub Connection String Primary"
    echo "   -e         EventHub name"
    echo
    echo "Examples:"
    echo " $0 -n <eventhubNamespace> -c <Endpoint=sb://xxxxx>"
    echo " "
    exit 1
}

# ************ Command Options **********************
while getopts :n:c:e:h option
do
    case "${option}"
    in
        n) EVENTHUB_NAMESPACE=$OPTARG;;
        c) EVENTHUB_CONNECTIONSTRING=$OPTARG;;
        e) EVENTHUB_NAME=$OPTARG;;
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

# ****** Installing latest kafkacat
if [ -x "$(command -v kafkacat)" ]; then
    echo "removing kafkacat.."
    apt-get remove --auto-remove kafkacat
fi

echo "Installing Kafkacat.."
apt-get install kafkacat

echo "Installing Git.."
apt install git

echo "Cloning Mordor repo.."
git clone https://github.com/hunters-forge/mordor.git

echo "Decompressing every small mordor dataset.."
cd mordor/datasets/small/
find . -type f -name "*.tar.gz" -print0 | xargs -0 -I{} tar xf {} -C .

echo "Sending every dataset to Azure Event Hub"
for mordorfile in *.json; do
    echo "Sending $mordorfile to Event Hub"
    until kafkacat -b ${EVENTHUB_NAMESPACE}.servicebus.windows.net:9093 -t ${EVENTHUB_NAME} -X metadata.broker.list=${EVENTHUB_NAMESPACE}.servicebus.windows.net:9093 -X security.protocol=SASL_SSL -X sasl.mechanisms=PLAIN -X sasl.username=\$ConnectionString -X sasl.password="${EVENTHUB_CONNECTIONSTRING}" -P -l $mordorfile
    do
        echo "Trying again"
    done
done