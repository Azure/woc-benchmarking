#!/bin/bash

# Determine the OS version
. /usr/lib/os-release

if [ "$ID" == "almalinux" ]
then
    majVer=(${VERSION_ID//./ })
    echo "$ID-${majVer[0]}"
elif [ "$ID" == "ubuntu" ]
then
    echo "ID: ${ID}-${VERSION_ID}"
elif [ "$ID" == "centos" ]
then
    echo -n "${ID}-${VERSION_ID}" 
fi
