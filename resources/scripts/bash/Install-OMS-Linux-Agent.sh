#!/bin/sh

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPLv3s
# Reference: https://raw.githubusercontent.com/microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh

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
    echo "  -t tag --tag tag           Download bundle script from specific GitHub release tag (i.e OMSAgent_v1.13.40-0)."
    echo "                             Latest version is installed by default"
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
        
        -t|--tag)
            tagRelease=$2
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

# Set bundle script to latest GitHub release:
GITHUB_RELEASE_X64=$(curl --silent "https://api.github.com/repos/microsoft/OMS-Agent-for-Linux/releases/latest" | grep -oP '"browser_download_url": "\K(.*)(?=")')
# Output example: https://github.com/microsoft/OMS-Agent-for-Linux/releases/download/OMSAgent_v1.13.40-0/omsagent-1.13.40-0.universal.x64.sh
BUNDLE_X64=$(basename $GITHUB_RELEASE_X64)
# Output example: omsagent-1.13.40-0.universal.x64.sh

GITHUB_RELEASE_X86="https://github.com/Microsoft/OMS-Agent-for-Linux/releases/download/OMSAgent_v1.12.15-0/"
BUNDLE_X86="omsagent-1.12.15-0.universal.x86.sh"

# Architecture
ARCHITECTURE=$(uname -m)

# Download, install, and onboard OMSAgent for Linux, depending on architecture of machine
if [ "${ARCHITECTURE}" = 'x86_64' ]; then
    # x64 architecture
    if [ -n "$tagRelease" ]; then
        ASSETS_URL=$(curl --silent "https://api.github.com/repos/microsoft/OMS-Agent-for-Linux/releases/tags/$tagRelease" | grep -oP '"assets_url": "\K(.*)(?=")')
        GITHUB_RELEASE_X64=$(curl --silent "$ASSETS_URL" | grep -oP '"browser_download_url": "\K(.*)(?=")')
        BUNDLE_X64=$(basename $GITHUB_RELEASE_X64)
    fi
    wget -O ${BUNDLE_X64} ${GITHUB_RELEASE_X64} && $SUDO sh ./${BUNDLE_X64} ${bundleParameters}
else
    # x86 architecture
    echo "Note that there will be no further releases of the 32-bit OMS Linux agent."
    echo "The final version with 32-bit support is 1.12.15-0, which will now be installed."
    wget -O ${BUNDLE_X86} ${GITHUB_RELEASE_X86}${BUNDLE_X86} && $SUDO sh ./${BUNDLE_X86} ${bundleParameters}
fi

ERROR=$?
if [ $ERROR -ne 0 ]; then
  echo "[!] Could not install OMS agent (Error Code: $ERROR)."
fi
