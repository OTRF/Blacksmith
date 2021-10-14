#!/bin/sh

# Collaboration: Open Threat Research (OTR)
# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: MIT

usage()
{
    echo "usage: $1 [OPTIONS]"
    echo "Options:"
    echo "   "
    echo "  -c config --config config      The url for a Sysmon for Linux config file (.xml)"
    echo "  -? | -h | --help               shows this usage text."
}

# Extract parameters
while [ $# -ne 0 ]
do
    case "$1" in
        -c|--config)
            sysmonConfigUrl=$2
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

# We need to use sudo for commands, if not running as root
SUDO=''
if [ "$EUID" != 0 ]; then
    SUDO='sudo'
fi

# Architecture
ARCHITECTURE=$(uname -m)

# Set package to latest GitHub release:
# Get distribution list
LSB_DIST="$(. /etc/os-release && echo "$ID")"
LSB_DIST="$(echo "$LSB_DIST" | tr '[:upper:]' '[:lower:]')"

# Get package manager and set commands
if [ "${ARCHITECTURE}" = 'x86_64' ]; then
  case "$LSB_DIST" in
    ubuntu)
      pkgMgr="apt install -y"
      if [ -z "$DIST_VERSION" ] && [ -r /etc/lsb-release ]; then
        DIST_VERSION="$(. /etc/lsb-release && echo "$DISTRIB_RELEASE")"
      fi
      if [ -z "$DIST_VERSION" ] && [ -r /etc/os-release ]; then
        DIST_VERSION="$(. /etc/os-release && echo "$VERSION_ID")"
      fi
      case "$DIST_VERSION" in
        18.04 | 20.04 | 21.04)
          wget -q https://packages.microsoft.com/config/ubuntu/$DIST_VERSION/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
          eval $SUDO dpkg -i packages-microsoft-prod.deb
          eval $SUDO apt-get update
        ;;
        *)
          ERROR=$?
          if [ $ERROR -ne 0 ]; then
            echo "[!] $LSB_DIST version $DIST_VERSION not supported!"
          fi
      esac
      ;;
    debian)
      pkgMgr="apt install -y"
      if [ -z "$DIST_VERSION" ] && [ -r /etc/os-release ]; then
        DIST_VERSION="$(. /etc/os-release && echo "$VERSION_ID")"
      fi
      case "$DIST_VERSION" in
        9)
          wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc.gpg
          eval $SUDO mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/
          wget -q https://packages.microsoft.com/config/debian/9/prod.list
          eval $SUDO mv prod.list /etc/apt/sources.list.d/microsoft-prod.list
          eval $SUDO chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg
          eval $SUDO chown root:root /etc/apt/sources.list.d/microsoft-prod.list
          eval $SUDO apt-get update
          eval $SUDO apt-get install apt-transport-https
          eval $SUDO apt-get update
        ;;
        10)
          wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc.gpg
          eval $SUDO mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/
          wget -q https://packages.microsoft.com/config/debian/10/prod.list
          eval $SUDO mv prod.list /etc/apt/sources.list.d/microsoft-prod.list
          eval $SUDO chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg
          eval $SUDO chown root:root /etc/apt/sources.list.d/microsoft-prod.list
          eval $SUDO apt-get update
          eval $SUDO apt-get install apt-transport-https
          eval $SUDO apt-get update
        ;;
        11)
          wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc.gpg
          eval $SUDO mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/
          wget -q https://packages.microsoft.com/config/debian/11/prod.list
          eval $SUDO mv prod.list /etc/apt/sources.list.d/microsoft-prod.list
          eval $SUDO chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg
          eval $SUDO chown root:root /etc/apt/sources.list.d/microsoft-prod.list
          eval $SUDO apt-get update
          eval $SUDO apt-get install apt-transport-https
          eval $SUDO apt-get update
        ;;
        *)
          ERROR=$?
          if [ $ERROR -ne 0 ]; then
            echo "[!] $LSB_DIST version $DIST_VERSION not supported!"
          fi
      esac
      ;;
    centos)
      pkgMgr="yum install -y"
      if [ -z "$DIST_VERSION" ] && [ -r /etc/os-release ]; then
        DIST_VERSION="$(. /etc/os-release && echo "$VERSION_ID")"
      fi
      case "$DIST_VERSION" in
        7*)
          eval $SUDO rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm
        ;;
        8*)
          eval $SUDO rpm -Uvh https://packages.microsoft.com/config/centos/8/packages-microsoft-prod.rpm
        ;;
        *)
          ERROR=$?
          if [ $ERROR -ne 0 ]; then
            echo "[!] $LSB_DIST version $DIST_VERSION not supported!"
          fi
      esac
      ;;
    rhel)
      pkgMgr="yum install -y"
      if [ -z "$DIST_VERSION" ] && [ -r /etc/os-release ]; then
        DIST_VERSION="$(. /etc/os-release && echo "$VERSION_ID")"
      fi
      case "$DIST_VERSION" in
        7*)
          eval $SUDO rpm --import https://packages.microsoft.com/keys/microsoft.asc
          eval $SUDO wget -q -O /etc/yum.repos.d/microsoft-prod.repo https://packages.microsoft.com/config/rhel/7/prod.repo
        ;;
        8*)
          eval $SUDO rpm --import https://packages.microsoft.com/keys/microsoft.asc
          eval $SUDO wget -q -O /etc/yum.repos.d/microsoft-prod.repo https://packages.microsoft.com/config/rhel/8/prod.repo
        ;;
        *)
          ERROR=$?
          if [ $ERROR -ne 0 ]; then
            echo "[!] $LSB_DIST version $DIST_VERSION not supported!"
          fi
      esac
      ;;
    *)
      if [ -x "$(command -v lsb_release)" ]; then
        DIST_VERSION="$(lsb_release --release | cut -f2)"
      fi
      if [ -z "$DIST_VERSION" ] && [ -r /etc/os-release ]; then
        DIST_VERSION="$(. /etc/os-release && echo "$VERSION_ID")"
      fi
      ;;
    esac
    ERROR=$?
    if [ $ERROR -ne 0 ]; then
      echoerror "Could not verify distribution or version of the OS (Error Code: $ERROR)."
    fi
    echo "You're using $LSB_DIST version $DIST_VERSION"

  # Install Sysinternals EBPF & Sysmon
  echo "Installing SysinternalsEBPF and Sysmon"
  eval $SUDO $pkgMgr sysinternalsebpf
  eval $SUDO $pkgMgr sysmonforlinux

  # Download Sysmon config and install Sysmon for Linux
  wget -O sysmon.xml $sysmonConfigUrl
  eval $SUDO sysmon -accepteula -i sysmon.xml

  ERROR=$?
  if [ $ERROR -ne 0 ]; then
    echo "[!] Could not install Sysmon for Linux (Error Code: $ERROR)."
  fi
else
  echo "[!] ${ARCHITECTURE} not supported at the moment."
fi