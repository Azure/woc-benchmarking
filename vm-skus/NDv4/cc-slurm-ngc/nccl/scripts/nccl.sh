#!/bin/bash
  
export UCX_IB_ENABLE_CUDA_AFFINITY=n \
       UCX_IB_PCI_RELAXED_ORDERING=on \
       UCX_TLS=rc \
       UCX_NET_DEVICES=mlx5_ib0:1,mlx5_ib1:1,mlx5_ib2:1,mlx5_ib3:1,mlx5_ib4:1,mlx5_ib5:1,mlx5_ib6:1,mlx5_ib7:1 \
       CUDA_DEVICE_ORDER=PCI_BUS_ID \
       NCCL_IB_PCI_RELAXED_ORDERING=1 \
       NCCL_SOCKET_IFNAME=eth0 \
       NCCL_TOPO_FILE=/microsoft/ndv4-topo.xml
#       NCCL_DEBUG=INFO \

HPCX_DIR=`ls /opt | grep -i hpcx`

CONT="nvcr.io#nvidia/pytorch:21.09-py3"
MOUNT="/opt/microsoft:/microsoft,/shared/data/azure/benchmarking/NDv4/cc-slurm-ngc/nccl:/nccl,/opt/${HPCX_DIR}:/opt/hpcx"

export OMPI_MCA_pml=ucx
export OMPI_MCA_btl=^openib

env | grep "SLURMD_NODENAME="
env | grep "SLURM_NODELIST="

srun --ntasks=$SLURM_JOB_NUM_NODES \
    --container-image "${CONT}" \
    --container-name=nccl \
    --container-mounts="${MOUNT}" \
    --ntasks-per-node=1 \
    bash -c "apt update && apt-get install -y infiniband-diags "

srun \
    --gpus-per-node=8 \
    --ntasks-per-node=8 \
    --container-name=nccl \
    --container-mounts "${MOUNT}" \
    bash -c 'source /opt/hpcx/hpcx-init.sh && hpcx_load && /nccl/nccl-tests/build/all_reduce_perf -b8 -f 2 -g 1 -e 8G'
