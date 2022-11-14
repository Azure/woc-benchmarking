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

sed -i "s/4           Ps/4           Ps/g" HPL.dat
sed -i "s/4            Qs/8            Qs/g" HPL.dat

echo "Running on $(hostname | tr "[:upper:]" "[:lower:]")" > hpl-$(hostname | tr "[:upper:]" "[:lower:]").log
mpirun -np 32 --report-bindings --mca btl self,vader --map-by ppr:1:l3cache:pe=3 -x OMP_NUM_THREADS=3 -x OMP_PROC_BIND=TRUE -x OMP_PLACES=cores -x LD_LIBRARY_PATH xhpl >> hpl-$(hostname | tr "[:upper:]" "[:lower:]").log
#echo "system: $(hostname | tr "[:upper:]" "[:lower:]") HPL: $(grep WR hpl*.log | awk -F ' ' '{print $7}')" >> ../hpl-test-results.log
