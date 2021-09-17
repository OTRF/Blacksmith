#!/bin/sh

# Easy download/install/onboard script for the OMSAgent for Linux
#
# Reference: https://raw.githubusercontent.com/microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh

# Architecture
ARCHITECTURE=$(uname -m)

# Values to be updated upon each new release
GITHUB_RELEASE_X64="https://github.com/microsoft/OMS-Agent-for-Linux/releases/download/OMSAgent_v1.13.40-0/"
GITHUB_RELEASE_X86="https://github.com/Microsoft/OMS-Agent-for-Linux/releases/download/OMSAgent_v1.12.15-0/"

BUNDLE_X64="omsagent-1.13.40-0.universal.x64.sh"
BUNDLE_X86="omsagent-1.12.15-0.universal.x86.sh"

usage()
{
    echo "usage: $1 [OPTIONS]"
    echo "Options:"
    echo "   "
    echo "  -w id, --id id             Use workspace ID <id> for automatic onboarding."
    echo "  -s key, --shared key       Use <key> as the shared key for automatic onboarding."
    echo "  -d dmn, --domain dmn       Use <dmn> as the OMS domain for onboarding. Optional."
    echo "                             default: opinsights.azure.com"
    echo "                             ex: opinsights.azure.us (for FairFax)"
    echo "  -p conf, --proxy conf      Use <conf> as the proxy configuration."
    echo "                             ex: -p [protocol://][user:password@]proxyhost[:port]"
    echo "  --purge                    Uninstall the package and remove all related data."
    echo "  -? | -h | --help           shows this usage text."
}


# Extract parameters
while [ $# -ne 0 ]
do
    case "$1" in
        -d|--domain)
            topLevelDomain=$2
            shift 2
            ;;

        -s|--shared)
            onboardKey=$2
            shift 2
            ;;

        -w|--id)
            onboardID=$2
            shift 2
            ;;

        --purge)
            purgeAgent="true"
            break;
            ;;

        -p|--proxy)
            proxyConf=$2
            shift 2
            ;;

        -\? | -h | --help)
            usage `basename $0` >&2
            exit 0
            ;;

         *)
            echo "Unknown argument: '$1'" >&2
            echo "Use -h or --help for usage" >&2
            exit 1
            ;;
    esac
done

# Assemble parameters
bundleParameters="--upgrade"
if [ -n "$onboardID" ]; then
    bundleParameters="${bundleParameters} -w $onboardID"
fi
if [ -n "$onboardKey" ]; then
    bundleParameters="${bundleParameters} -s $onboardKey"
fi
if [ -n "$topLevelDomain" ]; then
    bundleParameters="${bundleParameters} -d $topLevelDomain"
fi
if [ -n "$purgeAgent" ]; then
    bundleParameters="--purge"
fi
if [ -n "$proxyConf" ]; then
    bundleParameters="${bundleParameters} -p $proxyConf"
fi
bundleParameters="${bundleParameters} --debug"

# We need to use sudo for commands in the following block, if not running as root
SUDO=''
if [ "$EUID" != 0 ]; then
    SUDO='sudo'
fi

# Download, install, and onboard OMSAgent for Linux, depending on architecture of machine
if [ "${ARCHITECTURE}" = 'x86_64' ]; then
    # x64 architecture
    wget -O ${BUNDLE_X64} ${GITHUB_RELEASE_X64}${BUNDLE_X64} && $SUDO sh ./${BUNDLE_X64} ${bundleParameters}
else
    # x86 architecture
    echo "Note that there will be no further releases of the 32-bit OMS Linux agent."
    echo "The final version with 32-bit support is 1.12.15-0, which will now be installed."
    wget -O ${BUNDLE_X86} ${GITHUB_RELEASE_X86}${BUNDLE_X86} && $SUDO sh ./${BUNDLE_X86} ${bundleParameters}
fi

# Sleep
sleep 5s

# Force vulnerable version
# reference: https://github.com/microsoft/OMS-Agent-for-Linux/blob/master/tools/OMIcheck/omi_upgrade.sh

omi_version="1.6.8-0"

osslverstr=$(openssl version)
echo $osslverstr
echo $osslverstr | grep 1.1. > /dev/null
isSSL11=$?
echo isSSL11=$isSSL11
echo $osslverstr | grep 1.0. > /dev/null
isSSL10=$?
echo isSSL10=$isSSL10

if [ $isSSL11 = 0 ]; then
    osslver="110"
elif [ $isSSL10 = 0 ]; then
    osslver="100"
else
    echo "Unexpected Open SSL version"
    exit -1
fi

which dpkg > /dev/null
if [ $? = 0 ]; then
    pkgMgr="dpkg -i"
    pkgName="omi-${omi_version}.ssl_${osslver}.ulinux.x64.deb"
else
    which rpm > /dev/null
    if [ $? = 0 ]; then
        # sometimes rpm db is not in a good shape.
        pkgMgr="rpm --rebuilddb && rpm -Uhv"
        #pkgMgr="rpm -Uhv"
        pkgName="omi-${omi_version}.ssl_${osslver}.ulinux.x64.rpm"
    else
        echo Unknown package manager
        exit -2
    fi
fi

pkg="https://github.com/microsoft/omi/releases/download/v${omi_version}/$pkgName"
echo $pkg
wget -q $pkg -O /tmp/$pkgName
ls -l /tmp/$pkgName
echo sudo eval $pkgMgr /tmp/$pkgName
eval sudo $pkgMgr /tmp/$pkgName
/opt/omi/bin/omiserver -v

# ********** Update OMI Server Configuration **********
sed -i "s|^httpsport=0$|httpsport=0,5986|g" /etc/opt/omi/conf/omiserver.conf
sed -i "s|^httpport=0$|httpport=0,5985|g" /etc/opt/omi/conf/omiserver.conf

# ********** Restart OMI service **********
service omid restart

# ********** Restart auoms service **********
service auoms restart

ERROR=$?
if [ $ERROR -ne 0 ]; then
  echo "[!] Could not deploy Azure OMS and OMI (Error Code: $ERROR)."
fi
