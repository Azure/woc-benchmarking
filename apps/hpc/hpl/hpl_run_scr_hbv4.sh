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
cp ../appfile_ccx_hbv4 .
cp ../xhpl_ccx.sh .
cp ../xhpl .

sed -i "s/128000/256000/g" HPL.dat
sed -i "s/4           Ps/11           Ps/g" HPL.dat
sed -i "s/4            Qs/8           Qs/g" HPL.dat
sed -i "s/2            BCASTs (0=1rg,1=1rM,2=2rg,3=2rM,4=Lng,5=LnM)/1            BCASTs/g" HPL.dat


#export mpi_options="--mca mpi_leave_pinned 1 --bind-to none --report-bindings --map-by ppr:6:numa:PE=6 -x OMP_NUM_THREADS=6 -x OMP_PROC_BIND=TRUE -x OMP_PLACES=cores -x UCX_TLS=dc_x,\knem,self -x LD_LIBRARY_PATH"
export mpi_options="--mca mpi_leave_pinned 1 --mca btl vader,self --bind-to core --report-bindings --map-by ppr:88:node:PE=2 --rank-by slot -x OMP_NUM_THREADS=2 -x OMP_PROC_BIND=TRUE -x OMP_PLACES=cores -x LD_LIBRARY_PATH"
mpirun $mpi_options ./xhpl >> hpl-$(hostname | tr "[:upper:]" "[:lower:]").log

#echo "Running on $(hostname | tr "[:upper:]" "[:lower:]")" > hpl-$(hostname | tr "[:upper:]" "[:lower:]").log
#mpirun $mpi_options -app ./appfile_ccx_hbv4  >> hpl-$(hostname | tr "[:upper:]" "[:lower:]").log
#echo "system: $(hostname | tr "[:upper:]" "[:lower:]") HPL: $(grep WR hpl*.log | awk -F ' ' '{print $7}')" >> ../hpl-test-results.log
