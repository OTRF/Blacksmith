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

# OMI
GITHUB_OMI_RELEASE_X64="https://github.com/microsoft/omi/releases/download/v1.6.8-0/"
OMI_DEB_PACKAGE="omi-1.6.8-0.ssl_110.ulinux.x64.deb"
OMI_RPM_PACKAGE="omi-1.6.8-0.ssl_110.ulinux.x64.rpm"

# SCX
GITHUB_SCX_RELEASE_X64="https://github.com/microsoft/SCXcore/releases/download/1.6.6-0/"
SCX_DEB_PACKAGE="scx-1.6.6-0.ssl_110.universal.x64.deb"
SCX_RPM_PACKAGE="scx-1.6.6-0.ssl_110.universal.x64.rpm"

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
#bundleParameters="--upgrade"
bundleParameters="--install"
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
  echo "[!] $LSB_DIST $DIST_VERSION is not supported.." >> $LOGFILE 2>&1
  exit 1
  ;;
esac
ERROR=$?
if [ $ERROR -ne 0 ]; then
  echoerror "Could not verify distribution or version of the OS (Error Code: $ERROR)."
fi

# ********** OMI **********
echo "Installing OMI package.."
case "$LSB_DIST" in
ubuntu | debian | raspbian)
  wget -O ${OMI_DEB_PACKAGE} ${GITHUB_OMI_RELEASE_X64}${OMI_DEB_PACKAGE} && $SUDO dpkg -i ./${OMI_DEB_PACKAGE} && rm ${OMI_DEB_PACKAGE}
  ;;
centos | rhel)
  wget -O ${OMI_RPM_PACKAGE} ${GITHUB_OMI_RELEASE_X64}${OMI_RPM_PACKAGE} && $SUDO rpm -Uvh ./${OMI_RPM_PACKAGE} && rm ${OMI_RPM_PACKAGE}
  ;;
esac

# ********** Update OMI Server Configuration **********
sed -i "s|^httpsport=0$|httpsport=0,5986|g" /etc/opt/omi/conf/omiserver.conf
sed -i "s|^httpport=0$|httpport=0,5985|g" /etc/opt/omi/conf/omiserver.conf

# Install SCX
# ********** SCX **********
echo "Installing SCX package.."
case "$LSB_DIST" in
ubuntu | debian | raspbian)
  wget -O ${SCX_DEB_PACKAGE} ${GITHUB_SCX_RELEASE_X64}${SCX_DEB_PACKAGE} && $SUDO dpkg -i ./${SCX_DEB_PACKAGE} && rm ${SCX_DEB_PACKAGE}
  ;;
centos | rhel)
  wget -O ${SCX_RPM_PACKAGE} ${GITHUB_SCX_RELEASE_X64}${SCX_RPM_PACKAGE} && $SUDO rpm -Uvh ./${SCX_RPM_PACKAGE} && rm ${SCX_RPM_PACKAGE}
  ;;
esac

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

# Set SCX Audit Level
# /opt/microsoft/scx/bin/tools/scxadmin -log-set all verbose

ERROR=$?
if [ $ERROR -ne 0 ]; then
  echo "[!] Could not deploy Azure OMS and OMI for $LSB_DIST $DIST_VERSION (Error Code: $ERROR)."
fi
