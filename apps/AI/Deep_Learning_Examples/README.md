# A quick start guide to benchmarking AI models in Azure: NVIDIA Deep Learning Examples on the NC-series
Below are the steps one needs to take to run benchmarking models using NVIDIA Deep Learning Examples benchmarks on NC A100 v4, NCsv3, and NCas_t4_v3 series on Azure.

## Deploy the environment
Deploy and set up a NC A100 v4 virtual machine on Azure portal by [following this script](https://techcommunity.microsoft.com/t5/azure-high-performance-computing/getting-started-with-the-nc-a100-v4-series/ba-p/3568843)
Or, deploy and set up a NCsv3/NCas_T4_v3 virtual machine on Azure portal by [following this script](https://techcommunity.microsoft.com/t5/azure-high-performance-computing/getting-started-with-the-ncsv3-series-and-ncas-t4-v3-series/ba-p/3568874#M148)

SSH into the machine and run the following commands.

## Set the path
Set the path to the mounted disk depending on the deployed VM with the pre-requisites.
NC A100 v4 series
    ```
    Data_path=/mnt/resource_nvme
    ```
NCsv3-series and the NCas_T4_v3 series
    ```
    Data_path=/mnt/resource_mdisk
    ```

# BERT
## Clone the repository
    ```
    mkdir $Data_path/BERT && cd $Data_path/BERT
    git clone https://github.com/NVIDIA/DeepLearningExamples.git
    cd $Data_path/BERT/DeepLearningExamples/PyTorch/LanguageModeling/BERT
    ```
## Set up the environment
1. Get the checkpoints for both models SQUAD and Glue:
    ```
    wget --content-disposition https://api.ngc.nvidia.com/v2/models/nvidia/dle/bert_pyt_ckpt_large_ft_sst2_amp/versions/21.11.0/zip%20-O%20bert_pyt_ckpt_large_ft_sst2_amp_21.11.0.zip
    wget --content-disposition https://api.ngc.nvidia.com/v2/models/nvidia/bert_pyt_ckpt_large_qa_squad11_amp/versions/19.09.0/zip%20-O%20bert_pyt_ckpt_large_qa_squad11_amp_19.09.0.zip
    ```
2. Unzip and place the checkpoints in the checkpoints folder
    ```
    unzip bert_pyt_ckpt_large_qa_squad11_amp_19.09.0.zip
    unzip bert_pyt_ckpt_large_ft_sst2_amp_21.11.0.zip
    mv pytorch_model.bin checkpoints/ && mv bert_large_qa.pt checkpoints/
    ```
3. Build and launch docker in two steps:
    ```
    bash scripts/docker/build.sh
    bash scripts/docker/launch.sh
    ```
4. Finally, obtain the datasets with the following line inside the container. This step is the bottleneck of the benchmark because it requires downloading 19.6 GB of data. It takes approximately two hours.
    ```
    /workspace/bert/data/create_datasets_from_start.sh
    ```
## Run inference benchmark GLUE
This benchmark takes less than one minute per batch size. First, start by opening and modifying the configuration file.
    ```
    vi scripts/run_glue.sh
    ```
Modify the following parameters
    ```
    init_checkpoint=${1:-"/workspace/bert/checkpoints/pytorch_model.bin"}
    num_gpu=${7:-"1"}
    batch_size=${8:-"1"}
    precision=${14:-"fp32"}
    mode=${16:-"eval"}
    ```
Run the benchmark
    ```
    bash scripts/run_glue.sh
    ```
Then, modify only the batch size by incrementations and run the previous command again to obtain more data points.

## Run inference benchmark SQuAD
Reproduce the previous steps for SQUAD. This benchmark takes approximately five minutes per batch size. First, start by opening and modifying the configuration file.
    ```
    vi scripts/run_squad.sh
    ```
Modify the following parameters
    ```
    init_checkpoint=${1:-"/workspace/bert/checkpoints/bert_large_qa.pt"}
    num_gpu=${7:-"1"}
    batch_size=${3:-"1"}
    precision=${6:-"fp32"}
    mode=${12:-"eval"}
    ```
Run the benchmark
    ```
    bash scripts/run_squad.sh
    ```
Finally, modify only the batch size by incrementations and run the previous command again to obtain more data points.
## Run training benchmarks
Reproduce the previous steps for both SQUAD and Glue after changing the mode to run training benchmarks.
    ```
    mode=${12:-"train"}
    ```

# ResNet
## Clone the repository
    ```
    mkdir $Data_path/resnet && cd $Data_path/resnet
    git clone https://github.com/NVIDIA/DeepLearningExamples
    cd $Data_path/resnet/DeepLearningExamples/PyTorch/Classification/
    ```
Download ImageNet Data [available online](https://image-net.org/download-images)

## Set up the environment
Starting with training
    ```
    mkdir train && mv ILSVRC2012_img_train.tar train/ && cd train
    tar -xvf ILSVRC2012_img_train.tar && rm -f ILSVRC2012_img_train.tar
    find . -name "*.tar" | while read NAME ; do mkdir -p "${NAME%.tar}"; tar -xvf "${NAME}" -C "${NAME%.tar}"; rm -f "${NAME}"; done
    cd ..
    ```
Continuing with inference:
    ```
    mkdir val && mv ILSVRC2012_img_val.tar val/ && cd val && tar -xvf ILSVRC2012_img_val.tar
    wget -qO- https://raw.githubusercontent.com/soumith/imagenetloader.torch/master/valprep.sh | bash
    cd ../ConvNets
    ```
Create and launch the container
    ```
    docker build . -t nvidia_resnet50
    nvidia-docker run --rm -it -v $Data_path/resnet/DeepLearningExamples:/imagenet --ipc=host nvidia_resnet50
    ```
## Run the benchmark
Get the pretrained weights from NGC:
    ```
    wget --content-disposition https://api.ngc.nvidia.com/v2/models/nvidia/resnet50_pyt_amp/versions/20.06.0/zip -O resnet50_pyt_am...
    unzip resnet50_pyt_amp_20.06.0.zip
    ```
Finally, for the benchmarks start by updating the config file for the desired batch size
    ```
    vi configs.yml
    ```
Run inference benchmark
    ```
    python ./launch.py --model resnet50 --precision TF32 --mode benchmark_inference --platform DGXA100 /imagenet/PyTorch/Classification/ --raport-file benchmark.json --epochs 1 --prof 100
    ```
Run training benchmark
    ```
    python ./launch.py --model resnet50 --precision TF32 --mode benchmark_training --platform DGXA100 /imagenet/PyTorch/Classification/ --raport-file benchmark.json --epochs 1 --prof 100
    ```
Read the summary to get the values you need. Modify the config file before running the benchmark again to get data points for different batch size

# SSD
## Clone the repository
    ```
    sudo chmod 1777 /mnt
    mkdir $Data_path/SSD && cd $Data_path/SSD
    git clone https://github.com/NVIDIA/DeepLearningExamples
    ```
## Set up the environment
Get the datasets
    ```
    mkdir $Data_path/coco && cd $Data_path/coco
    sudo apt install unzip
    wget http://images.cocodataset.org/zips/train2017.zip && unzip train2017.zip 
    wget http://images.cocodataset.org/zips/val2017.zip && unzip val2017.zip 
    wget http://images.cocodataset.org/annotations/annotations_trainval2017.zip && unzip annotations_trainval2017.zip
    ```
Build and launch docker with this three-step launch
    ```
    cd $Data_path/SSD/DeepLearningExamples/PyTorch/Detection/SSD
    docker build . -t nvidia_ssd
    docker run --rm -it --gpus=all --ipc=host -v $Data_path:/coco nvidia_ssd
    ```
## Run the benchmarks
Inference benchmark takes less than one minute per batch size: modify only the variable eval-batch-size and run again to obtain more data points
    ```
    python main.py --data /coco/coco --eval-batch-size 1 --mode benchmark-inference
    ```
Then, one can run training benchmark with the following command. Again, modify the variable batch-size and run again to obtain more data points
    ```
    python main.py --data /coco/coco --batch-size 2 --mode benchmark-training
    ```
