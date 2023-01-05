#!/bin/bash

# parameters that can be overridden
APP_INSTALL_DIR=${APP_INSTALL_DIR:-/shared/apps}
TMP_DIR=${TMP_DIR:-/shared/tmp}
STARCCM_INSTALLER_FILE=${STARCCM_INSTALLER_FILE:-STAR-CCM+17.02.008_01_linux-x86_64.tar.gz}

if [ ! -e $STARCCM_INSTALLER_FILE ]; then
    echo "Error:  $STARCCM_INSTALLER_FILE does not exist"
    echo "You can set the path to the file with the STARCCM_INSTALLER_FILE"
    exit 1
fi

sudo yum install -y unzip

install_dir=$APP_INSTALL_DIR/starccm
tmp_dir=$TMP_DIR/tmp-starccm

mkdir -p $tmp_dir

if [ -f "$STARCCM_INSTALLER_FILE" ]
then
    mv $STARCCM_INSTALLER_FILE $tmp_dir/$STARCCM_INSTALLER_FILE
fi

pushd $tmp_dir
if [ ! -f "$STARCCM_INSTALLER_FILE" ]
then
    echo "Not able to find $STARCCM_INSTALLER_FILE in $PWD"
    exit
else
    tar xzvf $STARCCM_INSTALLER_FILE
    cd starccm+_*
    sudo ./STAR-CCM+*.sh -i silent -DINSTALLDIR=$install_dir
    popd
    rm -rf $tmp_dir
fi
