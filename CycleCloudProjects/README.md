# HPC-reframe

This contains cyclecloud projects that are developed by the Azure AI/HPC benchmarking team.

Below are instructions on how to provision a cluster supporting H-Series VMs in CycleCloud using the cc-base template in this directory to implement the automated Reframe validation tests.

REQUIREMENTS

•	Supported OS:  Ubuntu20, AlmaLinux8

•	CycleCloud 8.3, using cyclecloud-slurm-2.7.1 with Slurm v22.11

•	Cyclecloud Reframe template (cc-base, in this directory)

GETTING STARTED

Create a CycleCloud VM instance on the Azure portal using the [CycleCloud instructions](https://learn.microsoft.com/en-us/azure/cyclecloud/qs-install-marketplace?view=cyclecloud-8).
SSH into the [VM instance](https://learn.microsoft.com/en-us/azure/cyclecloud/qs-install-marketplace?view=cyclecloud-8#log-into-the-cyclecloud-application-server) on a linux machine and pull the cc-base template from github.

   $> git clone https://github.com/Azure/woc-benchmarking

Start a new cycle cloud project:
   $> cyclecloud initialize
   
   $> cyclecloud project init cc-base

   $> cd woc-benchmarking/CycleCloudProjects/cc-base/templates
   
   $> cyclecloud import_template cc-base -f ./cc-slurm-base.txt -c slurm

The newly uploaded cc-slurm template should be available when creating a new CycleCloud cluster in the web browser.

Included in the cc-base template are several tests for validating HW, SW, single-node health, multi-node communications, and performance. These are executed on all compute VMs before they are added to the slurm cluster and ready for use.
