#!/bin/bash

export NODE_LIST=(120)
export PPN_LIST=(144)
export THRD_LIST=(1)
export compiler=gcc-9.2.1
export mpi_library=hpcx #openmpi-4.0.5
export BENCHMARK="conus2.5km" #"conus12km"
export REPS=3
export SKU_TYPE=hbv4
export APPNS=${APPNS:-/share/home/hpcuser/woc-benchmarking/apps/hpc/utils/azure_process_pinning.sh}  #PATH to azure_process_pinning.sh script

export INPUTDIR="/share/home/hpcuser/wrf/v4_bench_conus2.5km/"  #directory where the initial conditions are residing
#################################################################################################################
basedir=$(pwd)
nlist=($(pbsnodes -avS | grep 'free\|job' | awk -F ' ' '{print $1}'))
VMINFO=$(ssh ${nlist[0]} sudo curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2018-10-01")
export clustertype=$(echo $VMINFO |sed -e 's/"//g' |sed -e 's/^.*vmSize://g' |cut -d"," -f1)
clustertype=${clustertype#*_}

module purge
module load $compiler
module load mpi/$mpi_library

export WRFROOT="" #set the wrf root, see the build instructions
export NETCDF_C=$WRFROOT/netcdf
export NETCDF=$WRFROOT/netcdf
export HDF5=$WRFROOT/hdf5
export WRFIO_NCD_LARGE_FILE_SUPPORT=1
export WRFROOT=$WRFROOT/WRF-4.2.2/

WRF_PATH=$(command -v wrf.exe)
echo "wrf path:" ${WRFROOT}
echo "mpi library: $(command -v mpirun)"

JOBID=INITIALIZE

LOGFILE=log_${clustertype}_${BENCHMARK}_bench_${compiler}_${mpi_library}.txt
# File to keep a record of the jobids of the benchmarking runs
touch ${LOGFILE}

OUTPUTDIR=${basedir}/run_${clustertype}/${compiler}/${mpi_library}/$BENCHMARK/
echo $OUTPUTDIR
mkdir -p $OUTPUTDIR
cp stats.awk $OUTPUTDIR
cd $OUTPUTDIR
echo "PWD: $PWD"

for NNODES in ${NODE_LIST[@]}; do
for NPPNS in ${PPN_LIST[@]}; do
for NTHRDS in ${THRD_LIST[@]}; do

NTASKS=$((NNODES * NPPNS))
NCPUS=$((NPPNS * NTHRDS))

cat <<EOF > ${BENCHMARK}_benchmark_${NNODES}_${NPPNS}_${NTHRDS}.pbs	
#!/bin/bash
#PBS -N wrf-${BENCHMARK}-${NNODES}_${NPPNS}_${NTHRDS}
#PBS -l walltime=02:08:00
#PBS -l select=$NNODES:ncpus=$NCPUS:mpiprocs=$NPPNS:ompthreads=$NTHRDS
#PBS -l place=scatter:exclhost
#PBS -j oe
###PBS -q debug

ulimit -s unlimited
ulimit -l unlimited
ulimit -a


export NETCDF_C=$WRFROOT/netcdf
export NETCDF=$WRFROOT/netcdf
export HDF5=$WRFROOT/hdf5
export WRFIO_NCD_LARGE_FILE_SUPPORT=1
export LD_LIBRARY_PATH=$WRFROOT/netcdf/lib:$WRFROOT/hdf5/lib:${LD_LIBRARY_PATH}
export WRFROOT=$WRFROOT/WRF-4.2.2/

module purge
module load $compiler
module load mpi/$mpi_library
module list

export OMP_NUM_THREADS=$NTHRDS

WRF_PATH=\${WRFROOT}
echo "wrf path:" \${WRFROOT}
echo "mpi library: \$(command -v mpirun)"

source $APPNS $NPPNS $NTHRDS
export mppflags="--bind-to cpulist:ordered --cpu-set \$AZURE_PROCESSOR_LIST --rank-by slot --report-bindings"

cd \$PBS_O_WORKDIR
BOUTPUTDIR=WRF_${NNODES}_${NPPNS}_${NTHRDS}.\${PBS_JOBID}
mkdir \$BOUTPUTDIR
cd \$BOUTPUTDIR

cat \$PBS_NODEFILE | sort -u > hostlist

export mpi_options="-machinefile \$PBS_NODEFILE -np $NTASKS \$mppflags -x UCX_TLS=dc_x,sm,self -x LD_LIBRARY_PATH -x PATH"

echo mpi_options: \$mpi_options

sudo yum install pssh -y
pssh -p 10 -i -t 0 -h ./hostlist "ulimit -s unlimited" 

ln -s ${WRFROOT}/run/* .
ln -sf ${INPUTDIR}/namelist.input .
ln -sf ${INPUTDIR}/wrfrst* .
ln -sf ${INPUTDIR}/*dat .
ln -sf ${INPUTDIR}/*_d01 .

mpirun \$mpi_options ./wrf.exe 

#to find the wall time
cp ../stats.awk .
grep 'Timing for main' rsl.error.0000* | tail -149 | awk '{print \$9}' | awk -f stats.awk >  outputfile.log
tst=\$(grep "time_step    " namelist.input | awk -F ' ' '{printf("%5f\n", \$3)}')
echo "time_step:         \$tst" >> outputfile.log

rm wrf*d01*

exit 0

EOF

for ((i=1 ; i<= $REPS ; i++)); do
## Submit job
#if test "${JOBID}" = "INITIALIZE"; then
  JOBID=$(qsub ${BENCHMARK}_benchmark_${NNODES}_${NPPNS}_${NTHRDS}.pbs)
#else
#  JOBID=$(qsub -W depend=afterany:$JOBID lihfx_benchmark_${NNODES}_${NPPNS}_${NTHRDS}.pbs)
#fi
echo "WRF Benchmarking: $BENCHMARK, tasks ${NTASKS} nodes ${NNODES} ppn ${NPPNS}, threads $NTHRDS, PBS job id ${JOBID}" >> ${basedir}/${LOGFILE}
done

done
done
done

cd ${basedir}

