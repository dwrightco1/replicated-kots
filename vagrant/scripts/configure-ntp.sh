#!/bin/bash

usage() {
	echo "Usage: $(basename $0) [<timezone>]"
	exit 1
}

if [ $# -eq 1 ]; then
	timezone=${1}
else
	timezone="UTC"
fi

# install OS updates
sudo apt-get update

# set timezone
sudo timedatectl set-timezone ${timezone}

# ntp
sudo timedatectl set-ntp on
sudo apt install -y ntp
