# CradleCFD Benchmarking
Scripts for automatic build of CradleCFD on Azure HPC VMs, and its benchmarking on PBS & Slurm clusters

## Getting Started

### Dependencies

* None 
* Relies on Intel-MPI 2019 shipped with the CradleCFD

### Building CradleCFD
To buil CradleCFD v2023, simply run 

```
tar zxvf scflowsol2023ii_net.tgz -C /aps/
cd /aps/Dscflowsol2023
./inst
```

To build CradleCFD 2022 (Tested and verified on Azure)

```
sh CradleCFD_2022.1_Lnx64_Setup.bin
```
and follow the instructions in the command line. For the license path, enter the address to the license server, e.g. XXXXX@hosted-license.mscsoftware.com, and the set MSC license (HPC) as the default. Select Intel MPI 2019 update 11 for the installation. 

CradleCFD v2022 needs to be updated with a patch. SO after the installation, run
```
sh CradleCFD_2022.1_Lnx64_Setup_Patch3_Sep2022.bin
```
and follow the instructions in the command line. 


To run a simulation, modify and submit the job scripts for your respective job scheduller. For PBS

```
qsub run-scFlow.pbs
```
and for Slurm
```
sbatch run-scFlow.slurm
```

## Output

The solver elapsed time (CPU Time) can be obtained by running 
```
grep "CPU TIME=" scFlow.log 
```
inside the job directory. 



