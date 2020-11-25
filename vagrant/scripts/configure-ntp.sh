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

sudo timedatectl set-timezone ${timezone}
sudo timedatectl set-ntp on
