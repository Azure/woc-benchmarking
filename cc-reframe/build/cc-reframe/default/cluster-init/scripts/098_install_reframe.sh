#!/bin/bash
set -ex

# Install reframe
cd /usr/local
yum install -y git python38 python38-pip

rm -rf reframe
git clone https://github.com/JonShelley/reframe.git
cd reframe

export python=python3.8
./bootstrap.sh
