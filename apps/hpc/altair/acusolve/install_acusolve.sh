#!/bin/bash

# parameters that can be overridden
APP_INSTALL_DIR=${APP_INSTALL_DIR:-/share/apps}
TMP_DIR=${TMP_DIR:-/mnt/resource}
ALTAIR_INSTALLER_FILE=${ALTAIR_INSTALLER_FILE:-/share/home/hpcuser/altair/src/hwCFDSolvers2021.2_linux64.bin}
ALTAIR_HOTFIX_FILE=${ALTAIR_HOTFIX_FILE:-/share/home/hpcuser/altair/src/hwCFDSolvers2021.2.1_hotfix-1_linux64.bin}

if [ ! -e $ALTAIR_INSTALLER_FILE ]; then
    echo "Error:  $ALTAIR_INSTALLER_FILE does not exist"
    echo "You can set the path to the file with the ALTAIR_INSTALLER_FILE"
    exit 1
fi

if [ ! -e $ALTAIR_HOTFIX_FILE ]; then
    echo "Error:  $ALTAIR_HOTFIX_FILE does not exist"
    echo "You can set the path to the file with the ALTAIR_HOTFIX_FILE"
    exit 1
fi

install_dir=$APP_INSTALL_DIR/altair_2021

$ALTAIR_INSTALLER_FILE -i silent -DUSER_INSTALL_DIR=$install_dir -DTMP_DIR=/mnt/resource/scratch -DACCEPT_EULA=YES
$ALTAIR_HOTFIX_FILE -i silent -DUSER_INSTALL_DIR=$install_dir -DTMP_DIR=/mnt/resource/scratch -DACCEPT_EULA=YES
