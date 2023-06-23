#!/bin/bash

export compiler=gcc-13.1.0
export mpi_library=hpcx-v2.15.0
export FOAM_SPEC="openfoam@2006"
export MESH_DIM="120x88x88"
export NODES=15
export PPN=144

basedir=$(pwd)
VMINFO=$(sudo curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2018-10-01")
export clustertype=$(echo $VMINFO |sed -e 's/"//g' |sed -e 's/^.*vmSize://g' |cut -d"," -f1 |cut -d"_" -f2)

yes | sudo yum install python3
module use /apps/gcc/gcc/module/
module load $compiler
module use mpi/$mpi_library
export PATH="/apps/spack/bin/:$PATH"
. /apps/spack/share/spack/setup-env.sh

spack load $FOAM_SPEC

# Directory in which OpenFOAM is compiled/installed
export az_FOAMROOT=$WM_PROJECT_DIR
source $FOAM_ETC/bashrc

cp ${basedir}/decomposeParDict $WM_PROJECT_DIR/tutorials/incompressible/simpleFoam/motorBike/system/ 

# Name of log file
LOGFILE=log_${clustertype}_mesh_${compiler}_${mpi_library}.txt

# File to keep a record of jobid for each meshing run
touch ${LOGFILE}

# Specific version of OpenFOAM we want
export az_FOAM_VERSION=''

for PROB_SIZE in $MESH_DIM; do

export az_FOAM_SIZE=$PROB_SIZE

# Just use one size for meshing. PPN should be multiple of 4.

NTASKS=$(($NODES * $PPN))

## Set up base directory for running benchmark
OUTPUTDIR=${basedir}/run_${clustertype}/${compiler}/${mpi_library}/motorbike_${az_FOAM_SIZE}
mkdir -p $OUTPUTDIR
cd $OUTPUTDIR

## WRITE SUBMISSION SCRIPT
cat <<EOF > mesh_${NODES}_${PPN}.pbs
#!/bin/bash
#PBS -N mesh_motorBike
#PBS -l walltime=08:00:00
#PBS -l select=$NODES:ncpus=$PPN:mpiprocs=$PPN:ompthreads=1
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
OUTPUTDIR=${OUTPUTDIR}/MESH_${NTASKS}_${NODES}_${PPN}

if [ -e \$OUTPUTDIR ]; then
  echo "Error: Mesh directory \$OUTPUTDIR already exists"
  exit
fi

mkdir -p \$OUTPUTDIR

cd \$OUTPUTDIR

cat \$PBS_NODEFILE | sort -u > hostlist
HOSTFILE=hostlist

# mpi_options must be set to pass correct mpirun flags to generate_mesh.sh script
####for openmpi & hpcx
export mpi_options="-machinefile \$PBS_NODEFILE -np $NTASKS -x LD_LIBRARY_PATH -x PATH -x PWD -x MPI_BUFFER_SIZE -x WM_PROJECT_DIR -x WM_DIR -x WM_PROJECT_USER_DIR -x WM_PROJECT_INST_DIR"

bash ${basedir}/generate_mesh.sh ${az_FOAMROOT}/${az_FOAM_VERSION} \$OUTPUTDIR . $NODES $PPN "$(echo ${PROB_SIZE} |sed -e 's/x/ /g')" "${mpi_library}" "${SPACK_VERSION}" "${FOAM_SPEC}"

EOF

## Submit job
JOBID=$(qsub mesh_${NODES}_${PPN}.pbs) 
echo "${az_FOAM_VERSION} Meshing: motorbike_${PROB_SIZE}, tasks ${NTASKS} nodes ${NODES} ppn ${PPN}, PBS job id ${JOBID}" >> ${basedir}/${LOGFILE}

cd ${basedir}
done

cat ${basedir}/${LOGFILE}
