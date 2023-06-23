#!/bin/bash

export compiler=gcc-13.1.0
export mpi_library=hpcx-v2.15.0
export FOAM_SPEC="openfoam@2006"
export MESH_DIM="120x88x88"
export NODE_LIST=(16 32)
export PPN_LIST=(176 120 96)

basedir=$(pwd)
VMINFO=$(sudo curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2018-10-01")
export clustertype=$(echo $VMINFO |sed -e 's/"//g' |sed -e 's/^.*vmSize://g' |cut -d"," -f1 |cut -d"_" -f2)

yes | sudo yum install python3
module load $compiler
module load mpi/$mpi_library 
export PATH="/apps/spack/bin/:$PATH"
. /apps/spack/share/spack/setup-env.sh

spack load $FOAM_SPEC

# Directory in which OpenFOAM is compiled/installed
export az_FOAMROOT=$WM_PROJECT_DIR
source $FOAM_ETC/bashrc


LOGFILE=log_${clustertype}_decompose_${compiler}_${mpi_library}.txt

# File to keep a record of jobid for each meshing run
touch ${LOGFILE}

# Specific version of OpenFOAM we want
export az_FOAM_VERSION='' # OpenFOAM-7

# We only want the scheduler to run one job at a time so that we are devoting all resources to the code in question
# Chain the jobs so that each one is only launched after the previous one finishes
# Get a job ID to chain the others from
JOBID=INITIALIZE

for PROB_SIZE in $MESH_DIM; do

export az_FOAM_SIZE=$PROB_SIZE

for NODES in ${NODE_LIST[@]}; do
for PPN in ${PPN_LIST[@]}; do

let NTASKS=$NODES*$PPN

## Set up base directory for running benchmark
OUTPUTDIR=${basedir}/run_${clustertype}/${compiler}/${mpi_library}/motorbike_${az_FOAM_SIZE}
mkdir -p $OUTPUTDIR
cd $OUTPUTDIR

## WRITE SUBMISSION SCRIPT
## (Note: Despite values of NODES and PPN above, this is a serial job.
##        Grab one node but specify multiple cores, in case memory limit/core applies)
cat <<EOF > decompose_${NODES}_${PPN}.pbs
#!/bin/bash
#PBS -N decompose_motorBike
#PBS -l walltime=08:30:00
##PBS -l select=$NODES:ncpus=$PPN:mpiprocs=$PPN:ompthreads=1
#PBS -l select=1:ncpus=$PPN:mpiprocs=$PPN:ompthreads=1
#PBS -v NODES_N=$NODES,PPN_N=$PPN
#PBS -l place=scatter:exclhost
#PBS -j oe

ulimit -s unlimited
ulimit -l unlimited
ulimit -a

module load $compiler
module load mpi/$mpi_library
module list

export OMP_NUM_THREADS=1

cd \$PBS_O_WORKDIR

## Now create a separate subdirectory for this specific run
OUTPUTDIR=${OUTPUTDIR}/DECOMPOSE_${NTASKS}_${NODES}_${PPN}

if [ -e \$OUTPUTDIR ]; then
  echo "Error: Decompose directory \$OUTPUTDIR already exists"
  exit
fi

mkdir -p \$OUTPUTDIR

cd \$OUTPUTDIR

bash ${basedir}/decompose.sh ${az_FOAMROOT}/${az_FOAM_VERSION} \$OUTPUTDIR . $NODES $PPN "${mpi_library}" "${SPACK_VERSION}" "${FOAM_SPEC}"

EOF

## Submit job
if test "${JOBID}" = "INITIALIZE"; then
  JOBID=$(qsub decompose_${NODES}_${PPN}.pbs) 
else
  JOBID=$(qsub -W depend=afterany:$JOBID decompose_${NODES}_${PPN}.pbs) 
fi
echo "${az_FOAM_VERSION} Decompose: motorbike_${PROB_SIZE}, tasks ${NTASKS} nodes ${NODES} ppn ${PPN}, PBS job id ${JOBID}" >> ${basedir}/${LOGFILE}

cd ${basedir}
done
done
done

cat ${basedir}/${LOGFILE}
