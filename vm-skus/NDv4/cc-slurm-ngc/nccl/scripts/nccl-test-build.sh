#!/bin/bash

HPCX_DIR=`ls /opt | grep -i hpcx`
CONT="nvcr.io#nvidia/pytorch:21.09-py3"
MOUNT="/shared/data/azure/benchmarking/NDv4/cc-slurm-ngc/nccl:/nccl,/opt/${HPCX_DIR}:/opt/hpcx"

export OMPI_MCA_pml=ucx
export OMPI_MCA_btl=^openib

srun --ntasks=$SLURM_JOB_NUM_NODES \
    --container-image "${CONT}" \
    --container-name=nccl \
    --container-mounts="${MOUNT}" \
    --ntasks-per-node=1 \
    bash -c 'cd /nccl && git clone https://github.com/NVIDIA/nccl-tests.git && source /opt/hpcx/hpcx-init.sh && hpcx_load && cd nccl-tests && make MPI=1'
