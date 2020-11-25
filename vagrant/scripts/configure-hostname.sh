#!/bin/bash

usage() {
	echo "Usage: $(basename $0) <hostname>"
	exit 1
}

# validate commandline
if [ $# -ne 1 ]; then usage; fi
hostname=${1}

# set hostname
sudo hostnamectl set-hostname ${hostname}

# Update bash profile
echo "export PS1=\"${hostname} \$\"" > ~/.bash_profile
