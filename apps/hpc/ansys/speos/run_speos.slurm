#!/bin/bash
#SBATCH -o "speos-%j.out"
#SBATCH -e "speos-%j.err"
#SBATCH -J speos-bm
#SBATCH -N 4
# spread the tasks evenly among the nodes
#SBATCH --ntasks-per-node=120
#SBATCH --exclusive
#SBATCH -t 00:30:00
##SBATCH --partition=hbv3

CASE_DIR=${CASE_DIR:-/shared/data/ansys/speos/FlaconInverse2.sv5}
CASE_NAME=${CASE_NAME:-FlaconInverse2.sv5}

# Load the INTEL redistribuables
BASE_SPEOS_DIR=/shared/apps/ansys_inc/v222/OpticalProducts/SPEOS_HPC
BASE_MPI_DIR=/shared/apps/ansys_inc/v222/commonfiles/MPI/Intel/2018.3.222

export ANSYSLMD_LICENSE_FILE=1055@10.1.0.5
export TMPDIR="/mnt"
export PATH=${BASE_MPI_DIR}/linx64/bin:$PATH
export LD_LIBRARY_PATH=${BASE_MPI_DIR}/linx64/lib:$LD_LIBRARY_PATH
export UCX_TLS=tcp,sm,self



###############################
# SPEOSHPC command line options
###############################

cd $CASE_DIR
ls -altr


#unset SLURM_CPU_BIND SLURM_TASKS_PER_NODE SLURM_NNODES SLURM_NTASKS_PER_NODE SLURM_JOB_NODELIST SLURM_NTASKS SLURM_TOPOLOGY_ADDR SLURM_WORKING_CLUSTER SLURM_STEP_NODELIST SLURM_SRUN_COMM_PORT SLURM_NODE_ALIASES SLURM_TOPOLOGY_ADDR_PATTERN SLURM_CPUS_ON_NODE SLURM_JOB_NUM_NODES SLURM_PTY_WIN_ROW SLURM_CPU_BIND_LIST  SLURM_PTY_WIN_COL SLURM_NPROCS SLURM_SUBMIT_HOST SLURM_STEP_LAUNCHER_PORT SLURM_PTY_PORT SLURM_GTIDS SLURM_CPU_BIND_TYPE SLURM_STEP_NUM_TASKS SLURM_STEP_NUM_NODES SLURM_LOCALID SLURM_STEP_ID SLURM_NODEID SLURM_TASK_PID SLURM_PRIO_PROCESS SLURM_CPU_BIND_VERBOSE SLURM_STEPID SLURM_SRUN_COMM_HOST SLURM_PROCID SLURM_JOB_GID SLURMD_NODENAME SLURM_LAUNCH_NODE_IPADDR SLURM_STEP_TASKS_PER_NODE SLURM_CLUSTER_NAME SLURM_NODELIST SLURM_UMASK SLURM_JOB_CPUS_PER_NODE  SLURM_JOB_NAME SLURM_CONF SLURM_JOB_QOS SLURM_JOB_UID SLURM_JOB_PARTITION SLURM_JOB_USER SLURM_JOBID SLURM_JOB_ID

#mpirun -n 4 -ppn 1 -machinefile=hostfile.txt ${BASE_SPEOS_DIR}/SPEOSHPC.x -speos "${CASE_DIR}/${CASE_NAME}" -threads 64 -mtime 1 -mpi IntelMPI -gpu
mpirun ${BASE_SPEOS_DIR}/SPEOSHPC.x -speos "${CASE_DIR}/${CASE_NAME}" -threads 64 -mtime 1 -mpi IntelMPI -gpu
