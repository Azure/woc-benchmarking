#!/bin/bash
export compiler=gcc-13.1.0
export mpi_library=hpcx-v2.15
export BENCHMARK="H2O-DFT-LS" #"LIH-HFX"

echo "Summarize the CP2K Benchmarking Results"

basedir=$(pwd)
VMINFO=$(sudo curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2018-10-01")
export clustertype=$(echo $VMINFO |sed -e 's/"//g' |sed -e 's/^.*vmSize://g' |cut -d"," -f1 |cut -d"_" -f2)

outdir=$1/$2/$3/hybrid

if [ -d "./run_${clustertype}/${compiler}/${mpi_library}/${BENCHMARK}" ]; then

res_file=./res_${clustertype}_${compiler}_${mpi_library}_CP2K_${BENCHMARK}_benchmark.csv
rm -f ${res_file}

echo ""
echo "System ${clustertype}, build ${compiler} & ${mpi_library}, ${BENCHMARK} benchmarking test"

echo "#nodes,ppn,tasks,threads,time" > ${res_file}

for RESULT in $(find ./run_${clustertype}/${compiler}/${mpi_library}/${BENCHMARK}/CP2K* -name outputfile.log |sort -V);  do
 	executiontime=$(grep "CP2K    " ${RESULT} | awk -F ' ' '{print $6}')
	nodes=$(echo ${RESULT} |cut -d"/" -f6 |cut -d"_" -f2)
        ppn=$(echo ${RESULT} |cut -d"/" -f6 |cut -d"_" -f3)
        thrds=$(echo ${RESULT} |cut -d"/" -f6 |cut -d"_" -f4| cut -d "." -f1)
        ntasks=$((nodes * ppn))
	if [ ! -z "$executiontime" ]; then
	 echo "N=$nodes ppn=$ppn tasks=$ntasks thrd=$thrds T=$executiontime"
	 echo $nodes,$ppn,$ntasks,$thrds,$executiontime >> ${res_file}
	fi
done

fi
