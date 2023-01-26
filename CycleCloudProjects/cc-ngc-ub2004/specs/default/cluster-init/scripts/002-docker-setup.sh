#!/bin/bash

set -ex

#### 
# Requirements: Ubuntu 18.04
####

# Install Docker and NVIDIA Docker                                                       
#### Install Docker                                                       
echo "\n---------------- Install Docker ----------------"
cd /mnt/resource
apt update
curl https://get.docker.com | sh && sudo systemctl --now enable docker

#### Install NV-DOCKER                                                       
echo "\n---------------- Install NV-Docker ----------------"
cd /mnt/resource
# If you have nvidia-docker 1.0 installed: we need to remove it and all existing GPU containers
docker volume ls -q -f driver=nvidia-docker | xargs -r -I{} -n1 docker ps -q -a -f volume={} | xargs -r docker rm -f

set +e
apt-get purge -y nvidia-docker
set -e

# Add the package repositories
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | \
  apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  tee /etc/apt/sources.list.d/nvidia-docker.list
apt-get update
apt-get install -y nvidia-docker2=2.6.0-1
pkill -SIGHUP dockerd

# Update the docker config file
systemctl stop docker
sh -c "echo '{  \"data-root\": \"/mnt/resource/docker\", \"bip\": \"152.26.0.1/16\", \"runtimes\": { \"nvidia\": { \"path\": \"/usr/bin/nvidia-container-runtime\", \"runtimeArgs\": [] } } }' > /etc/docker/daemon.json"
systemctl restart docker

set +e
# docker run --runtime=nvidia --rm nvidia/cuda:11.0-base nvidia-smi
docker run --runtime=nvidia --rm nvcr.io/nvidia/cuda:11.0.3-base-ubuntu18.04 nvidia-smi
set -e

### Install NVtop
echo "\n---------------- Install NVtop ----------------"
apt install -y cmake libncurses5-dev libncursesw5-dev git
cd /tmp
cp ${CYCLECLOUD_SPEC_PATH}/files/nvtop-2.0.3.tar.gz .
tar xzf nvtop-2.0.3.tar.gz
cd nvtop-2.0.3
cmake .
make
make install
