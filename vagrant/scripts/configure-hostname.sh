#!/bin/bash

usage() {
	echo "Usage: $(basename $0) <hostname>"
	exit 1
}

# validate commandline
if [ $# -ne 1 ]; then usage; fi

# set hostname
sudo hostnamectl set-hostname ${1}
