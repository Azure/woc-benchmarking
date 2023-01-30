# A quick start guide to benchmarking T5x Model with JAX on Azure
Below are the steps one needs to take to run T5X training benchmarks using NVIDIA JAX container on NDm A100 v4-series on Azure.

## Prerequisites
1. Make sure to have **sufficient quota** for the NDm A100 v4 virtual machine to run the intended scale of your benchmarks.
2. Setup a [NVIDIA NGC account](https://ngc.nvidia.com/signin)

## Set up Azure CycleCloud cluster and environment
Deploy and set up a CycleCloud cluster (Azure CycleCloud 8.2 and slurm 2.6.5) of [NDm A100 v4 virtual machines](https://learn.microsoft.com/en-us/azure/virtual-machines/ndm-a100-v4-series) by following the steps highligted in the [README.MD](https://github.com/JonShelley/CycleCloudProjects/tree/master/cc-slurm-ngc-ub2004) doc. Once the CC cluster is deployed, continue following the steps below:
### Set up your cluster environment 
1. SSH into the scheduler machine and open the docker daemon configuration file 
    ```
    sudo vi /etc/docker/daemon.json
    ```
2. Update the docker root directory in the daemon configuration file by adding the line below after the first curly bracket. Once that is done, save the file
    ```
    "data-root": "/shared/docker",
    ```
3. Generate your NGC API key by following the [generate API key guide](https://docs.nvidia.com/ngc/ngc-overview/index.html#generating-api-key)
4. Copy the generated API key and replace the <GENERATED API KEY> with the generated API key. Run the command below to update the enroot details - 
    ```
    mkdir -p ~/.config/enroot
    echo "machine nvcr.io login \$oauthtoken password <GENERATED API KEY>" > ~/.config/enroot/.credentials
    ```

## Downloading the datasets
1. Make a scratch space working directory in the /shared file system 
    ```
    mkdir –p /shared/JAX/
    ``` 
2. Set the JAX_SCRATCH_SPACE environment variable to the scratch path that was created above. 
    ```
    export JAX_SCRATCH_SPACE=/shared/JAX
    ```
3. Create a data and model sub directory for the T5x model and dataset 
    ```
    mkdir $JAX_SCRATCH_SPACE/data_dir && mkdir $JAX_SCRATCH_SPACE/model_dir
    ```
4. Clone the workload optimized compute benchmarking repository and change directories to the JAX directory. This has the run scripts for the benchmarks
    ```
    cd $JAX_SCRATCH_SPACE
    git clone https://github.com/Azure/woc-benchmarking.git
    cd woc-benchmarking/apps/AI/JAX/scripts
    ```
5. Download the dataset by running a small model on a single-node. This will download the dataset to $JAX_SCRATCH_SPACE/data_dir, and subsequent run will reuse it.
    ```
    DOWNLOAD=1 T5_SIZE=small BS_PER_GPU=8 sbatch -N 1 run.slurm
    ```
***Note:This benchmark performance is benefitted by faster storage. We recommend that you have the data on a performant parallel file system or copy the data to each node on the raid0 nvme disk found at /mnt/resource_nvme.***

6. Copy the data to the /mnt/resource_nvme disk of the compute nodes in the cluster.
    ```
    clush -w <compute_nodes> cp -r $JAX_SCRATCH_SPACE /mnt/resource_nvme
    ```
## Running the Benchmarks
1. Set the JAX_SCRATCH_SPACE environment variable to the data path. 
    ```
    export JAX_SCRATCH_SPACE=/mnt/resource_nvme/JAX
    ```
2. Run the experiments. Adjust the number of nodes(N) accordingly:
    ```
    #For small models, we recommend you use 256 for BS_PER_GPU
    T5_SIZE=small BS_PER_GPU=256 sbatch -N 1 run.slurm

    #For large models, we recommend you use 32 for BS_PER_GPU
    T5_SIZE=large BS_PER_GPU=32  sbatch -N 1 run.slurm

    #For XL models, we recommend you use 8 for BS_PER_GPU
    T5_SIZE=xl BS_PER_GPU=8 sbatch -N 1 run.slurm
    ``` 
## Reviewing the results
1. Once your slurm job is completed, you can find the results by opening the output log file and search for **[200]**.
2. In the summary line, extract the **timing/seqs_per_second** value. That is the throughput number we report for the benchmarks.

