#!/bin/bash
wdir=$1

#module load mpi/hpcx
source /opt/hpcx-*-x86_64/hpcx-init.sh
hpcx_load

ulimit -s unlimited
ulimit -l unlimited
ulimit -a

echo always | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
echo always | sudo tee /sys/kernel/mm/transparent_hugepage/defrag

cd $wdir

mkdir HPL-test.$(hostname | tr "[:upper:]" "[:lower:]")
cd HPL-test.$(hostname | tr "[:upper:]" "[:lower:]")

cp ../HPL.dat .
cp ../appfile*_ccx .
cp ../xhpl_ccx.sh .
cp ../xhpl .

export mpi_options="--mca mpi_leave_pinned 1 --bind-to none --report-bindings --mca btl self,vader --map-by ppr:4:numa:PE=6 -x OMP_NUM_THREADS=6 -x OMP_PROC_BIND=TRUE -x OMP_PLACES=cores -x LD_LIBRARY_PATH"

echo "Running on $(hostname | tr "[:upper:]" "[:lower:]")" > hpl-$(hostname | tr "[:upper:]" "[:lower:]").log
mpirun $mpi_options -app ./appfile_ccx_hbv3  >> hpl-$(hostname | tr "[:upper:]" "[:lower:]").log
#echo "system: $(hostname | tr "[:upper:]" "[:lower:]") HPL: $(grep WR hpl*.log | awk -F ' ' '{print $7}')" >> ../hpl-test-results.log
