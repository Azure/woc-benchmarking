#!/bin/bash
#SBATCH --gpus-per-node=8
#SBATCH --exclusive
#SBATCH -p ndmv4

export XLA_FLAGS='--xla_gpu_simplify_all_fp_conversions --xla_gpu_all_reduce_combine_threshold_bytes=136314880'

export UCX_IB_ENABLE_CUDA_AFFINITY=n
export UCX_IB_PCI_RELAXED_ORDERING=on
export UCX_TLS=rc 
export UCX_NET_DEVICES=mlx5_ib0:1,mlx5_ib1:1,mlx5_ib2:1,mlx5_ib3:1,mlx5_ib4:1,mlx5_ib5:1,mlx5_ib6:1,mlx5_ib7:1
export CUDA_DEVICE_ORDER=PCI_BUS_ID
export NCCL_IB_PCI_RELAXED_ORDERING=1
export NCCL_SOCKET_IFNAME=eth0
export NCCL_TOPO_FILE=/microsoft/ndv4-topo.xml
export PYTHONPATH=/t5x/

# Start from TF2 container
export CONTAINERS="--container-image=nvcr.io/nvidia/tensorflow:22.11-tf2-py3 --container-mounts=$JAX_SCRATCH_SPACE:/workdir,/opt/microsoft/:/microsoft --container-name=nvidia_$RANDOM"

# Download and install JAX + T5X
srun $CONTAINERS --ntasks-per-node 1 bash -c 'pip install jax[cuda]==0.4.1 -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.html && git clone https://github.com/google-research/t5x.git /t5x && cd /t5x && git checkout ef48f3 && pip install -e . && pip install -r ./t5x/contrib/gpu/scripts_gpu/pile_requirements.txt'

# Run training
export TRAIN="python3 -u /t5x/t5x/train.py --gin_file=/t5x/t5x/contrib/gpu/t5/t5_1_1/examples/${T5_SIZE}_pile_pretrain.gin --gin.MODEL_DIR=\"/workdir/model_dir/$(date --iso-8601=seconds)/\" --gin.network.T5Config.dtype=\"bfloat16\" --gin.TRAIN_STEPS=200 --tfds_data_dir=/workdir/data_dir/ --gin.train/utils.DatasetConfig.batch_size=$(($BS_PER_GPU*8*$SLURM_JOB_NUM_NODES)) --gin.CheckpointConfig.save=None --gin.train.stats_period=100 --gin.MIXTURE_OR_TASK_NAME=\"wmt_t2t_ende_v003\""

if [ -z ${DOWNLOAD+x} ]
then
        srun $CONTAINERS -l --ntasks-per-node 8 $TRAIN --multiprocess_gpu
else
        # When downloading the dataset, we should run on 1 node with 1 process
        srun $CONTAINERS -l --ntasks-per-node 1 $TRAIN
fi


























