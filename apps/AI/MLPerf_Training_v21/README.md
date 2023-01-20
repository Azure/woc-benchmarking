# A quick start guide to benchmarking AI models in Azure: MLPerf Training v2.1
Below are the steps one needs to take to run benchmarking models using MLPerf Training v2.1 containers on NC A100 v4-series and NDm A100 v4-series on Azure.

## Deploy the environment
NC A100 v4-series (single node): Deploy and set up a NC A100 v4 virtual machine on Azure portal by [following this script](https://techcommunity.microsoft.com/t5/azure-high-performance-computing/getting-started-with-the-nc-a100-v4-series/ba-p/3568843)
NDm A100 v4-series (multi node): Deploy and set up a CycleCloud cluster (Azure CycleCloud 8.2 and slurm 2.6.5) of NDm A100 v4 virtual machines by [following this script](https://github.com/Azure/woc-benchmarking/tree/main/CycleCloudProjects/cc-slurm-ngc-ub2004)

SSH into the virtual machine, or into the scheduler, and run the following commands.

## Set up the environment
1. First, we need to export the path to the directory where we will perform the benchmarks.
The path for NC A100 v4-series (single node) is:
    ```
    export PATH_DIR=/mnt/resource_nvme
    ```
The path for NDm A100 v4-series (multi node) is:
    ```
    export PATH_DIR=/shared/mlcommons
    ```
2. Then, we can clone the repository in the directory we created previously.
    ```
    cd $PATH_DIR
    git clone https://github.com/mlcommons/training_results_v2.1.git
    ```
## Get the dataset for Mask R-CNN
The Mask R-CNN script operates on COCO, a large-scale object detection, segmentation, and captioning dataset. To download and verify the dataset, use the following commands.    
    ```
    cd $PATH_DIR/training_results_v2.1/Azure/benchmarks/maskrcnn/implementations/ND96amsr_A100_v4/maskrcnn/dataset_scripts
    ./download_dataset.sh
    ./verify_dataset.sh
    ```
This should return PASSED.

Then, to extract the dataset, use:
    ```
    DATASET_DIR=$PATH_DIR/mlperf/data/maskrcnn_data/
    mkdir -p $DATASET_DIR
    DATASET_DIR=$DATASET_DIR ./extract_dataset.sh
    ```
Mask R-CNN uses pre-trained ResNet50 as a backbone. To download and verify the RN50 weights use:
    ```
    DATASET_DIR=$DATASET_DIR ./download_weights.sh
    ```
Make sure DATASET_DIR is writable.

To speed up loading of coco annotations during training, the annotations can be pickled since unpickling is faster than loading a json. Repeat the command below for all the annotations files in the json format to convert it to the pickle format.
    ```
    cd $PATH_DIR/training_results_v2.1/Azure/benchmarks/maskrcnn/implementations/NC96ads_A100_v4
    docker build -t mlperftrainingv21/maskrcnn:latest .
    docker run --gpus all -v $DATASET_DIR:/data -it mlperftrainingv21/maskrcnn:latest
    cd /data
    mkdir /data/pkl_coco
    cd /workspace/object_detection/maskrcnn/dataset_scripts
    python pickle_coco_annotations.py --root /data --ann_file /data/coco2017/annotations/<FILENAME>.json --pickle_output_file /data/pkl_coco/<FILENAME>.json.pickled
    ```
Exit the container to run the benchmarks.
## Run the Mask R-CNN benchmark
The steps to run the benchmark consist of building the docker container, sourcing the configuration file, and starting the benchmark. The path and run commands differ depending on the virtual machines you are testing.
For NC A100 v4-series:
    ```
    cd $PATH_DIR/training_results_v2.1/Azure/benchmarks/maskrcnn/implementations/NC96ads_A100_v4
    source ./config_DGXA100_NC.sh
    CONT= mlperftrainingv21/maskrcnn:latest DATADIR=$PATH_DIR/mlperf/data/maskrcnn_data/ ./run_with_docker.sh
    ```
For NDm A100 v4-series:
    ```
    cd $PATH_DIR/training_results_v2.1/Azure/benchmarks/maskrcnn/implementations/ND96amsr_A100_v4
    enroot import -o maskrcnn.sqsh "dockerd://mlperftrainingv21/maskrcnn:latest"
    source ./config_DGXA100.sh
    CONT=./maskrcnn.sqsh DATADIR=$PATH_DIR/mlperf/data/maskrcnn_data/ sbatch -N $DGXNNODES -p ndmv4 --exclusive --gpus-per-node=${DGXNGPU} ./run.sub
    ```
The above steps can be replicated for the other MLPerf Training v2.1 benchmarks or cluster sizes. One would have to adapt to the right configuration files and steps to preprocess the data.
