#!/bin/bash

VM_SERIES=$1
export wdir=$(pwd)

sudo yum install pssh -y

echo "beginning date: $(date)"

echo $(hostname | tr "[:upper:]" "[:lower:]") > hosts.txt

if command -v pbsnodes --version &> /dev/null
then
	pbsnodes -avS | grep free | awk -F ' ' '{print tolower($1)}' >> hosts.txt
fi

if [ "${VM_SERIES}" == "hbrs_v4" ]; then
	pssh -p 301 -t 0 -i -h hosts.txt "cd $wdir && ./hpl_run_scr_hbv4.sh $wdir" >> hpl_pssh.log 2>&1
elif [ "${VM_SERIES}" == "hbrs_v3" ]; then
	pssh -p 301 -t 0 -i -h hosts.txt "cd $wdir && ./hpl_run_scr_hbv3.sh $wdir" >> hpl_pssh.log 2>&1
elif [ "${VM_SERIES}" == "hbrs_v2" ]; then
	pssh -p 301 -t 0 -i -h hosts.txt "cd $wdir && ./hpl_run_scr_hbv2.sh $wdir" >> hpl_pssh.log 2>&1
else
    echo "No defined VM series entered"
    exit 1
fi

sleep 60

IFS=$'\n' read -d '' -r -a names < ./hosts.txt
for i in ${names[@]}; do
    echo "system: $i HPL: $(grep WR ./HPL-test.$i/hpl*.log | awk -F ' ' '{print $7}')" >> hpl-test-results.log
done

echo "end date: $(date)"
exit 0

