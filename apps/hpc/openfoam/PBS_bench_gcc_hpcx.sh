#!/bin/bash

export compiler=gcc-12.2.0
export mpi_library=hpcx-v2.14.0
export FOAM_SPEC="openfoam@2006"
export MESH_DIM="120x88x88"
export NODE_LIST=(1 2 4 8)
export PPN_LIST=(96 120 176)
export APPNS=${APPNS:-/share/home/hpcuser/woc-benchmarking/apps/hpc/utils/azure_process_pinning.sh}  #PATH to azure_process_pinning.sh script


basedir=$(pwd)
VMINFO=$(sudo curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2018-10-01")
export clustertype=GenoaX #$(echo $VMINFO |sed -e 's/"//g' |sed -e 's/^.*vmSize://g' |cut -d"," -f1 |cut -d"_" -f2)

yes | sudo yum install python3
module load $compiler
module load mpi/$mpi_library 
hpcx_load
export PATH="/apps/spack/bin/:$PATH"
. /apps/spack/share/spack/setup-env.sh

spack load $FOAM_SPEC

# Directory in which OpenFOAM is compiled/installed
#export az_FOAMROOT=${basedir}/openfoam/7.20200120/${compiler}/${mpi_library}
export az_FOAMROOT=$WM_PROJECT_DIR
source $FOAM_ETC/bashrc

# Name of log file
LOGFILE=log_${clustertype}_bench_${compiler}_${mpi_library}.txt

# File to keep a record of jobid for each meshing run
touch ${LOGFILE}

# Specific version of OpenFOAM we want
export az_FOAM_VERSION=''

# We only want the scheduler to run one job at a time so that we are devoting all resources to the code in question
# Chain the jobs so that each one is only launched after the previous one finishes
# Get a job ID to chain the others from
JOBID=INITIALIZE

for PROB_SIZE in $MESH_DIM; do

export az_FOAM_SIZE=$PROB_SIZE

for NODES in ${NODE_LIST[@]}; do
for PPN in ${PPN_LIST[@]}; do
for REPS in 1 ; do

let NTASKS=$NODES*$PPN

## Set up base directory for running benchmark
OUTPUTDIR=${basedir}/run_${clustertype}/${compiler}/${mpi_library}/motorbike_${az_FOAM_SIZE}
mkdir -p $OUTPUTDIR
cd $OUTPUTDIR

source $APPNS $PPN 1
export mppflags="--bind-to cpulist:ordered --cpu-set $AZURE_PROCESSOR_LIST --rank-by slot --report-bindings"

## WRITE SUBMISSION SCRIPT
cat <<EOF > bench_${NODES}_${PPN}.pbs
#!/bin/bash
#PBS -N bench_motorBike_${NTASKS}_${NODES}_${PPN}
#PBS -l walltime=03:00:00
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

key0=\$(cat /sys/class/infiniband/mlx5_0/ports/1/pkeys/0)
key1=\$(cat /sys/class/infiniband/mlx5_0/ports/1/pkeys/1)
    if [ \$((\$key0 - \$key1)) -gt 0 ]; then
        export IB_PKEY=\$key0
    else
        export IB_PKEY=\$key1
    fi
UCX_IB_PKEY=\$(printf '0x%04x' "\$(( \$IB_PKEY & 0x0FFF ))")
echo UCX_IB_PKEY is \$UCX_IB_PKEY

cd \$PBS_O_WORKDIR

## Now create a separate subdirectory for this specific run
OUTPUTDIR=${OUTPUTDIR}/BENCH_${NTASKS}_${NODES}_${PPN}_pbs\${PBS_JOBID}

if [ -e \$OUTPUTDIR ]; then
  echo "Error: Benchmark directory \$OUTPUTDIR already exists"
  exit
fi

mkdir -p \$OUTPUTDIR

cd \$OUTPUTDIR

##cat \$PBS_NODEFILE | sort -u > hostlist
##HOSTFILE=hostlist

# mpirun option to run one process per node, or force round-robin distribution across nodes
# File "hostlist.bench" will be generated in run_benchmark.sh
####for openmpi & hpcx
export mpi_one_per_node="-machinefile hostlist.bench -np $NODES --map-by node"

# mpi_options must be set to pass correct mpirun flags to generate_mesh.sh script
# Add "-display-map" for extra info on task placement
####for openmpi & hpcx
#### hpcx with all ucx options

export mpi_options="-machinefile \$PBS_NODEFILE -np $NTASKS $mppflags --rank-by slot -x UCX_TLS=dc_x,sm,self -x LD_LIBRARY_PATH -x PATH -x PWD -x MPI_BUFFER_SIZE -x WM_PROJECT_DIR -x WM_DIR -x WM_PROJECT_USER_DIR -x WM_PROJECT_INST_DIR"

bash ${basedir}/run_benchmark.sh ${az_FOAMROOT}/${az_FOAM_VERSION} \$OUTPUTDIR . $NODES $PPN "${mpi_library}" "${SPACK_VERSION}" "${FOAM_SPEC}"

EOF

## Submit job
if test "${JOBID}" = "INITIALIZE"; then
  JOBID=$(qsub bench_${NODES}_${PPN}.pbs) 
else
  JOBID=$(qsub -W depend=afterany:$JOBID bench_${NODES}_${PPN}.pbs) 
fi
echo "${az_FOAM_VERSION} Bench: motorbike_${PROB_SIZE}, tasks ${NTASKS} nodes ${NODES} ppn ${PPN}, PBS job id ${JOBID}" >> ${basedir}/${LOGFILE}

cd ${basedir}
done
done
done
done

cat ${basedir}/${LOGFILE}
