#!/bin/bash

cd /tmp

# Install azcopy
wget https://aka.ms/downloadazcopy-v10-linux
tar xzvf downloadazcopy-v10-linux
sudo mv azcopy_linux_amd64_*/azcopy /usr/bin/azcopy
sudo chmod 755 /usr/bin/azcopy
sudo chown root:root /usr/bin/azcopy

# Install pdsh
apt install -y pdsh

# Install lbzip2 (Useful for parallel compression/decompression)
apt install -y lbzip2

# Install gdown useful for getting data from google drive
sudo apt-get -y install python3-pip
sudo pip3 install gdown

# install clustershell
sudo apt install clustershell
