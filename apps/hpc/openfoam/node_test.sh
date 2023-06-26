#!/bin/bash

# Argv[1] should be directory for storing cluster information

hostname=$(/usr/bin/hostname)
outputfile=$1/$hostname

echo "System info:" > $outputfile 2>&1
echo "" >> $outputfile 2>&1
uname -a >> $outputfile 2>&1
echo "" >> $outputfile 2>&1
cat /etc/os-release  >> $outputfile 2>&1
echo "" >> $outputfile 2>&1
echo "cpuinfo" >> $outputfile 2>&1
cat /proc/cpuinfo >> $outputfile 2>&1
echo "" >> $outputfile 2>&1
echo "meminfo" >> $outputfile 2>&1
cat /proc/meminfo >> $outputfile 2>&1
echo "" >> $outputfile 2>&1
echo "numactl" >> $outputfile 2>&1
numactl --hardware >> $outputfile 2>&1
echo "" >> $outputfile 2>&1
echo "lspci" >> $outputfile 2>&1
sudo --non-interactive lspci >> $outputfile 2>&1
echo "" >> $outputfile 2>&1
echo "lshw" >> $outputfile 2>&1
sudo --non-interactive lshw >> $outputfile 2>&1
echo "" >> $outputfile 2>&1
echo "sysctl" >> $outputfile 2>&1
sudo --non-interactive sysctl -a >> $outputfile 2>&1
echo "" >> $outputfile 2>&1

echo "Software info:" >> $outputfile 2>&1
echo "" >> $outputfile 2>&1
echo "modules" >> $outputfile 2>&1
module list >> $outputfile 2>&1
echo "" >> $outputfile 2>&1
echo "environment variables" >> $outputfile 2>&1
env >> $outputfile 2>&1

echo "" >> $outputfile 2>&1
echo "What is running on system (ex root)?:" >> $outputfile 2>&1
ps -ef |grep -v root >> $outputfile 2>&1
