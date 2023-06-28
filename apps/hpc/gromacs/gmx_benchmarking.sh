#!/bin/bash

export NODE_LIST=(1 2 4 8)
export PPN_LIST=(96 120 144 176)
export THRD_LIST=(1)
export compiler=gcc-13.1.0
export mpi_library=hpcx-v2.15 
export BENCHMARK="PEP" #  "PEP" #"RIB"
export REPS=3
export SKU_TYPE=hbv4

export INPUTDIR="/share/home/hpcuser/gromacs/inputs"  #directory where the initial conditions are residing
export GMX_BIN="/apps/gromacs/bin/"
#################################################################################################################
basedir=$(pwd)
nlist=($(pbsnodes -avS | grep 'free\|job' | awk -F ' ' '{print $1}'))
VMINFO=$(ssh ${nlist[0]} sudo curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2018-10-01")
export clustertype=$(echo $VMINFO |sed -e 's/"//g' |sed -e 's/^.*vmSize://g' |cut -d"," -f1)
clustertype=${clustertype#*_}

module use /apps/gcc/gcc-b/module/
module load $compiler
module load mpi/$mpi_library
module list 
source ${GMX_BIN}/GMXRC

GMX_MPI=$(command -v gmx_mpi)
echo "gmx mpi:" ${GMX_MPI}
echo "mpi library: $(command -v mpirun)"

JOBID=INITIALIZE

LOGFILE=log_${clustertype}_bench${BENCHMARK}_${compiler}_${mpi_library}.txt
# File to keep a record of the jobids of the benchmarking runs
touch ${LOGFILE}

OUTPUTDIR=${basedir}/run_${clustertype}/${compiler}/${mpi_library}/$BENCHMARK/
mkdir -p $OUTPUTDIR
cd $OUTPUTDIR

for NNODES in ${NODE_LIST[@]}; do
for NPPNS in ${PPN_LIST[@]}; do
for NTHRDS in ${THRD_LIST[@]}; do

NTASKS=$((NNODES * NPPNS))
NCPUS=$((NPPNS * NTHRDS))

cat <<EOF > ${BENCHMARK}_benchmark_${NNODES}_${NPPNS}_${NTHRDS}.pbs	
#!/bin/bash
#PBS -N gmx-${BENCHMARK}-${NNODES}_${NPPNS}_${NTHRDS}
#PBS -l walltime=02:08:00
#PBS -l select=$NNODES:ncpus=$NCPUS:mpiprocs=$NPPNS:ompthreads=$NTHRDS
#PBS -l place=scatter:exclhost
#PBS -j oe

ulimit -s unlimited
ulimit -l unlimited
ulimit -a

module use /apps/gcc/gcc-b/module/
module load $compiler
module load mpi/$mpi_library
module list
source ${GMX_BIN}/GMXRC

export OMP_NUM_THREADS=$NTHRDS

GMX_MPI=\$(command -v gmx_mpi)
echo "gmx mpi:" \${GMX_MPI}
echo "mpi library: \$(command -v mpirun)"

key0=\$(cat /sys/class/infiniband/mlx5_ib0/ports/1/pkeys/0)
key1=\$(cat /sys/class/infiniband/mlx5_ib0/ports/1/pkeys/1)
    if [ \$((\$key0 - \$key1)) -gt 0 ]; then
        export IB_PKEY=\$key0
    else
        export IB_PKEY=\$key1
    fi
export UCX_IB_PKEY=\$(printf '0x%04x' "\$(( \$IB_PKEY & 0x0FFF ))")
echo UCX_IB_PKEY is \$UCX_IB_PKEY

if [ "$NPPNS" == "96" ]
then
            mppflags="--bind-to cpulist:ordered --cpu-set 0,1,2,3,8,9,10,11,16,17,18,19,24,25,26,27,32,33,34,35,38,39,40,41,44,45,46,47,52,53,54,55,60,61,62,63,68,69,70,71,76,77,78,79,82,83,84,85,88,89,90,91,96,97,98,99,104,105,106,107,112,113,114,115,120,121,122,123,126,127,128,129,132,133,134,135,140,141,142,143,148,149,150,151,156,157,158,159,164,165,166,167,170,171,172,173 --rank-by slot --report-bindings"
elif [ "$NPPNS" == "120" ]
then
            mppflags="--bind-to cpulist:ordered --cpu-set 0,1,2,3,4,8,9,10,11,12,16,17,18,19,20,24,25,26,27,28,32,33,34,35,36,38,39,40,41,42,44,45,46,47,48,52,53,54,55,56,60,61,62,63,64,68,69,70,71,72,76,77,78,79,80,82,83,84,85,86,88,89,90,91,92,96,97,98,99,100,104,105,106,107,108,112,113,114,115,116,120,121,122,123,124,126,127,128,129,130,132,133,134,135,136,140,141,142,143,144,148,149,150,151,152,156,157,158,159,160,164,165,166,167,168,170,171,172,173,174 --rank-by slot --report-bindings"
elif [ "$NPPNS" == "144" ]
then
            mppflags="--bind-to cpulist:ordered --cpu-set 0,1,2,3,4,5,8,9,10,11,12,13,16,17,18,19,20,21,24,25,26,27,28,29,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,52,53,54,55,56,57,60,61,62,63,64,65,68,69,70,71,72,73,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,96,97,98,99,100,101,104,105,106,107,108,109,112,113,114,115,116,117,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,140,141,142,143,144,145,148,149,150,151,152,153,156,157,158,159,160,161,164,165,166,167,168,169,170,171,172,173,174,175 --rank-by slot --report-bindings"
elif [ "$NPPNS" == "176" ]
then
            mppflags="--bind-to cpulist:ordered --cpu-set 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175 --rank-by slot --report-bindings"
else
            echo "No defined setting for Core count: $NPPNS"
            mppflags="--report-bindings"
fi

cd \$PBS_O_WORKDIR
BOUTPUTDIR=GMX_${NNODES}_${NPPNS}_${NTHRDS}.\${PBS_JOBID}
mkdir \$BOUTPUTDIR
cd \$BOUTPUTDIR

#NNUMA=\$(lscpu | grep "NUMA node(s):" | awk -F ' ' '{print \$3}')
NNUMA=\$(lscpu | grep "Socket(s):" | awk -F ' ' '{print \$2}')
PPS=\$(($NPPNS / NNUMA))
if [ \$((PPS * NNUMA - $NPPNS)) -eq 0 ]; then
#        NUMA_OPT="ppr:\$PPS:numa:pe=${NTHRDS}"
       	NUMA_OPT="ppr:\$PPS:socket:pe=${NTHRDS}"
else
#        NUMA_OPT="numa:pe=${NTHRDS}"
       	NUMA_OPT="socket:pe=${NTHRDS}"
fi

echo NUMA_OPT: \$NUMA_OPT

cat \$PBS_NODEFILE | sort -u > hostlist

if [ \${OMP_NUM_THREADS} -eq 1 -a "${SKU_TYPE}" == "hbv4" ]; then
    export mpi_options="-machinefile \$PBS_NODEFILE -np $NTASKS \$mppflags --rank-by slot 
    -x UCX_NET_DEVICES=mlx5_ib0:1 -x UCX_IB_PKEY -x UCX_UNIFIED_MODE=y 
    -x LD_LIBRARY_PATH -x PATH -x PWD" 
else
    export mpi_options="-machinefile \$PBS_NODEFILE -np $NTASKS --bind-to core --map-by \$NUMA_OPT --rank-by slot 
    -x OMP_NUM_THREADS=$NTHRDS -x OMP_PLACES=cores -x OMP_PROC_BIND=close 
    -x UCX_NET_DEVICES=mlx5_ib0:1 -x UCX_IB_PKEY -x UCX_UNIFIED_MODE=y 
    -x LD_LIBRARY_PATH -x PATH -x PWD --display-map --report-bindings" 
fi

echo mpi_options: \$mpi_options

ln -s ${INPUTDIR}/bench${BENCHMARK}.tpr .

mpirun \$mpi_options \${GMX_MPI} mdrun -s bench${BENCHMARK}.tpr -ntomp $NTHRDS -dlb yes -noconfout  -pin on -cpt -1 -resethway -g output.log

###grep "Performance:" output.log | awk -F ' ' '{print $2}'

exit 0

EOF

for ((i=1 ; i<= $REPS ; i++)); do
## Submit job
#if test "${JOBID}" = "INITIALIZE"; then
  JOBID=$(qsub ${BENCHMARK}_benchmark_${NNODES}_${NPPNS}_${NTHRDS}.pbs)
#else
#  JOBID=$(qsub -W depend=afterany:$JOBID lihfx_benchmark_${NNODES}_${NPPNS}_${NTHRDS}.pbs)
#fi
echo "GMX Benchmarking: $BENCHMARK, tasks ${NTASKS} nodes ${NNODES} ppn ${NPPNS}, threads $NTHRDS, PBS job id ${JOBID}" >> ${basedir}/${LOGFILE}
done

done
done
done

cd ${basedir}

