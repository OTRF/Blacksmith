#!/bin/bash

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# *********** log tagging variables ***********
INFO_TAG="[INSTALLATION-INFO]"
ERROR_TAG="[INSTALLATION-ERROR]"

# *********** Set Log File ***************
LOGFILE="/var/log/C2s-install.log"
echoerror() {
    printf "${RC} * ERROR${EC}: $@\n" 1>&2;
}

# *********** Script Menu ***************
usage(){
    echo " "
    echo "Usage: $0 [option...]" >&2
    echo
    echo "   -r         run a specific C2 server (empire or covenant or caldera or shadow or poshc2)"
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
    metasploit);;
    shad0w);;
    poshc2);;
    *)
        echo "$ERROR_TAG Not a valid C2 option. Valid Options: empire or covenant or caldera"
        usage
    ;;
esac

# Install Docker and Docker-Compose
if [[ ! -f Install-Docker.sh ]]; then
    wget https://raw.githubusercontent.com/OTRF/Blacksmith/master/resources/scripts/bash/Install-Docker.sh >> $LOGFILE 2>&1
    chmod +x Install-Docker.sh >> $LOGFILE 2>&1
fi
./Install-Docker.sh >> $LOGFILE 2>&1

# Create Adversary Directory
mkdir -p /opt/attack-platform
chmod -R 755 /opt/attack-platform/

# Downloading Impacker Binaries from https://github.com/ropnop/impacket_static_binaries
echo "$INFO_TAG Downloading Impacket binaries.."
mkdir -p /opt/Impacket
cd /opt/Impacket && curl -s https://api.github.com/repos/ropnop/impacket_static_binaries/releases/latest | grep "browser_download_url.*linux_x86_64" | cut -d '"' -f 4 | wget -qi -

# *********** Running default C2 Selected ***********
echo "$INFO_TAG Deploying $RUN_C2 .."
if [[ $RUN_C2 == "covenant" ]]; then
    # *********** Installing Covenant ***************
    git clone --recurse-submodules https://github.com/cobbr/Covenant /opt/Covenant >> $LOGFILE 2>&1
    cd /opt/Covenant/Covenant && docker build -t covenant . >> $LOGFILE 2>&1

    docker run -d -it -p 7443:7443 -p 80:80 -p 443:443 -p 8443-8500:8443-8500 --name covenant -v /opt/Covenant/Covenant/Data:/app/Data covenant >> $LOGFILE 2>&1  
elif [[ $RUN_C2 == "empire" ]]; then
    # *********** Installing Empire ***************
    git clone https://github.com/BC-SECURITY/Empire /opt/Empire >> $LOGFILE 2>&1
    cd /opt/Empire && docker build -t empire . >> $LOGFILE 2>&1
    docker create -v /opt/Empire --name data empire >> $LOGFILE 2>&1

    # Run Empire in the background
    docker run -d -it -p 80:80 -p 443:443 -p 8443-8500:8443-8500 --name empire --volumes-from data empire >> $LOGFILE 2>&1
    
    # To run the client against the already running server container
    # docker container ls
    # docker exec -it {container-id} ./ps-empire client

elif [[ $RUN_C2 == "caldera" ]]; then
    # *********** Installing Caldera ***************
    git clone https://github.com/Cyb3rWard0g/docker-caldera /opt/caldera >> $LOGFILE 2>&1
    cd /opt/caldera && docker build -t caldera . >> $LOGFILE 2>&1
    
    docker run -d -it -p 8888:8888 -p 7010:7010/tcp -p 7010:7010/udp -p 7012:7012 --name caldera caldera >> $LOGFILE 2>&1
elif [[ $RUN_C2 == "metasploit" ]]; then
    # *********** Installing Metasploit ***************
    docker image pull metasploitframework/metasploit-framework >> $LOGFILE 2>&1

    # Run manually:
    # docker run --rm -it -p 443:443 -v "/opt/attack-platform:/tmp/attack-platform" metasploitframework/metasploit-framework ./msfconsole
    # docker run --rm -it -p 8443:8443 -v "/opt/attack-platform:/tmp/attack-platform" metasploitframework/metasploit-framework ./msfconsole
elif [[ $RUN_C2 == "shad0w" ]]; then
    # *********** Installing Shad0w ***************
    git clone --recurse-submodules https://github.com/bats3c/shad0w.git /opt/shad0w >> $LOGFILE 2>&1
    cd /opt/shad0w && sudo ./shad0w install >> $LOGFILE 2>&1
    
    # *********** Creating PowerShell Payload ***********
    #./shad0w beacon -p x64/windows/secure/static -H $IP_ADDDRESS -f psh -o beacon.ps1 >> $LOGFILE 2>&1

    # shad0w beacon -p x64/windows/secure/static -H 192.168.1.1 -f psh -o beacon.ps1
    # shad0w listen
elif [[ $RUN_C2 == "poshc2" ]]; then
    mkdir /opt/PoshC2
    # Pull docker image
    docker image pull cyb3rward0g/docker-poshc2:20210315
    # tag image to be compatible with official PoshC2 scripts
    docker tag cyb3rward0g/docker-poshc2:20210315 poshc2

    # Run Server Manually to create a few One-Liners!
    # sudo docker run -ti --rm -p 443:443 -v /opt/PoshC2:/opt/PoshC2 -e PAYLOAD_COMMS_HOST=https://192.168.0.4 poshc2 /usr/bin/posh-server

    # Make sure you update the scripts following ATT&CK evals Red Team Setup steps for day 2 in the /opt/PoshC2/resources/modules/ folder. 
    # https://github.com/mitre-attack/attack-arsenal/tree/master/adversary_emulation/APT29/Emulation_Plan/Day%202#red-team-setup

    # Run Client Manually
    # sudo docker run -ti --rm -v /opt/PoshC2:/opt/PoshC2 poshc2 /usr/bin/posh
fi