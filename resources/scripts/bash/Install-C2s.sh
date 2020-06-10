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
    echo "   -u         C2 admin user name (optional)"
    echo "   -p         C2 admin password (optional)"
    echo "   -h         help menu"
    echo
    echo "Examples:"
    echo " $0 -r caldera"
    echo " "
    exit 1
}

# ************ Command Options **********************
while getopts r:u:p:h option
do
    case "${option}"
    in
        r) RUN_C2=$OPTARG;;
        u) ADMIN_USER_NAME=$OPTARG;;
        p) ADMIN_PASSWORD=$OPTARG;;
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
    metasploit);;
    *)
        echo "$ERROR_TAG Not a valid C2 option. Valid Options: empire or covenant or caldera"
        usage
    ;;
esac

# Install Docker and Docker-Compose
./Install-Docker.sh

# Create Adversary Directory
mkdir /opt/attack-platform
chmod -R 755 /opt/attack-platform/

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
    docker run -d -it -p 7443:7443 -p 80:80 -p 443:443 -p 8443-8500:8443-8500 --name covenant -v /opt/Covenant/Covenant/Data:/app/Data covenant >> $LOGFILE 2>&1  
elif [[ $RUN_C2 == "empire" ]]; then
    # *********** Installing Empire ***************
    echo "$INFO_TAG Setting up Empire.."
    git clone https://github.com/BC-SECURITY/Empire /opt/Empire
    cd /opt/Empire && docker build -t empire . >> $LOGFILE 2>&1
    docker create -v /opt/Empire --name data empire >> $LOGFILE 2>&1

    echo "$INFO_TAG Running Empire by default.."
    cd /opt/Empire && docker run -d -it -p 80:80 -p 443:443 -p 8443-8500:8443-8500 --name empire --volumes-from data empire /bin/bash >> $LOGFILE 2>&1
elif [[ $RUN_C2 == "caldera" ]]; then
    # *********** Installing Caldera ***************
    echo "$INFO_TAG Setting up Caldera.."
    mkdir /opt/Caldera
    curl -L https://raw.githubusercontent.com/hunters-forge/Blacksmith/master/resources/scripts/docker/caldera/2.6.6-040520/docker-compose-caldera.yml -o /opt/Caldera/docker-compose-caldera.yml >> $LOGFILE 2>&1
    echo "$INFO_TAG Running Caldera by default.."

    #U Updating Caldera dmin password
    export CALDERA_RED_ADMIN_PASSWORD=$ADMIN_PASSWORD
    export CALDERA_RED_ADMIN_NAME=$ADMIN_USER_NAME

    docker-compose -f /opt/Caldera/docker-compose-caldera.yml up --build -d
elif [[ $RUN_C2 == "metasploit" ]]; then
    # *********** Installing Metasploit ***************
    docker image pull metasploitframework/metasploit-framework

    # Run manually:
    # docker run --rm -it -p 443:443 -v "/opt/attack-platform:/tmp/attack-platform" metasploitframework/metasploit-framework ./msfconsole
    # docker run --rm -it -p 8443:8443 -v "/opt/attack-platform:/tmp/attack-platform" metasploitframework/metasploit-framework ./msfconsole
fi