#!/bin/bash
export compiler=gcc-9.2.1
export mpi_library=hpcx
export BENCHMARK="conus2.5km" #"conus12km"

echo "Summarize the WRF Benchmarking Results"

basedir=$(pwd)
#nlist=($(pbsnodes -avS | grep 'free\|job' | awk -F ' ' '{print $1}'))
#VMINFO=$(ssh ${nlist[0]} sudo curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2018-10-01")
export clustertype=HX176rs #$(echo $VMINFO |sed -e 's/"//g' |sed -e 's/^.*vmSize://g' |cut -d"," -f1)
#clustertype=${clustertype#*_}

outdir=$1/$2/$3/hybrid

if [ -d "./run_${clustertype}/${compiler}/${mpi_library}/${BENCHMARK}" ]; then

res_file=./res_${clustertype}_${compiler}_${mpi_library}_WRF_${BENCHMARK}_benchmark.csv
rm -f ${res_file}

echo ""
echo "System ${clustertype}, build ${compiler} & ${mpi_library}, ${BENCHMARK} benchmarking test"

echo "nodes,ppn,tasks,threads,time,speed,gfp" > ${res_file}

for RESULT in $(find ./run_${clustertype}/${compiler}/${mpi_library}/${BENCHMARK}/WRF* -name outputfile.log |sort -V);  do
 	meantime=$(grep "mean:    " ${RESULT} | awk -F ' ' '{print $2}')
    timestep=$(grep "time_step:    "  ${RESULT} | awk -F ' ' '{print $2}')
	nodes=$(echo ${RESULT} |cut -d"/" -f6 |cut -d"_" -f2)
    ppn=$(echo ${RESULT} |cut -d"/" -f6 |cut -d"_" -f3)
    thrds=$(echo ${RESULT} |cut -d"/" -f6 |cut -d"_" -f4| cut -d "." -f1)
    ntasks=$((nodes * ppn))
	if [ ! -z "$meantime" ]; then
        speed=$(echo $timestep/$meantime | bc -l)
        gfp=$(echo $speed*27.45 | bc -l)
	    echo "N=$nodes ppn=$ppn tasks=$ntasks thrd=$thrds T=$meantime Speed=$speed GFP/s=$gfp"
	    echo $nodes,$ppn,$ntasks,$thrds,$meantime,$speed,$gfp >> ${res_file}
	fi
done

fi
