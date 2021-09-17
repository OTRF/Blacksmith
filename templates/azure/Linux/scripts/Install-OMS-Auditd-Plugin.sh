#!/bin/bash

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# *********** Set Log File ***************
echoerror() {
    printf "${RC} * ERROR${EC}: $@\n" 1>&2;
}

# *********** Check if user is root ***************
if [[ $EUID -ne 0 ]]; then
  echo "YOU MUST BE ROOT TO RUN THIS SCRIPT!"
  exit 1
fi

# ********* Globals **********************
SYSTEM_KERNEL="$(uname -s)"

# ********* Checking Architecture ************
if [ "$SYSTEM_KERNEL" == "Linux" ]; then
  ARCHITECTURE=$(uname -m)
  if [ "${ARCHITECTURE}" != "x86_64" ]; then
    echo "ENVIRONMENT REQUIRES AN X86_64 BASED OPERATING SYSTEM TO INSTALL"
    echo "Your Systems Architecture: ${ARCHITECTURE}"
    exit 1
  fi
  # ********** Check distribution list **********
  LSB_DIST="$(. /etc/os-release && echo "$ID")"
  LSB_DIST="$(echo "$LSB_DIST" | tr '[:upper:]' '[:lower:]')"

  # *********** Check distribution version ***************
  case "$LSB_DIST" in
  ubuntu)
    if [ -x "$(command -v lsb_release)" ]; then
      DIST_VERSION="$(lsb_release --codename | cut -f2)"
    fi
    if [ -z "$DIST_VERSION" ] && [ -r /etc/lsb-release ]; then
      DIST_VERSION="$(. /etc/lsb-release && echo "$DISTRIB_CODENAME")"
    fi
    # ********* Commenting Out CDROM **********************
    sed -i "s/\(^deb cdrom.*$\)/\#/g" /etc/apt/sources.list
    ;;
  debian | raspbian)
    DIST_VERSION="$(sed 's/\/.*//' /etc/debian_version | sed 's/\..*//')"
    case "$DIST_VERSION" in
    9) DIST_VERSION="stretch" ;;
    8) DIST_VERSION="jessie" ;;
    7) DIST_VERSION="wheezy" ;;
    esac
    # ********* Commenting Out CDROM **********************
    sed -i "s/\(^deb cdrom.*$\)/\#/g" /etc/apt/sources.list
    ;;
  centos)
    if [ -z "$DIST_VERSION" ] && [ -r /etc/os-release ]; then
      DIST_VERSION="$(. /etc/os-release && echo "$VERSION_ID")"
    fi
    ;;
  rhel)
    DIST_VERSION="$(. /etc/os-release && echo "$VERSION_ID")"
    ;;
  *)
    if [ -x "$(command -v lsb_release)" ]; then
      DIST_VERSION="$(lsb_release --release | cut -f2)"
    fi
    if [ -z "$DIST_VERSION" ] && [ -r /etc/os-release ]; then
      DIST_VERSION="$(. /etc/os-release && echo "$VERSION_ID")"
    fi
    echo "$LSB_DIST $DIST_VERSION is not supported.."
    exit 1
    ;;
  esac
  ERROR=$?
  if [ $ERROR -ne 0 ]; then
    echoerror "Could not verify distribution or version of the OS (Error Code: $ERROR)."
  fi

  echo "Running script on $LSB_DIST $DIST_VERSION .."

  # ********** Dependencies **********
  echo "Installing dependencies .."
  case "$LSB_DIST" in
  ubuntu | debian | raspbian)
    apt update -y
    apt install -y net-tools rapidjson-dev libmsgpack-dev libxml2-dev libboost-all-dev libaudit-dev libauparse-dev build-essential cmake auditd
    ;;
  centos | rhel)
    rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    yum update -y --exclude=WALinuxAgent
    yum install -y git rapidjson-devel msgpack-devel libxml2-devel gcc gcc-c++ make cmake boost-devel audit yum-utils audit-libs-devel centos-release-scl-rh
    yum-config-manager --enable rhel-server-rhscl-7-rpms
    yum install -y devtoolset-7
    echo 'source scl_source enable devtoolset-7' >> ~/.bashrc
    source scl_source enable devtoolset-7
    ;;
  esac

  # ********** Download OMS-Auditd-Plugin Repository **********
  echo "Downloading OMS Auditd Plugin Repository .."
  git clone https://github.com/microsoft/OMS-Auditd-Plugin /opt/OMS-Auditd-Plugin && cd /opt/OMS-Auditd-Plugin && git checkout MSTIC-Research

  # ********** Build **********
  echo "Building.."
  case "$LSB_DIST" in
  ubuntu | debian | raspbian)
    cmake .
    ;;
  centos | rhel)
    cmake -DCMAKE_CXX_COMPILER=//opt/rh/devtoolset-7/root/usr/bin/g++ .
    ;;
  esac

  make

  # Copy config files and rules
  cp -n auoms auomscollect auomsctl /opt/microsoft/auoms/bin
  cp -n conf/auoms.conf /etc/opt/microsoft/auoms
  cp conf/outconf.d/testout.conf /etc/opt/microsoft/auoms/outconf.d/syslog.conf
  cp rules/mstic-research.rules /etc/opt/microsoft/auoms/rules.d
  /opt/microsoft/auoms/bin/auomsctl enable

  # ********** Manager Service **********
  echo "Configuring Azure OMS and auditd services .."
  case "$LSB_DIST" in
  ubuntu | debian | raspbian)
    update-rc.d auoms defaults
    ;;
  centos | rhel)
    chkconfig auoms on
    ;;
  esac

  service auoms stop
  service auditd stop
  sed -i -e 's/active = no/active = yes/' /etc/audisp/plugins.d/auoms.conf
  
  # ********** Manager Service **********
  case "$LSB_DIST" in
  ubuntu | debian | raspbian)
    update-rc.d auditd defaults
    ;;
  centos | rhel)
    chkconfig auditd on
    ;;
  esac

  echo "Starting auditd service .."
  service auditd start
  service auoms start

  ERROR=$?
  if [ $ERROR -ne 0 ]; then
    echoerror "Could not deploy Azure OMS Auditd plugin for $LSB_DIST $DIST_VERSION (Error Code: $ERROR)."
    exit 1
  fi
else
  echoerror "SCRIPT ONLY WORKS IN LINUX VMs."
fi