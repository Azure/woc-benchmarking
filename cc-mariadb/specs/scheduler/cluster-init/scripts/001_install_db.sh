#!/bin/bash

#MNT_FILES=${CYCLECLOUD_SPEC_PATH}/files
MNT_FILES=/mnt/cluster-init/cc-mariadb/scheduler/files

if [ -z $(which)]; then
#we cant assume that 'which' is installed



 if [ -n $(which apt) ]; then
    echo "apt"
    sudo apt install -y mariadb-server
    sudo mysql_secure_installation < $MNT_FILES/mysql_install_inputs.txt
  elif [ -n $(which yum) ]; then
    echo "yum"
    sudo yum install -y mariadb-server
    sudo mysql_secure_installation < $MNT_FILES/mysql_install_inputs.txt
  else
    echo "Package manager is neither yum or apt. Exiting ..."
  fi
else
# just force-try both; one will work ... hopefully
    sudo apt install -y mariadb-server
    sudo yum install -y mariadb-server
    sudo mysql_secure_installation < $MNT_FILES/mysql_install_inputs.txt
fi

systemctl enable mariadb.service
systemctl start mariadb.service
