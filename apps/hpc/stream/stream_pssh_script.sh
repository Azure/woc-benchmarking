#!/bin/bash

#SKU type
SKU=$1

export wdir=$(pwd)
sudo yum install pssh -y
echo "beginning date: $(date)"
echo $(hostname | tr "[:upper:]" "[:lower:]") > hosts.txt

if command -v pbsnodes --version &> /dev/null
then
    pbsnodes -avS | grep free | awk -F ' ' '{print tolower($1)}' >> hosts.txt
fi

pssh -p 32 -t 0 -i -h hosts.txt "cd $wdir && ./stream_run_script.sh $wdir $SKU" >> stream_pssh.log 2>&1
sleep 60

IFS=$'\n' read -d '' -r -a names < ./hosts.txt
for i in ${names[@]}; do
    echo "system: $i stream: $(grep 'Triad:' ./stream-$i/stream-*.log | awk '{print $2}') MB/s" >> stream-test-results.log
done
    
