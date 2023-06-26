#!/bin/bash

export NODE_LIST=(1 2 4 8 16)
export PPN_LIST=(96 120 144 176)
export THRD_LIST=(1)
export compiler=gcc-13.1.0
export mpi_library=hpcx-v2.15
export BENCHMARK="H2O-DFT-LS"
export REPS=3
export APPNS=${APPNS:-/share/home/hpcuser/woc-benchmarking/apps/hpc/utils/azure_process_pinning.sh}  #PATH to azure_process_pinning.sh script
export SKU_TYPE=hbv4

export CP2K_SPEC="cp2k@2023.1 /eqw6svak4in7"
export INPUTDIR=/share/home/hpcuser/cp2k/input
#################################################################################################################
basedir=$(pwd)
VMINFO=$(sudo curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2018-10-01")
export clustertype=$(echo $VMINFO |sed -e 's/"//g' |sed -e 's/^.*vmSize://g' |cut -d"," -f1 |cut -d"_" -f2)

yes | sudo yum install python3
module use /apps/gcc/gcc-b/module
module load $compiler
source /share/home/hpcuser/cp2k/spack/share/spack/setup-env.sh
module load mpi/$mpi_library
spack load $CP2K_SPEC

CP2K_PATH=$(command -v cp2k.psmp)
echo "cp2k path:" $CP2K_PATH
echo "mpi library: $(command -v mpirun)"

JOBID=INITIALIZE

LOGFILE=log_${clustertype}_${BENCHMARK}_bench_${compiler}_${mpi_library}.txt
# File to keep a record of the jobids of the benchmarking runs
touch ${LOGFILE}

OUTPUTDIR=${basedir}/run_${clustertype}/${compiler}/${mpi_library}/$BENCHMARK/
mkdir -p $OUTPUTDIR
cp $INPUTDIR/cp2k-H2O-DFT-LS-initial-files.tar.gz $OUTPUTDIR
cd $OUTPUTDIR

for NNODES in ${NODE_LIST[@]}; do
for NPPNS in ${PPN_LIST[@]}; do
for NTHRDS in ${THRD_LIST[@]}; do

NTASKS=$((NNODES * NPPNS))
NCPUS=$((NPPNS * NTHRDS))

cat <<EOF > ${BENCHMARK}_benchmark_${NNODES}_${NPPNS}_${NTHRDS}.pbs	
#!/bin/bash
#PBS -N cp2k-${BENCHMARK}-${NNODES}_${NPPNS}_${NTHRDS}
#PBS -l walltime=01:00:00
#PBS -l select=$NNODES:ncpus=$NCPUS:mpiprocs=$NPPNS:ompthreads=$NTHRDS
#PBS -l place=scatter:exclhost
#PBS -j oe

ulimit -s unlimited
ulimit -l unlimited
ulimit -a

module use /apps/gcc/gcc-b/module
module load $compiler
module list

yes | sudo yum install python3
source /share/home/hpcuser/cp2k/spack/share/spack/setup-env.sh
module load mpi/$mpi_library
spack load $CP2K_SPEC
#module load mpi/$mpi_library

CP2K_PATH=\$(command -v cp2k.psmp)
echo "cp2k path:" \$CP2K_PATH
echo "mpi library: \$(command -v mpirun)"

cd \$PBS_O_WORKDIR
BOUTPUTDIR=CP2KH2O_${NNODES}_${NPPNS}_${NTHRDS}.\${PBS_JOBID}
mkdir \$BOUTPUTDIR
cd \$BOUTPUTDIR

source $APPNS $NPPNS $NTHRDS
export mppflags="--bind-to cpulist:ordered --cpu-set \$AZURE_PROCESSOR_LIST --rank-by slot --report-bindings"

cat \$PBS_NODEFILE | sort -u > hostlist
export OMPI_MCA_coll=^hcoll
export mpi_options="-machinefile \$PBS_NODEFILE -np $NTASKS \$mppflags --rank-by slot -mca coll ^hcoll -x OMP_NUM_THREADS=$NTHRDS -x LD_LIBRARY_PATH -x PATH"

echo mpi_options: \$mpi_options
export OMP_NUM_THREADS=$NTHRDS

cp ../cp2k-H2O-DFT-LS-initial-files.tar.gz .
tar -xzvf cp2k-H2O-DFT-LS-initial-files.tar.gz

mpirun \$mpi_options $CP2K_PATH -i H2O-dft-ls.NREP4.inp -o outputfile.log

#to find the wall time
grep "CP2K    " outputfile.log | awk -F ' ' '{print \$6}' > exec_time.log

exit 0

EOF

for ((i=1 ; i<= $REPS ; i++)); do
## Submit job
#if test "${JOBID}" = "INITIALIZE"; then
  JOBID=$(qsub ${BENCHMARK}_benchmark_${NNODES}_${NPPNS}_${NTHRDS}.pbs)
#else
#  JOBID=$(qsub -W depend=afterany:$JOBID lihfx_benchmark_${NNODES}_${NPPNS}_${NTHRDS}.pbs)
#fi
echo "CP2K Benchmarking: $BENCHMARK, tasks ${NTASKS} nodes ${NNODES} ppn ${NPPNS}, threads $NTHRDS, PBS job id ${JOBID}" >> ${basedir}/${LOGFILE}
done

done
done
done

cd ${basedir}

