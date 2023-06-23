#!/bin/bash

export compiler=gcc-13.1.0
export mpi_library=hpcx-v2.15.0
export MESH_DIM="120x88x88"

timesteps_expected=250

VMINFO=$(sudo curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2018-10-01")
export clustertype=GenoaX #$(echo $VMINFO |sed -e 's/"//g' |sed -e 's/^.*vmSize://g' |cut -d"," -f1 |cut -d"_" -f2)

debug=false
while test $# -gt 0
do
    case "$1" in
        --debug) debug=true
            ;;
        --*) echo "unknown option $1"
            exit
            ;;
        *) echo "unknown argument $1"
           exit
            ;;
    esac
    shift
done

echo "OpenFOAM 2006 Motorbike benchmark results:"
for SYSTEM in $clustertype; do

  for BUILD in $compiler/$mpi_library; do

    for PROB_SIZE in $MESH_DIM; do

      if [ -d "./run_${SYSTEM}/${BUILD}/motorbike_${PROB_SIZE}" ]; then

        res_file=./res_${SYSTEM}_$(echo ${BUILD} |sed -e 's%/%_%g')_${PROB_SIZE}_timesteps${timesteps_expected}.csv
        rm -f ${res_file}

        echo ""
        echo "System ${SYSTEM}, build ${BUILD}, problem_size ${PROB_SIZE}"
        if [ "${debug}" = "true" ]; then
          echo "Nodes, PPN, Tasks, Time for ${timesteps_expected} timesteps (secs), data_directory"
        else
          echo "Nodes, PPN, Tasks, Time for ${timesteps_expected} timesteps (secs)"
        fi
        echo "nodes,ppn,tasks,time" > ${res_file}

        for RESULT in $(find ./run_${SYSTEM}/${BUILD}/motorbike_${PROB_SIZE}/BENCH* -name log.simpleFoam |sort -V);  do

          # Check if correct number of timesteps has been done
          timesteps_done=$(grep "^Time = " ${RESULT} |tail -1 |cut -d" " -f3)
          executiontime=$(grep "ExecutionTime = " ${RESULT} |tail -1 |cut -d" " -f3)
          if [ "${timesteps_done}" != "${timesteps_expected}" ]; then
            echo "Error in ${RESULT}"
            echo "  Incorrect number of timesteps: ${timesteps_done} (executiontime: ${executiontime})"
            echo "  Expected number of timesteps : ${timesteps_expected}"
            echo "  Ignoring this output file"
          else
            ntasks=$(echo ${RESULT} |cut -d"/" -f6 |cut -d"_" -f2)
            nnodes=$(echo ${RESULT} |cut -d"/" -f6 |cut -d"_" -f3)
            ppn=$(echo ${RESULT} |cut -d"/" -f6 |cut -d"_" -f4)
            if [ "${debug}" = "true" ]; then
              echo $nnodes $ppn $ntasks $executiontime $(dirname ${RESULT})
            else
              echo $nnodes $ppn $ntasks $executiontime
            fi
            echo $nnodes,$ppn,$ntasks,$executiontime >> ${res_file}
          fi

        done

      fi
    done
  done
done
