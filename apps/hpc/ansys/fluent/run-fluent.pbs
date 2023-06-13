#!/bin/bash

#PBS -l select=4:ncpus=120:mpiprocs=96:mem=420gb
#PBS -l place=excl
#PBS -N fluent
#PBS -j oe

# parameters that can be overridden
APP_INSTALL_DIR=${APP_INSTALL_DIR:-/apps}
DATA_DIR=${DATA_DIR:-/data/fluent}
MODEL=${MODEL:-f1_racecar_140m}
OMPI=${OMPI:-hpcx}
FLUENT_VERSION=${FLUENT_VERSION:-v222}
LIC_SRV=${LIC_SRV:-10.1.0.5}
APPNS=${APPNS:-/share/home/hpcuser/woc-benchmarking/apps/hpc/utils/azure_process_pinning.sh}  #PATH to azure_process_pinning.sh script

export ANSYSLMD_LICENSE_FILE=1055@${LIC_SRV}
export ANSYSLI_SERVERS=2325@${LIC_SRV}
export FLUENT_HOSTNAME=`hostname`
export APPLICATION=fluent
export VERSION=$FLUENT_VERSION

cd $PBS_O_WORKDIR/

NODES=$(sort -u < $PBS_NODEFILE | wc -l)
PPN=$(uniq -c < $PBS_NODEFILE | tail -n1 | awk '{print $1}')
CORES=$(wc -l <$PBS_NODEFILE)
DATE=`date +"%Y%m%d_%H%M%S"`

source /etc/profile
source /opt/hpcx*/hpcx-init.sh
hpcx_load

export PATH=$APP_INSTALL_DIR/ansys_inc/${FLUENT_VERSION}/fluent/bin:$PATH
export FLUENT_PATH=$APP_INSTALL_DIR/ansys_inc/${FLUENT_VERSION}/fluent
export OPENMPI_ROOT=$HPCX_MPI_DIR

mkdir ${MODEL}-${NODES}N-${PPN}PPN.${PBS_JOBID}
cd ${MODEL}-${NODES}N-${PPN}PPN.${PBS_JOBID}

source $APPNS $PPN $NTHREADS
export mppflags="--bind-to cpulist:ordered --cpu-set $AZURE_PROCESSOR_LIST --rank-by slot --report-bindings"

if [ "$CORES" -gt 2816 ]; then
    ans_lic_type=anshpc_pack
else
    ans_lic_type=anshpc
fi

aff=off
num_cpus="$(cat /proc/cpuinfo |grep ^processor | wc -l)"

cat $PBS_NODEFILE | uniq -c > hosts
sudo yum install pssh -y
pssh -p 4 -t 0 -i -h hosts "echo -1 | sudo tee /proc/sys/kernel/perf_event_paranoid"
pssh -p 4 -t 0 -i -h hosts "sudo yum -y install libXt libnsl libnsl2 glibc freetype motif.x86_64 mesa-libGLU mesa-libGLU-devel libnl3 libnl3-devel"
pssh -p 4 -t 0 -i -h hosts "sudo free && sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches && sudo swapoff -a && sudo swapon -a"
pssh -p 4 -t 0 -i -h hosts "sudo /sbin/sysctl vm.drop_caches=3"

cat $PBS_NODEFILE | uniq -c | awk '{ print $2 ":" $1 }' > hosts

echo "License Type: $ans_lic_type"

numa_domains="$(numactl -H |grep available|cut -d' ' -f2)"
ppr=$(( ($PPN + $numa_domains - 1) / $numa_domains ))

echo PPN at runtime is $PPN

fluentbench.pl \
    -path=$FLUENT_PATH \
    -ssh \
    -verbose \
    -norm \
    -platform=amd \
    -nosyslog \
    $MODEL \
    -t$CORES \
    -pinfiniband \
    -mpi=$OMPI \
    -mpiopt="$mppflags --report-bindings -x UCX_TLS=dc_x,sm,self -x LD_LIBRARY_PATH -x PATH -x PWD -x MKL_DEBUG_CPU_TYPE=5" \
    -cnf=hosts \
    -affinity=$aff \
    -feature_parallel_preferred=$ans_lic_type

