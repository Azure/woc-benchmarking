#!/bin/bash
#PBS -N namd-apoa1
#PBS -l walltime=02:08:00
#PBS -l select=4:ncpus=120:mpiprocs=96:ompthreads=1
#PBS -l place=scatter:exclhost
#PBS -j oe

INSTALL_DIR=${INSTALL_DIR:-/apps/namd}
DATA_DIR=${DATA_DIR:-/data/apoa1}
CASE=${CASE:-apoa1}
APPNS=${APPNS:-/share/home/hpcuser/woc-benchmarking/apps/hpc/utils/azure_process_pinning.sh}  #PATH to azure_process_pinning.sh script

ulimit -s unlimited
ulimit -l unlimited
ulimit -a

module load gcc-9.2.0
module load mpi/hpcx
module use ${INSTALL_DIR}/modulefile
module load namd
module list

export OMP_NUM_THREADS=1

NAMD_PATH=$(command -v namd2)
echo "namd path:" ${NAMD_PATH}
echo "mpi library: $(command -v mpirun)"

export NODES=$(sort -u < $PBS_NODEFILE | wc -l)
export PPN=$(uniq -c < $PBS_NODEFILE | tail -n1 | awk '{print $1}')
export CORES=$(wc -l <$PBS_NODEFILE)
export NTHREADS=1

source $APPNS $PPN $NTHREADS
export mppflags="--bind-to cpulist:ordered --cpu-set $AZURE_PROCESSOR_LIST --rank-by slot --report-bindings"

cd $PBS_O_WORKDIR
mkdir ${NODES}N_${PPN}PPN.$PBS_JOBID
cd ${NODES}N_${PPN}PPN.$PBS_JOBID
ln -s ${DATA_DIR}/* .

cat $PBS_NODEFILE | sort -u > hostlist

export mpi_options="-machinefile $PBS_NODEFILE -np $CORES $mppflags -x LD_LIBRARY_PATH -x PATH "
echo mpi_options: $mpi_options

#mpirun $mpi_options ${NAMD_PATH} +isomalloc_sync *.namd > namd.log
mpirun $mpi_options ${NAMD_PATH} $CASE.namd > namd.log
sleep 1
#to find the wall time
cp $PBS_O_WORKDIR/ns_per_day.py .
./ns_per_day.py namd.log > timings.log 
nspd=$(./ns_per_day.py namd.log | grep "Nanoseconds per day:" | awk -F ' ' '{print $4}')
echo nodes=$NODES ppn=$PPN nanosecondperday=$nspd
echo $nspd > timing.log
sleep 1
rm *bin
sleep 1

exit 0

