#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# User Permission Check
if [ ! $(id -u) = 0 ]; then
  echo "Error: GlobaLeaks install script must be run by root"
  exit 1
fi

# Status updating function
function DO () {
  CMD="$1"

  if [ -z "$2" ]; then
    EXPECTED_RET=0
  else
    EXPECTED_RET=$2
  fi

  echo -n "Running: \"$CMD\"... "
  eval $CMD &>${LOGFILE}

  STATUS=$?

  last_command $CMD
  last_status $STATUS

  if [ "$STATUS" -eq "$EXPECTED_RET" ]; then
    echo "SUCCESS"
  else
    echo "FAIL"
    echo "Ouch! The installation failed."
    echo "COMBINED STDOUT/STDERR OUTPUT OF FAILED COMMAND:"
    cat ${LOGFILE}
    exit 1
  fi
}

LOGFILE="./install.log"
ASSUMEYES=0
DISABLEAUTOSTART=0

DISTRO="Debian"
DISTRO_CODENAME="bookworm"

# Report last executed command and its status
TMPDIR=$(mktemp -d)
echo '' > $TMPDIR/last_command
echo '' > $TMPDIR/last_status

function last_command () {
  echo $1 > $TMPDIR/last_command
}

function last_status () {
  echo $1 > $TMPDIR/last_status
}

function prompt_for_continuation () {
  if [ $ASSUMEYES -eq 0 ]; then
    while true; do
      read -p "Do you wish to continue anyway? [y|n]?" yn
      case $yn in
        [Yy]*) break;;
        [Nn]*) exit 1;;
        *) echo $yn; echo "Please answer y/n.";  continue;;
      esac
    done
  fi
}

usage() {
  echo "GlobaLeaks Install Script"
  echo "Valid options:"
  echo -e " -h show the script helper"
  echo -e " -y assume yes"
  echo -e " -n disable autostart"
  echo -e " -v install a specific software version"
}

while getopts "ynvh:" opt; do
  case $opt in
    y) ASSUMEYES=1
    ;;
    n) DISABLEAUTOSTART=1
    ;;
    v) VERSION="$OPTARG"
    ;;
    h)
        usage
        exit 1
    ;;
    \?) usage
        exit 1
    ;;
  esac
done

echo -e "Running the GlobaLeaks installation...\nIn case of failure please report encountered issues to the ticketing system at: https://github.com/globaleaks/GlobaLeaks/issues\n"

last_command "check_distro"

# align apt-get cache to up-to-date state on configured repositories
DO "apt-get -y update"

if [ ! -f /etc/timezone ]; then
  echo "Etc/UTC" > /etc/timezone
fi

apt-get install -y tzdata
dpkg-reconfigure -f noninteractive tzdata

DO "apt-get -y install curl gnupg net-tools software-properties-common"

function is_tcp_sock_free_check {
  ! netstat -tlpn 2>/dev/null | grep -F $1 -q
}

# check the required sockets to see if they are already used
for SOCK in "0.0.0.0:80" "0.0.0.0:443" "127.0.0.1:8082" "127.0.0.1:8083"
do
  DO "is_tcp_sock_free_check $SOCK"
done

echo " + required TCP sockets open"

echo "Adding GlobaLeaks PGP key to trusted APT keys"
curl -L https://deb.globaleaks.org/globaleaks.asc | apt-key add

echo "Updating GlobaLeaks apt source.list in /etc/apt/sources.list.d/globaleaks.list ..."
echo "deb http://deb.globaleaks.org $DISTRO_CODENAME/" > /etc/apt/sources.list.d/globaleaks.list

DO "apt-get update -y"
DO "apt-get install globaleaks -y"

# Set the script to its success condition
last_command "startup"
last_status "0"

sleep 5

i=0
while [ $i -lt 30 ]
do
  X=$(netstat -tln | grep ":8443")
  if [ $? -eq 0 ]; then
    #SUCCESS
    echo "GlobaLeaks setup completed."
    TOR=$(gl-admin getvar onionservice)
    echo "To proceed with the configuration you could now access the platform wizard at:"
    echo "+ http://$TOR (via the Tor Browser)"
    echo "+ https://127.0.0.1:8443"
    echo "+ https://0.0.0.0"
    echo "We recommend you to to perform the wizard by using Tor address or on localhost via a VPN."
    exit 0
  fi
  i=$[$i+1]
  sleep 1
done

#ERROR
echo "Ouch! The installation is complete but GlobaLeaks failed to start."
netstat -tln
cat /var/globaleaks/log/globaleaks.log
last_status "1"
exit 1