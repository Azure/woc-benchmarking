# A quick start guide to benchmarking AI models in Azure: MLPerf Inference v2.1 on Multi-Instance GPU (MIG)
In this document, one will find the steps to run the MLPerf Inference v2.1 benchmarks for BERT, ResNet-50, RNN-T, and 3D-UNet on one of seven slices of NVIDIA-powered NC A100 v4-series Tensor Core GPUs with Multi-Instance GPU (MIG).
Learn more about [MIG on Azure](https://techcommunity.microsoft.com/t5/azure-high-performance-computing/tackling-ai-inference-workloads-on-azure-s-nc-a100-v4-virtual/ba-p/3725991) and [Azure’s submission to MLPerf Inference v2.1](https://techcommunity.microsoft.com/t5/azure-high-performance-computing/a-quick-start-guide-to-benchmarking-ai-models-in-azure-mlperf/ba-p/3607414).

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
Do not create the MIG instance manually, the command “make prebuild” will do it. One change is needed prior to starting the container. Remove “--gpu all” in " --gpu all -e NVIDIA_MIG_CONFIG_DEVICES=all" on line 754 of the file Makefile.
Enable MIG on all the GPUs (rebooting the VM may be needed), prebuild the container on all the instances, and get the rest of the datasets from inside the container.

4. Get the rest of the datasets from inside the container:
    ```
    sudo nvidia-smi -mig 1
    make prebuild MIG_CONF=ALL
    make download_data BENCHMARKS="resnet50 bert rnnt 3d-unet"
    make download_model BENCHMARKS="resnet50 bert rnnt 3d-unet"
    make preprocess_data BENCHMARKS="resnet50 bert rnnt 3d-unet"
    ```
5. One needs to register the system and generate the configuration files before running the benchmarks.
    ```
    python3 -m scripts.custom_systems.add_custom_system

    Give a name and accept to generate the customed configuration files.
    ```
Finally, adjust the values of the configuration files located in configs/[benchmark]/[scenario]/custom.py by using the values suggested by NVIDIA under “A100_PCIe_80GB_MIG_1x1g10gb” located in /mnt/resource_nvme/inference_results_v2.1/closed/NVIDIA/configs/[benchmark]/[scenario]/__init__.py This will allow you to run the benchmarks on a single slice of MIG.

You can finally build the container:
```
cd /mnt/resource_nvme/inference_results_v2.1/closed/Azure
make build
```

## Run the benchmark
Finally, run the benchmark with the make run command, an example is given below. The value is only correct if the result is “VALID”, modify the value in the config files if the result is “INVALID”.
```
make run RUN_ARGS="--benchmarks=bert --scenarios=offline --config_ver=default,high_accuracy,triton,high_accuracy_triton"
```

