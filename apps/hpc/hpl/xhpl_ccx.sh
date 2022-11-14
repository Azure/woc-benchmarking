#! /usr/bin/env bash
#
# Bind memory to node $1 and four child threads to CPUs specified in $2
#
# Kernel parallelization is performed at the 2nd innermost loop (IC)
export LD_LIBRARY_PATH=$HPCX_MPI_DIR/lib:$LD_LIBRARY_PATH
export OMP_NUM_THREADS=$3
export GOMP_CPU_AFFINITY="$2"
export OMP_PROC_BIND=TRUE
# BLIS_JC_NT=1 (No outer loop parallelization):
export BLIS_JC_NT=1
# BLIS_IC_NT= #cores/ccx (# of 2nd level threads �~@~S one per core in the shared L3 cache domain):
export BLIS_IC_NT=$OMP_NUM_THREADS
# BLIS_JR_NT=1 (No 4th level threads):
export BLIS_JR_NT=1
# BLIS_IR_NT=1 (No 5th level threads):
export BLIS_IR_NT=1
numactl --membind=$1 ./xhpl
