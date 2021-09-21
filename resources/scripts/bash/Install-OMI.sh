#!/bin/sh

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPLv3
# reference: https://github.com/microsoft/OMS-Agent-for-Linux/blob/master/tools/OMIcheck/omi_upgrade.sh

usage()
{
    echo "usage: $1 [OPTIONS]"
    echo "Options:"
    echo "   "
    echo "  -t tag --tag tag           Install from specific GitHub release tag (v1.6.8-1) Latest version is installed by default"
    echo "  --httpport port            The HTTP port to listen on. It is recommended that HTTP remain disabled (httpport=0) to prevent unencrypted communication"
    echo "  --httpsport port           The HTTPs port(s) to listen on. The default is 5986. Multiple ports can be defined as a comma-separated list"
    echo "  -? | -h | --help           shows this usage text."
}

# Extract parameters
while [ $# -ne 0 ]
do
    case "$1" in
        -t|--tag)
            tagRelease=$2
            shift 2
            ;;
        
        --httpport)
            httpport=$2
            shift 2
            ;;

        --httpsport)
            httpsport=$2
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

# SSL Version
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

# Set package to latest GitHub release:
# Get distribution list
LSB_DIST="$(. /etc/os-release && echo "$ID")"
LSB_DIST="$(echo "$LSB_DIST" | tr '[:upper:]' '[:lower:]')"

# Get package manager and set commands
case "$LSB_DIST" in
ubuntu | debian)
  pkgMgr="dpkg -i"
  if [ -n "$tagRelease" ]; then
    ASSETS_URL=$(curl --silent "https://api.github.com/repos/microsoft/omi/releases/tags/$tagRelease" | grep -oP '"assets_url": "\K(.*)(?=")')
    pkgUrl=$(curl --silent "$ASSETS_URL" | grep -oP '"browser_download_url": "\K(.*.deb)(?=")' | grep $osslver)
  else
    pkgUrl=$(curl --silent "https://api.github.com/repos/microsoft/omi/releases/latest" | grep -oP '"browser_download_url": "\K(.*.deb)(?=")' | grep $osslver)
  fi
  ;;
centos | rhel)
  pkgMgr="rpm --rebuilddb && rpm -Uhv"
  if [ -n "$tagRelease" ]; then
    ASSETS_URL=$(curl --silent "https://api.github.com/repos/microsoft/omi/releases/tags/$tagRelease" | grep -oP '"assets_url": "\K(.*)(?=")')
    pkgUrl=$(curl --silent "$ASSETS_URL" | grep -oP '"browser_download_url": "\K(.*.rpm)(?=")' | grep $osslver)
  else
    pkgUrl=$(curl --silent "https://api.github.com/repos/microsoft/omi/releases/latest" | grep -oP '"browser_download_url": "\K(.*.rpm)(?=")' | grep $osslver)
  fi
  ;;
esac
pkgName=$(basename $pkgUrl)

# We need to use sudo for commands in the following block, if not running as root
SUDO=''
if [ "$EUID" != 0 ]; then
    SUDO='sudo'
fi

# Download package
wget -O ${pkgName} ${pkgUrl}

# Install OMI package
eval $SUDO $pkgMgr $pkgName
/opt/omi/bin/omiserver -v

# ********** Update OMI Server Configuration **********
if [ -n "$httpport" ]; then
    sed -i "s|^httpport=0$|httpport=0,${httpport}|g" /etc/opt/omi/conf/omiserver.conf
fi
if [ -n "$httpsport" ]; then
    sed -i "s|^httpsport=0$|httpsport=0,${httpsport}|g" /etc/opt/omi/conf/omiserver.conf
fi

# Restaring OMID and AUOMS
systemctl restart omid
systemctl restart auoms

ERROR=$?
if [ $ERROR -ne 0 ]; then
  echo "[!] Could not deploy Azure OMS and OMI (Error Code: $ERROR)."
fi
