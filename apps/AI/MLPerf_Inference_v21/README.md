# A quick start guide to benchmarking AI models in Azure: MLPerf Inference v2.1
Below are the steps one needs to take to run benchmarking models using MLPerf Inference v2.1 containers on NC A100 v4-series on Azure.

## Deploy the environment
Deploy and set up a NC A100 v4 virtual machine on Azure portal by [following this script](https://techcommunity.microsoft.com/t5/azure-high-performance-computing/getting-started-with-the-nc-a100-v4-series/ba-p/3568843)

SSH into the machine and run the following commands.

## Set up the environment
1. Once your machine is deployed and configured, create a folder for the scripts and get the scripts from MLPerf Inference v2.1 repository:
    ```
    cd /mnt/resource_nvme
    git clone https://github.com/mlcommons/inference_results_v2.1.git
    cd inference_results_v2.1/closed/Azure
    ```
2. Create folders for the data and get the ResNet50 data:
    ```
    export MLPERF_SCRATCH_PATH=/mnt/resource_nvme/scratch
    mkdir -p $MLPERF_SCRATCH_PATH
    mkdir $MLPERF_SCRATCH_PATH/data $MLPERF_SCRATCH_PATH/models $MLPERF_SCRATCH_PATH/preprocessed_data
    cd $MLPERF_SCRATCH_PATH/data && mkdir imagenet && cd imagenet
    ```
3. In this imagenet folder download ImageNet Data [available online](https://image-net.org/download-images) and go back to the script.
    ```
    cd /mnt/resource_nvme/inference_results_v2.1/closed/Azure
    ```
4. Get the rest of the datasets from inside the container:
    ```
    make prebuild
    make download_data BENCHMARKS="resnet50 bert rnnt 3d-unet"
    make download_model BENCHMARKS="resnet50 bert rnnt 3d-unet"
    make preprocess_data BENCHMARKS="resnet50 bert rnnt 3d-unet"
    make build
    ```
## Run the benchmark
Finally, run the benchmark with the make run command, an example is given below. The value is only correct if the result is “VALID”, modify the value in the config files if the result is “INVALID”.
```
make run RUN_ARGS="--benchmarks=bert --scenarios=offline --config_ver=default,high_accuracy,triton,high_accuracy_triton"
```

