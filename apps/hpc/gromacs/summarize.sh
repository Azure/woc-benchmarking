#!/bin/bash
export compiler=gcc-13.1.0
export mpi_library=hpcx-v2.15
export BENCHMARK="PEP"  #"PEP" #"RIB"

echo "Summarize the GMX Benchmarking Results"

basedir=$(pwd)
nlist=($(pbsnodes -avS | grep 'free\|job' | awk -F ' ' '{print $1}'))
VMINFO=$(ssh ${nlist[0]} sudo curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2018-10-01")
export clustertype=$(echo $VMINFO |sed -e 's/"//g' |sed -e 's/^.*vmSize://g' |cut -d"," -f1)
clustertype=${clustertype#*_}

outdir=$1/$2/$3/hybrid

if [ -d "./run_${clustertype}/${compiler}/${mpi_library}/${BENCHMARK}" ]; then

res_file=./res_${clustertype}_${compiler}_${mpi_library}_GMX_bench${BENCHMARK}.csv
rm -f ${res_file}

echo ""
echo "System ${clustertype}, build ${compiler} & ${mpi_library}, bench${BENCHMARK} benchmarking test"

echo "nodes,ppn,tasks,threads,wtime,ns/day" > ${res_file}
echo -e "N\tppn\ttasks\tthreads\tWtime\t\tns/day"
echo "--------------------------------------------------------"

for RESULT in $(find ./run_${clustertype}/${compiler}/${mpi_library}/${BENCHMARK}/GMX* -name output.log |sort -V);  do
 	ns=$(grep "Performance:" ${RESULT} | awk -F ' ' '{print $2}')
    wtime=$(grep "Time:"  ${RESULT} | awk -F ' ' '{print $3}')
	nodes=$(echo ${RESULT} |cut -d"/" -f6 |cut -d"_" -f2)
    ppn=$(echo ${RESULT} |cut -d"/" -f6 |cut -d"_" -f3)
    thrds=$(echo ${RESULT} |cut -d"/" -f6 |cut -d"_" -f4| cut -d "." -f1)
    ntasks=$((nodes * ppn))
	if [ ! -z "$ns" ]; then
	    echo -e "$nodes\t$ppn\t$ntasks\t$thrds\t$wtime\t\t$ns"
	    echo $nodes,$ppn,$ntasks,$thrds,$wtime,$ns >> ${res_file}
	fi
done

fi
