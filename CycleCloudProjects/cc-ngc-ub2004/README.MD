# Setup CycleCloud to run NGC containers using Slurm, Pyxis, and Enroot

## Requirements
* CycleCloud 8.2+

## Deploy the cyclecloud server and ssh into the VM
_Note: Please follow [Cycle Cloud Quickstart guide](https://docs.microsoft.com/en-us/azure/cyclecloud/qs-install-marketplace?view=cyclecloud-8) with the below recommendations_

__Recommendations:__
- Create a new resource group (i.e cc-manager) and then select your newly created resource group and create your cyclecloud server.
- Select Azure CycleCloud 8.2(or higher) and click create.
    - Fill out the requested information and deploy your CycleCloud server.
- Server size: D4s_v4 (Recommended).
- Create a uniquely named storage account (i.e. cc-storage-name) in your newly created resource group.
- Create a [Azure Virtual Private Network](https://microsoft-my.sharepoint.com/:w:/p/aimeegarcia/EdDJ0PxKehBMjKfFYcXEYDcBWAMRBNg39xYLEkiVVo9IhQ?isSPOFile=1&clickparams=eyJBcHBOYW1lIjoiVGVhbXMtRGVza3RvcCIsIkFwcFZlcnNpb24iOiIyNy8yMjA5MDQwMDcxMiIsIkhhc0ZlZGVyYXRlZFVzZXIiOmZhbHNlfQ%3D%3D) in your newly created resource group.  

Once deployed:
 - Go to the newly created Cycle Cloud server and record the ip address. 
 - Login to the Cycle Cloud server in your Web Browser and do the initial setup of your Cycle Cloud server. 
    - This step requires adding information about Tenant ID, App ID and App secret. 
    - Here is a presentation that shows how to get that information on Azure. [GTC_CC_SLURM_NGC](https://microsoft.sharepoint.com/teams/HPCAIBenchmarking/_layouts/15/stream.aspx?id=%2Fteams%2FHPCAIBenchmarking%2FShared%20Documents%2FConferences%2FGTC%2DCC%2DSlurm%2DNGC%2Emp4)
    - _Note:_ There could be an expiration secret on the App secret. The set up may not work as expected once that App secret expires.  
 
 
Next, ssh into your cyclecloud server (i.e. ssh azureuser@<cc-srv-ip>) and follow the steps below:

### Download and setup the project
Initialize Cycle Cloud
```shell
cyclecloud initialize
```
To use slurm 2.6.5, perform the following steps. _Note_: This is a temporary step
 ```shell
 vi Slurm-2.6.5.txt
 ```
Insert the following into the file Slurm-2.6.5.txt
```shell
AdType = "Cloud.Project"
Version = "2.6.5"
ProjectType = "scheduler"
Url = "https://github.com/Azure/cyclecloud-slurm/releases/2.6.5"
AutoUpgrade = false
Name= "slurm"
```
```shell
sudo cp Slurm-2.6.5.txt /opt/cycle_server/config/data/
```
  
Before running the below code block change \<azure-storage\> to the correct locker name. To see the available lockers run
```shell
cyclecloud locker list 
```
Run the following block of commands to upload the NGC project files to CC azure storage. 
```shell
sudo yum install -y git
cd ~/
git clone https://github.com/sdoomra/CycleCloudProjects.git
cd CycleCloudProjects/cc-slurm-ngc-ub2004
./download_dependancies.sh #downloads dependencies into the default/files folder
cyclecloud project upload "<azure-storage>"  # Change this to your locker name
cd templates
cyclecloud import_template cc-slurm-ngc -f ./cc-slurm-ngc-pmix.txt -c slurm
```

_Note:_ At this point you are ready to deploy your cyclecloud cluster

## Deploy your cyclecloud cluster
Open a web browser and go to your cyclecloud server (https://cc-srv-ip)

Once you have logged in to your cyclecloud server:
_Note:_ If this is your first time logging in you will need to fill out some information before you can proceed

Use the following link to learn more about creating a cluster (https://docs.microsoft.com/en-us/azure/cyclecloud/how-to/create-cluster?view=cyclecloud-8)

_Note: Only tested with Ubuntu-HPC 20.04 marketplace image_
 
 Tips: 
 - When creating a new cluster, in the _Schedulers_ section, select cc-slurm-ngc
 - Make sure you enter the name of the cluster in **small letters**. Camel-case and Capital letters in the cluster name do not work as expected (Known issue) 
 - In the "Required Settings" tab
   - Uncheck "autoscale" if you don't want VMs to automatically shut off when nodes sit idle 
  - Update value from Max HPC Cores to the desired # of VMs * # of cores/VM
 - In the "Advanced Settings" tab
   - Uncheck Job Accountinh if there is no slurmdb set up.
   - If you select Job Accounting, you will need Slurm DBD Url and user. 
   - Set the scheduler OS to use a custom image
     - microsoft-dsvm:ubuntu-hpc:2004:latest
   - Set the last HPC OS to use a custom image
     - microsoft-dsvm:ubuntu-hpc:2004:latest
   - If you plan to use the HTC partitions, I would recommned that you use the same OS image as the others
   
 At this point, you can start your cluster from the Azure Cyclecloud server on the webbrowser. 

 ## Testing out the deployment
 _Note: If you don't want to deal with auto scaling when testing, add "SuspendExcParts=ndmv4,ndv4" to /etc/slurm/slurm.conf and restart slurm (sudo systemctl restart slurmctld) once the scheduler has been deployed_
    
 Once the Scheduler has been provisioned, ssh into the scheduler and follow the instructions below
```shell
sudo mkdir -p /shared/data
sudo chmod 1777 /shared/data
cd /shared/data
git clone https://github.com/sdoomra/azure.git
```

At this point you are ready to deploy the VMs. Click on the Nodes tab and select the hpc template and you should see the bottom table fill up with VM names. Highlight the number that you would like to deploy, click on Actions -> Start
    
Once the VMs are deployed you will need to ssh in the scheduler and then you can explore the options below.

First we need to configure the GPUs to get the best performance. To do this run the following on every compute VM using clush command
```shell
clush -w <compute_nodes> sudo /shared/data/azure/benchmarking/NDv4/cc-slurm-ngc/util_scripts/configure_gpus.sh
```

If you'd like to use docker containers on compute nodes, the below command helps in setting up initial docker environment and makes sure that docker is installed correctly on the compute nodes.  
```shell
clush -w <compute_nodes> sudo docker run --runtime=nvidia --rm nvidia/cuda:11.2.0-runtime-ubuntu20.04 nvidia-smi
```
    
At this point the system should be ready to run some quick tests to verify that the system is working as expected
 - [HPL](https://github.com/sdoomra/azure/tree/master/benchmarking/NDv4/cc-slurm-ngc/hpl)
 - [NCCL - All Reduce](https://github.com/sdoomra/azure/tree/master/benchmarking/NDv4/cc-slurm-ngc/nccl)
 - [Utility scripts](https://github.com/sdoomra/azure/tree/master/benchmarking/NDv4/cc-slurm-ngc/util_scripts)
