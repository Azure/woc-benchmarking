# A quick start guide to benchmarking LLM models in Azure: NVIDIA NeMo Megatron
Below are the steps one needs to take to run GPT-3 architechture models using NeMo Megatron container on NDm A100 v4-series on Azure.

## Deploy the environment
1. Make sure to have **sufficient quota** for the NDm A100 v4 virtual machine to run the intended scale of your benchmarks.
2. Deploy and set up a CycleCloud cluster (Azure CycleCloud 8.2 and slurm 2.6.5) of NDm A100 v4 virtual machines by [following this script](https://github.com/Azure/woc-benchmarking/tree/main/CycleCloudProjects/cc-slurm-ngc-ub2004)
3. Add storage while deploying: Under Network Attached Storage on the CycleCloud portal, select NFS type “buildin” and make the size 4TB.

Start the scheduler first and then the compute nodes.

## Set up the environment
1. SSH into the scheduler machine and set the number of compute nodes in your cluster before starting the setup:
    ```
    export NN=<number of nodes>
    ```
2. Make a directory for the credentials before downloading the container. This directory must be accessible from all the nodes so it should be under the /shared directory:
    ```
    sudo chmod 1777 /shared
    mkdir -p /shared/tmp
    ```
3. Open the docker daemon configuration file
    ```
    sudo vi /etc/docker/daemon.json
    ```
4. Update the docker root directory in the daemon configuration file by adding the line below after the first curly bracket. Once that is done, save the file
    ```
    "data-root": "/shared/docker",
    ```
5. Generate your NGC API key by following the [generate API key guide](https://docs.nvidia.com/ngc/ngc-overview/index.html#generating-api-key)
6. Copy the generated API key and replace the <GENERATED API KEY> with the generated API key. Run the command below to update the enroot details - 
    ```
    echo "machine nvcr.io login \$oauthtoken password <GENERATED API KEY>" > ~/.config/enroot/.credentials
    ```
7. Copy the file with your credentials to all compute nodes:
    ```
    srun -p ndmv4 -N $NN bash -c "mkdir -p ~/.config/enroot/ && cp /shared/tmp/.credentials ~/.config/enroot/"
    ```

## Get the NeMo Megatron container:
1. Make a scratch space working directory in the /shared file system 
    ```
    mkdir –p /shared/ngc_scripts
    ``` 
2. Set the driver capacities before starting the setup: 
    ```
    export NVIDIA_DRIVER_CAPABILITIES=compute,utility
    ```
3. Pull the NeMo-Megatron Training container and extract the scripts to be used for training: 
    ```
    srun -p ndmv4 -N 1 --container-mounts=/shared/ngc_scripts:/workspace/mount_dir --container-image=nvcr.io/ea-bignlp/bignlp-training:22.06-hotfix.01-py3 bash -c "cp -r /opt/bignlp/bignlp-scripts /opt/bignlp/bignlp-hp-tool /workspace/mount_dir/"
    ```
## Install the requirements and dependencies:
Update the requirements on the scheduler:
    ```
    cd /shared/ngc_scripts/bignlp-scripts
    pip3 install -r requirements.txt
    pip3 install tensorboard
    ```
## Test the cluster:
Before cluster validation (which includes NCCL testing and DCGM Diagnostics), we need to modify a few scripts to point to the correct versions of software stacks (like HPCx and PyTorch), as well as add important flags (like number of GPUs per node):
    ```
    cd /shared/ngc_scripts/bignlp-scripts/csp/azure
    sed -i 's/hpcx-v2.9.0-gcc-MLNX_OFED_LINUX-5.4-1.0.3.0-ubuntu18.04-x86_64/hpcx-v2.9.0-gcc-MLNX_OFED_LINUX-5.4-1.0.3.0-ubuntu20.04-x86_64/g' nccl.sh
    sed -i '21,29d' nccl.sh
    sed -i 's/pytorch:21.09-py3/pytorch:22.06-py3/g' build-nccl-tests.sh
    sed -i 's/hpcx-v2.9.0-gcc-MLNX_OFED_LINUX-5.4-1.0.3.0-ubuntu18.04-x86_64/hpcx-v2.9.0-gcc-MLNX_OFED_LINUX-5.4-1.0.3.0-ubuntu20.04-x86_64/g' build-nccl-tests.sh
    sed -i 's/-w $NODES/-w $NODES --gpus-per-node 8/g' cluster_validation.sh
    sed -i 's/--parsable/--parsable --gpus-per-node 8/g' cluster_validation.sh
    sed -i 's/bash -c/--gpus-per-node 8 bash -c/g' dcgmi_diag.sh    
    ```
Generate the topology file and copy it to all compute nodes:
    ```
    mkdir /shared/topo
    sbatch -p ndmv4 -N 1 -o /shared/topo/ndv4-topo.xml gentopo.sh
    srun -p ndmv4 -N $NN bash -c "sudo mkdir -p /opt/microsoft && sudo cp /shared/topo/ndv4-topo.xml /opt/microsoft/"
    ```
Modify line 143 of the cluster_validation.sh file to specify the partition.
    ```
    cd /shared/ngc_scripts/bignlp-scripts/csp/azure
    vi cluster_validation.sh
    ```
line 143: 
    ```
    sbatch -p ndmv4 -N 1 -W build-nccl-tests.sh > /dev/null 2> /dev/null
    ```
Run the tests. It is expected that the DCGM runs for approximately 30 minutes and the NCCL test will take an extra 15 minutes for the first run. The NCCL test will not run if the DCGM test fails, but you can start it by adding the tag --nccl at the end of the command line.
    ```
    cd /shared/ngc_scripts/bignlp-scripts/csp/azure
    bash cluster_validation.sh --nodes=$NN --nodelist=<NAME_OF_YOUR_NODES> --partition=ndmv4
    ```
## Get the gpt3 data for NeMo Megatron:
Modify the configuration files:
    ```
    vi /shared/ngc_scripts/bignlp-scripts/conf/cluster/bcm.yaml
    
    change partition: ndmv4
    ```
and:
    ```
    vi /shared/ngc_scripts/bignlp-scripts/conf/data_preparation/download_gpt3_pile.yaml

    change file_numbers: "0-1"
    ```
Change the following values in /shared/ngc_scripts/bignlp-scripts/conf/config.yaml:
    ```
    run_data_preparation: True
    run_training: False
    run_conversion: False
    run_finetuning: False
    run_evaluation: False

    bignlp_path: /shared/ngc_scripts/bignlp-scripts
    data_dir: /shared/data/NeMo

    container_mounts:
    - /opt/microsoft:/opt/microsoft

    env_vars:
    NCCL_TOPO_FILE: /opt/microsoft/ndv4-topo.xml
    UCX_IB_PCI_RELAXED_ORDERING: auto
    NCCL_IB_PCI_RELAXED_ORDERING: 2
    NCCL_IB_TIMEOUT: 22
    ```
Start downloading the data with the following command:
    ```
    cd /shared/ngc_scripts/bignlp-scripts

    HYDRA_FULL_ERROR=1 python3 main.py \
        training=gpt3/126m \
        training.run.name=data_preparation \
        training.run.time_limit="10:00:00" \
        training.trainer.num_nodes=$NN \
        training.trainer.max_steps=200 \
        training.trainer.log_every_n_steps=1 \
        training.exp_manager.resume_if_exists=False \
        training.model.micro_batch_size=4 \
        training.model.tensor_model_parallel_size=1 \
        training.model.pipeline_model_parallel_size=1 \
        training.model.activations_checkpoint_num_layers=0 
    ```
## Run NeMo Megatron:
Modify the number of shards and their weights in each yaml file under /shared/ngc_scripts/bignlp-scripts/conf/training/gpt3. You should have only two shards with a 0.5 weight each. The file should look as follows:
    ```
    - 0.5
    - ${data_dir}/my-gpt3_00_text_document
    - 0.5
    - ${data_dir}/my-gpt3_01_text_document
    ```
Switch from data preparation to training.
    ```
    vi /shared/ngc_scripts/bignlp-scripts/conf/cluster/bcm.yaml

    change run_data_preparation: False
           run_training: True
    ```
Use the following command to start training. The following arguments must be changed accordingly to the benchmark you want to run (model, name, number of nodes, MBS, TP and PP). This step is expected to take several hours.
    ```
    cd /shared/ngc_scripts/bignlp-scripts

    HYDRA_FULL_ERROR=1 python3 main.py \
        training=gpt3/126m \
        training.run.name=gpt3_126m-1n-tp1-pp1-mbs1 \
        training.run.time_limit="10:00:00" \
        training.trainer.num_nodes=$NN \
        training.trainer.max_steps=200 \
        training.trainer.log_every_n_steps=1 \
        training.exp_manager.resume_if_exists=False \
        training.model.micro_batch_size=4 \
        training.model.tensor_model_parallel_size=1 \
        training.model.pipeline_model_parallel_size=1 \
        training.model.activations_checkpoint_num_layers=0
    ```
## Get the results:
In a separate terminal, connect to your scheduler using the following ssh command:
    ```
    ssh -L 4444:localhost:4444 <USER NAME>@<IP ADDRESS>
    ```
Start TensorBoard and point to the results directory for NeMo-Megatron:
    ```
    tensorboard --logdir=/shared/ngc_scripts/bignlp-scripts/results --port=4444
    ```
Visualize your results using TensorBoard on your web browser.
    ```
    http://localhost:4444/
    ```
Under the train_step_timing window you can find the time it takes per global step. Calculating the average of a few steps, for example 149, 169 and 189, gives a good indication of the time per step once the steady state is reached.

