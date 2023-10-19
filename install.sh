#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

DISABLEAUTOSTART=0
DISTRO="$(lsb_release -is)"
DISTRO_CODENAME="$(lsb_release -cs)"

echo -e "Running the GlobaLeaks installation..."

echo "Detected OS: $DISTRO - $DISTRO_CODENAME"

# align apt-get cache to up-to-date state on configured repositories
DO "apt-get -y update"
DO "apt-get install -y tzdata"
dpkg-reconfigure -f noninteractive tzdata
DO "apt-get -y install curl gnupg net-tools software-properties-common"

echo "Adding GlobaLeaks PGP key to trusted APT keys"
curl -L https://deb.globaleaks.org/globaleaks.asc | apt-key add
echo "Updating GlobaLeaks apt source.list in /etc/apt/sources.list.d/globaleaks.list ..."
echo "deb http://deb.globaleaks.org $DISTRO_CODENAME/" > /etc/apt/sources.list.d/globaleaks.list

DO "apt-get update -y"
DO "apt-get install globaleaks -y"
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