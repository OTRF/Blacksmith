#!/bin/bash

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# *********** log tagging variables ***********
INFO_TAG="[INSTALLATION-INFO]"
ERROR_TAG="[INSTALLATION-ERROR]"
DATE_TIME=`date "+%Y-%m-%d %H:%M:%S"`

# *********** Set Log File ***************
LOGFILE="/var/log/C2s-install.log"
echoerror() {
    printf "${RC} * ERROR${EC}: $@\n" 1>&2;
}

# *********** helk function ***************
usage(){
    echo " "
    echo "Usage: $0 [option...]" >&2
    echo
    echo "   -r         run a specific C2 server (empire or covenant or caldera)"
    echo "   -h         help menu"
    echo
    echo "Examples:"
    echo " $0 -r caldera"
    echo " "
    exit 1
}

# ************ Command Options **********************
while getopts r:h option
do
    case "${option}"
    in
        r) RUN_C2=$OPTARG;;
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

# *********** Validating Input ***************
case $RUN_C2 in
    empire);;
    covenant);;
    caldera);;
    *)
        echo "$ERROR_TAG Not a valid C2 option. Valid Options: empire or covenant or caldera"
        usage
    ;;
esac

# Downloading Impacker Binaries from https://github.com/ropnop/impacket_static_binaries
echo "$INFO_TAG Downloading Impacket binaries.."
mkdir /opt/Impacket
cd /opt/Impacket && curl -s https://api.github.com/repos/ropnop/impacket_static_binaries/releases/latest | grep "browser_download_url.*linux_x86_64" | cut -d '"' -f 4 | wget -qi -

# *********** Running default C2 Selected ***********
if [[ $RUN_C2 == "covenant" ]]; then
    # *********** Installing Covenant ***************
    echo "$INFO_TAG Setting up Covenant.."
    git clone --recurse-submodules https://github.com/cobbr/Covenant /opt/Covenant >> $LOGFILE 2>&1
    cd /opt/Covenant/Covenant && docker build -t covenant . >> $LOGFILE 2>&1

    echo "$INFO_TAG Running Covenant by default.."
    docker run -d -it -p 7443:7443 -p 80:80 -p 443:443 --name covenant -v /opt/Covenant/Covenant/Data:/app/Data covenant >> $LOGFILE 2>&1  
elif [[ $RUN_C2 == "empire" ]]; then
    # *********** Installing Empire ***************
    echo "$INFO_TAG Setting up Empire.."
    git clone https://github.com/BC-SECURITY/Empire /opt/Empire
    cd /opt/Empire && docker build -t empire . >> $LOGFILE 2>&1
    docker create -v /opt/Empire --name data empire >> $LOGFILE 2>&1

    echo "$INFO_TAG Running Empire by default.."
    cd /opt/Empire && docker run -d -it -p 80:80 -p 443:443 -p 999:999 --name empire --volumes-from data empire /bin/bash >> $LOGFILE 2>&1
else
    # *********** Installing Caldera ***************
    if ! [ -x "$(command -v docker-compose)" ]; then
        echo "$INFO_TAG Installing docker-compose.."
        COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
        curl -L https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose >> $LOGFILE 2>&1
        chmod +x /usr/local/bin/docker-compose >> $LOGFILE 2>&1
    fi
    
    echo "$INFO_TAG Setting up Caldera.."
    mkdir /opt/Caldera
    mkdir /opt/Caldera/config
    curl -L https://raw.githubusercontent.com/hunters-forge/Blacksmith/master/aws/mordor/cfn-files/docker/caldera/docker-compose-caldera.yml -o /opt/Caldera/docker-compose-caldera.yml >> $LOGFILE 2>&1
    curl -L https://raw.githubusercontent.com/hunters-forge/Blacksmith/master/aws/mordor/cfn-files/docker/caldera/config/a93f6915-a9b8-4a6b-ad46-c072963b32c1.yml -o /opt/Caldera/config/a93f6915-a9b8-4a6b-ad46-c072963b32c1.yml >> $LOGFILE 2>&1
    echo "$INFO_TAG Running Caldera by default.."
    docker-compose -f /opt/Caldera/docker-compose-caldera.yml up --build -d
fi