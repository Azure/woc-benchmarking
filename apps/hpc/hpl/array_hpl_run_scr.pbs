#!/bin/bash

#PBS -N hpl-amd-single-node
#PBS -l walltime=06:00:00
#PBS -l select=1:ncpus=120:mpiprocs=16
#PBS -l place=scatter:exclhost
#PBS -j oe
##PBS -q test
#PBS -J 1-64

module load mpi/hpcx

ulimit -s unlimited
ulimit -l unlimited
ulimit -a

echo always | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
echo always | sudo tee /sys/kernel/mm/transparent_hugepage/defrag

cd $PBS_O_WORKDIR

hosts=($(cat $PBS_NODEFILE | sort -u))
nhost=$(cat $PBS_NODEFILE | sort -u | wc -l)

JOBID=`echo ${PBS_JOBID} | cut -d'[' -f1`

mkdir HPL-N${nhost}-96PPN.${JOBID}-${PBS_ARRAY_INDEX}
cd HPL-N${nhost}-96PPN.${JOBID}-${PBS_ARRAY_INDEX}

cp ../HPL.dat .
cp ../appfile*_ccx .
cp ../xhpl_ccx.sh .
cp ../xhpl .

export mpi_options="--mca mpi_leave_pinned 1 --bind-to none --report-bindings --mca btl self,vader --map-by ppr:1:l3cache -x OMP_NUM_THREADS=6 -x OMP_PROC_BIND=TRUE -x OMP_PLACES=cores -x LD_LIBRARY_PATH"

echo "Running on $(hostname)" > hpl-${PBS_ARRAY_INDEX}.log
mpirun $mpi_options -app ./appfile_ccx  >> hpl-${PBS_ARRAY_INDEX}.log     
echo "system: $(hostname) HPL: $(grep WR hpl*.log | awk -F ' ' '{print $7}')" >> ../hpl-test-results.log
