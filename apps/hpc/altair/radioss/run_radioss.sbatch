#!/bin/bash

#SBATCH -N 1
#SBATCH --tasks-per-node=120
#SBATCH --cpus-per-task=1
#SBATCH --job-name=Radioss
#SBATCH --output=Radioss-%j.out
#SBATCH --exclusive

# parameters that can be overridden
APP_INSTALL_DIR=${APP_INSTALL_DIR:-/shared/apps}
DATA_DIR=${DATA_DIR:-/shared/data/altair}
SCRATCH_DIR=${SCRATCH_DIR:-/mnt/resource_nvme/scratch}
CASE=${CASE:-T10M}
RADIOSS_VERSION=${RADIOSS_VERSION:-2022.1}
#export ALTAIR_LICENSE_PATH=6200@$LIC_SRV

export ALTAIR_HOME=$APP_INSTALL_DIR/altair/$RADIOSS_VERSION/altair
echo "ALTAIR HOME: $ALTAIR_HOME"
INSTALL_DIR=$APP_INSTALL_DIR/altair/$RADIOSS_VERSION/altair/hwsolvers
RADIOSS_CASE=$DATA_DIR/${CASE}

NODES=$SLURM_NNODES
NMPI=$SLURM_NTASKS
OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK:-1}
CORES=$(( $SLURM_NTASKS * $OMP_NUM_THREADS ))
NMPI=${USE_NMPI:-$NMPI}
echo "------------------------------------------------------"
echo "Job ID           : " $SLURM_JOBID
echo "Job name         : " $SLURM_JOBNAME
echo "Queue            : " $SLURM_JOB_PARTITION
echo "Submission dir   : " $SLURM_SUBMIT_DIR
echo "NODES            = " $NODES
echo "NCPUS            = " $CORES
echo "OMP_NUM_THREADS  = " $OMP_NUM_THREADS
echo "Number of MPI    = " $NMPI
echo "------------------------------------------------------"

## RADIOSS Options
# Define HW_ROOT (location HyperWorks is installed)
HW_BASE=$INSTALL_DIR
HW_ROOT=${HW_BASE}/radioss/bin/linux64
LD_LIBRARY_PATH=$HW_ROOT:$LD_LIBRARY_PATH
export RAD_CFG_PATH=$INSTALL_DIR/radioss/cfg
echo "RAD CFG PATH: $RAD_CFG_PATH"

module load mpi/impi-2021

# Gather the pinning info
VM_SKU=$(curl --connect-timeout 10 -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2018-04-02" | jq '.compute.vmSize')
VM_SKU="${VM_SKU%\"}"
VM_SKU="${VM_SKU#\"}"
export VM_SKU=$VM_SKU
echo "VM SKU: $VM_SKU"
source ../../../../utils/azure_process_pinning.sh $SLURM_TASKS_PER_NODE
VM_SKU="${VM_SKU/Standard_/}"
#env | grep -i azure
#env | grep -i slurm


starter=$HW_ROOT/s_2022.1_linux64
engine=$HW_ROOT/e_2022.1_linux64_impi
user=$USER

## Data Options
ROOTNAME=TAURUS_A05_FFB50
d00=${ROOTNAME}_0000.rad
d01=${ROOTNAME}_0001.rad


# JOB Options
wkdir=$SCRATCH_DIR/projects/${USER}/radioss-$SLURM_JOBID
mkdir -p $wkdir
cd $wkdir
ln -s $DATA_DIR/radioss/T10M/* .
unlink includes
cp -a $DATA_DIR/radioss/T10M/includes .
echo Local execution under: `pwd`

# Setup RADFLEX
export RADFLEX_PATH=${ALTAIR_HOME}/hwsolvers/common/bin/linux64
cp ${RADFLEX_PATH}/radflex_2022_linux64 ./radflex_2018_linux64
export LD_LIBRARY_PATH=${HW_ROOT}/:$RADFLEX_PATH:$LD_LIBRARY_PATH

# Create hostfile
echo "------------------------------------------------------"
cmd_line='chomb; print "$_"'
cmd_line="$cmd_line x${SLURM_NTASKS_PER_NODE}"
if [[ -z $SLURM_JOB_NODELIST ]]; then
    if [[ ! -f "hostfile_$SLURM_JOBID.txt" ]]; then
        echo "Something is not right in this environment"
    fi
else
    scontrol show hostname $SLURM_JOB_NODELIST | perl -ne "$cmd_line" > hostfile_$SLURM_JOBID.txt
fi
#cat hostfile_$SLURM_JOBID.txt
echo "------------------------------------------------------"

# run RADIOSS starter
echo "------------------------------------------------------"
echo "RADIOSS Starter"
echo "------------------------------------------------------"
ulimit -s unlimited
$starter -np $NMPI -i $d00

pwd
# run RADIOSS engine
# this part is needed if using local ssd for the wkdir
if [[ $wkdir == *"/mnt/resource_nvme/"* && $SLURM_NNODES > 1  ]]; then 
    echo "Work Dir: $wkdir"
    echo "Nodes: $SLURM_NNODES"
    n=1
    for i in `cat hostfile_$SLURM_JOBID.txt | sort -n | uniq `
    do
        ssh $i test -f $wkdir/$d01
        a=$?
        if [ $a -ne 0 ]; then
            ssh $i mkdir $wkdir
            scp $d01 $i:$wkdir/$d01
        fi
        if [ $n -lt 10 ]; then
            scp ${ROOTNAME}_0000_000$n.rst $i:$wkdir/${ROOTNAME}_0000_000$n.rst;
        elif [ $n -lt 100 ]; then
            scp ${ROOTNAME}_0000_00$n.rst $i:$wkdir/${ROOTNAME}_0000_00$n.rst;
        elif [ $n -lt 1000 ]; then
            scp ${ROOTNAME}_0000_0$n.rst $i:$wkdir/${ROOTNAME}_0000_0$n.rst;
        else
            scp ${ROOTNAME}_0000_$n.rst $i:$wkdir/${ROOTNAME}_0000_$n.rst;
        fi
        n=$(($n+1))
    done
fi



echo "------------------------------------------------------"
echo "RADIOSS Engine"
echo "------------------------------------------------------"

#AZURE_IMPI_OPTIONS="-genv I_MPI_MPIRUN_CLEANUP 1 -genv I_MPI_PIN_DOMAIN auto -genv OMP_NUM_THREADS $OMP_NUM_THREADS -genv I_MPI_ADJUST_BCAST 1 -genv I_MPI_ADJUST_REDUCE 2 -genv KMP_AFFINITY verbose,scatter -genv KMP_STACKSIZE 400m -genv I_MPI_DEBUG 3 -genv I_MPI_FABRICS shm:ofa"

ADDITIONAL_MPI_OPTIONS="-genv I_MPI_MPIRUN_CLEANUP 1 -genv OMP_NUM_THREADS $OMP_NUM_THREADS -genv I_MPI_ADJUST_BCAST 1 -genv I_MPI_ADJUST_REDUCE 2 -genv KMP_AFFINITY verbose,scatter -genv KMP_STACKSIZE 400m"

echo "$MPI_BIN/mpirun -r ssh -machinefile hostfile_$SLURM_JOBID.txt $AZURE_IMPI_OPTIONS $ADDITIONAL_MPI_OPTIONS -genv LD_LIBRARY_PATH $MPILIB:$LD_LIBRARY_PATH -genv PATH $MPIBIN:$PATH -n $NMPI $engine  -i $d01"

$MPI_BIN/mpirun \
	-r ssh \
	-machinefile hostfile_$SLURM_JOBID.txt \
	-genv LD_LIBRARY_PATH $MPI_LIB:$LD_LIBRARY_PATH \
	$AZURE_IMPI_OPTIONS \
	$ADDITIONAL_MPI_OPTIONS \
	-genv PATH $MPI_BIN:$PATH \
	-n $NMPI \
	$engine  -i $d01


cp ${ROOTNAME}_0000.out $SLURM_SUBMIT_DIR/${ROOTNAME}-${VM_SKU}-${NODES}n-${CORES}c-${OMP_NUM_THREADS}tpc-MPI-OpenMP-pernode-${SLURM_JOBID}_0000.out
cp ${ROOTNAME}_0001.out $SLURM_SUBMIT_DIR/${ROOTNAME}-${VM_SKU}-${NODES}n-${CORES}c-${OMP_NUM_THREADS}tpc-MPI-OpenMP-pernode-${SLURM_JOBID}_0001.out

exit 0
#clean
#n=1
#for i in `cat hostfile_$SLURM_JOBID.txt`
#do
#   ssh $i rm -rf $wkdir
#done
