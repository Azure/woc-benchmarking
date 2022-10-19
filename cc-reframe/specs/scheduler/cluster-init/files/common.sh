#!/bin/bash

# Determine the OS version
. /usr/lib/os-release

if [ "$ID" == "almalinux" ]
then
    majVer=(${VERSION_ID//./ })
    echo "$ID-${majVer[0]}"
elif [ "$ID" == "ubuntu" ]
then
    echo "ID: $ID"
elif [ "$ID" == "centos" ]
then
    echo -n "$ID" 
    if [ "$VERSION_ID" == "7" ]
    then
        echo "-$VERSION_ID"
    elif [ "$VERSION_ID" == "8" ]
    then
        echo "-$VERSION_ID"
    fi
fi
