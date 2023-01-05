#!/bin/bash

cd /tmp

# Install azcopy
wget https://aka.ms/downloadazcopy-v10-linux
tar xzvf downloadazcopy-v10-linux
sudo mv azcopy_linux_amd64_*/azcopy /usr/bin/azcopy
sudo chmod 755 /usr/bin/azcopy
sudo chown root:root /usr/bin/azcopy

version=`/bin/bash ${CYCLECLOUD_SPEC_PATH}/files/common.sh`

if [ "$version" == "almalinux-8" ]
then
    yum install -y clustershell
    yum install -y git jq
elif [ "$version" == "centos-7" ]
then
    yum install -y clustershell
    yum install -y git jq
elif [ "$version" == "ubuntu-18.04" ]
then
    apt install -y clustershell
    apt install -y git jq
elif [ "$version" == "ubuntu-20.04" ]
then
    apt install -y clustershell
    apt install -y git jq
fi

