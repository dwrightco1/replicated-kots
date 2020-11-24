#!/bin/bash

# globals
url=https://releases.hashicorp.com/terraform
installer=0.13.4/terraform_0.13.4_linux_amd64.zip
tmpfile=/tmp/terraform_0.13.4_linux_amd64.zip
install_dir=/usr/local/bin

# install OS updates
sudo apt-get update

# install required packages
sudo apt-get install zip unzip

# download terraform
curl -o ${tmpfile} -O ${url}/${installer} 2>/dev/null

# extract archive
unzip ${tmpfile} -d /tmp

# copy terraform
sudo cp /tmp/terraform ${install_dir}
sudo chmod 755 ${install_dir}/terraform

# install aws cli
curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip 2>/dev/null
unzip awscliv2.zip
sudo ./aws/install

# Update bash profile
echo "export PS1=\"terraform \$\"" > ~/.bash_profile

exit 0
