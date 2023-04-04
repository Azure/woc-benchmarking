#!/bin/bash

#SBATCH --time=20:00:00
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=96
#SBATCH --mem=400gb
#SBATCH --job-name=Starccm
#SBATCH --exclusive
#SBATCH -o %x_%j.log

# parameters that can be overridden
APP_INSTALL_DIR=${APP_INSTALL_DIR:-/shared/apps}
DATA_DIR=${DATA_DIR:-/shared/data/starccm}
CASE=${CASE:-civil}
OMPI=${OMPI:-openmpi4}
STARCCM_VERSION=${STARCCM_VERSION:-17.02.008}
WOC_BENCH_DIR=${WOC_BENCH_DIR:-~/woc-benchmarking}
PODKEY=""

# PODKEY is required (pass in as environment variable)
if [ -z "$PODKEY" ];
then
    echo "Error: the PODKEY environment variable is not set"
    exit 1
fi

INSTALL_DIR=$APP_INSTALL_DIR/starccm
STARCCM_CASE=$DATA_DIR/${CASE}.sim

export PATH=$INSTALL_DIR/$STARCCM_VERSION/STAR-CCM+$STARCCM_VERSION/star/bin:$PATH
export CDLMD_LICENSE_FILE=1999@flex.cd-adapco.com

## SLURM: ====> Job Node List (DO NOT MODIFY)
echo "Slurm nodes assigned :$SLURM_JOB_NODELIST"
echo "SLURM_JOBID="$SLURM_JOBID
echo "SLURM_JOB_NODELIST"=$SLURM_JOB_NODELIST
echo "SLURM_NNODES"=$SLURM_NNODES
echo "SLURMTMPDIR="$SLURMTMPDIR
echo "working directory = "$SLURM_SUBMIT_DIR
echo "SLURM_NTASKS="$SLURM_NTASKS

mkdir -p $SLURM_SUBMIT_DIR/$SLURM_JOBID
cd $SLURM_SUBMIT_DIR/$SLURM_JOBID

NODES=$SLURM_NNODES
PPN=$SLURM_NTASKS_PER_NODE
CORES=$SLURM_NTASKS

BM_OPT="-preclear -preits 40 -nits 20 -nps $CORES"
if [ "$CASE" = "EmpHydroCyclone_30M" ]
then
    BM_OPT="-preits 1 -nits 1 -nps $CORES"
elif [ "$CASE" = "kcs_with_physics" ]
then
    BM_OPT="-preits 40 -nits 20 -nps $CORES"
fi

echo $BM_OPT
echo PPN=$PPN

echo "Running Starccm Benchmark case : [${starccm_case}], Nodes: ${NODES} (Total Cores: ${CORES})"

source $WOC_BENCH_DIR/apps/hpc/utils/azure_process_pinning.sh $SLURM_NTASKS_PER_NODE
export mppflags="--bind-to cpulist:ordered --cpu-set $AZURE_PROCESSOR_LIST --rank-by slot --report-bindings -mca mca_base_env_list UCX_TLS=dc_x,sm;UCX_MAX_RNDV_RAILS=1"

if [[ "$OMPI" == "intel" || "$OMPI" == "intelmpi" ]]
then
    mppflags=$AZURE_IMPI_FLAGS
else 
    export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH
    source /opt/hpcx-*-x86_64/hpcx-init.sh
    hpcx_load
    export OPENMPI_DIR=$HPCX_MPI_DIR
    mppflags=$AZURE_OPENMPI_FLAGS
fi 

echo "mppflags: $mppflags"
export LD_PRELOAD=${WOC_BENCH_DIR}/libnvidia-ml.so
export LD_LIBRARY_PATH="${WOC_BENCH_DIR}:$LD_LIBRARY_PATH"

starccm+ \
    -v \
    -batchsystem slurm \
    -power \
    -podkey "$PODKEY" \
    -rsh ssh \
    -mpi $OMPI \
    -cpubind off \
    -ldlibpath $LD_LIBRARY_PATH \
    -ldpreload $LD_PRELOAD \
    -mppflags "$mppflags" \
    $STARCCM_CASE -benchmark "$BM_OPT"

DATE=$(date +"%Y%m%d-%H%M%S.%N")
cp $CASE-*.xml $SLURM_SUBMIT_DIR/${CASE}-${OMPI}-${NODES}n-${PPN}cpn-${CORES}c-${DATE}.xml
