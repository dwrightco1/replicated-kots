#!/bin/bash

usage() {
	echo "Usage: $(basename $0) <hostname> [<ip-address>]"
	exit 1
}

# validate commandline
if [ $# -eq 1 ]; then
	hostname=${1}
	ip=""
elif [ $# -eq 2 ]; then
	hostname=${1}
	ip="${2}"
else
	usage
fi

# set hostname
echo "setting hostname to: ${hostname}"
sudo hostnamectl set-hostname ${hostname}

# update /etc/hosts
if [ -n "${ip}" ]; then
	grep "^${ip}" /etc/hosts > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "adding entry to /etc/hosts:"
		sudo echo "${ip} ${hostname}" >> /etc/hosts
	fi
fi

# Update bash profile
echo "export PS1=\"${hostname} \$\"" > ~/.bash_profile
