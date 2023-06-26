#!/bin/bash

INSTALL_DIR="$1"
RUN_DIR="$2"
CASE_NAME="$3"
NODES="$4"
PPN="$5"
mpi_library="$6"
SPACK_VERSION="$7"
FOAM_SPEC="$8"

NTASKS=$(($NODES * $PPN))


echo -n "Azure benchmark: start run_benchmark "
date +%s ; date -u

yes | sudo yum install python3
source /opt/hpcx*/hpcx-init.sh
hpcx_load
export PATH="/apps/spack/bin/:$PATH"
. /apps/spack/share/spack/setup-env.sh
spack load $FOAM_SPEC 

source $INSTALL_DIR/etc/bashrc FOAMY_HEX_MESH=yes
source $FOAM_ETC/bashrc

. ${WM_PROJECT_DIR:?}/bin/tools/RunFunctions

cd $RUN_DIR/..
DECOMPOSE_NAME=DECOMPOSE_${NTASKS}_${NODES}_${PPN}
DECOMPOSE_DIR=$(pwd)/${DECOMPOSE_NAME}

decompDict="decomposePar -decomposeParDict system/decomposeParDict"

cd $RUN_DIR
if [ -d ${DECOMPOSE_DIR} ]; then
  cp -pr $DECOMPOSE_DIR/* $CASE_NAME
else
  echo "Error: Decompose directory ${DECOMPOSE_DIR} not found"
  exit
fi

cd $CASE_NAME
# Limited usefulness, won't catch all errors.
if [ !-e "log.decomposeParMultiLevel" ]; then
  echo "Error: decompose step failed"
  exit
fi

# Gather list of hosts and log system settings
cat $PBS_NODEFILE | sort -u > hostlist.bench
SCRIPTDIR=$(cd ../../../../../; pwd)
CLUSTER_LOG_DIR=${CASE_NAME}/cluster_logs
mkdir -p ${CLUSTER_LOG_DIR}

# Check that we are running what we think we are running.
which mpirun
echo "mpi_options = " $mpi_options
echo "mpi_one_per_node = " $mpi_one_per_node
which potentialFoam


#- For parallel running: set the initial fields
restore0Dir -processor


mpirun $mpi_one_per_node ${SCRIPTDIR}/node_test.sh ${CLUSTER_LOG_DIR}

foamDictionary -entry relaxationFactors.equations.U -set 0.1 system/fvSolution                                ###was 0.1
foamDictionary -entry relaxationFactors.equations.k -set 0.1 system/fvSolution                                ###was 0.1
foamDictionary -entry relaxationFactors.equations.omega -set 0.025 system/fvSolution                            ###was 0.025
foamDictionary -entry relaxationFactors.fields.p -set 0.08 system/fvSolution                                   ###was 0.08

foamDictionary -entry writeInterval -set 1000 system/controlDict
foamDictionary -entry runTimeModifiable -set "false" system/controlDict
foamDictionary -entry functions -set "{}" system/controlDict

# Reduce timesteps from 500 to 250
# Matches setting in https://github.com/OpenFOAM/OpenFOAM-Intel/tree/master/benchmarks/motorbike
foamDictionary -entry endTime -set 250 system/controlDict

# mpi_options must have been set an environment variable by batch script 
echo -n "Azure benchmark: running potentialFoam "
date +%s ; date -u

#mpirun $mpi_options $decompDict potentialFoam -parallel 2>&1 | tee log.potentialFoam
mpirun $mpi_options potentialFoam -parallel 2>&1 | tee log.potentialFoam

echo -n "Azure benchmark: running simpleFoam "
date +%s ; date -u
#mpirun $mpi_options simpleFoam -decomposeParDict system/decomposeParDict -parallel 2>&1 | tee log.simpleFoam
mpirun $mpi_options simpleFoam -parallel 2>&1 | tee log.simpleFoam

echo -n "Azure benchmark: cleaning up "
date +%s ; date -u

touch case.foam

rm -rf ./processor*
echo -n "Azure benchmark: finish run_benchmark "
date +%s ; date -u
