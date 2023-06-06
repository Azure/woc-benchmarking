# NAMD Benchmarking
Instructions for building NAMD on Azure HPC VMs and running simulations under PBS and SLURM workload schedullers

## Getting Started

### Dependencies

* gcc compilers
* HPC-X MPI library (or any other MPI Library available)

### Building NAMD
To buil NAMD, simply run 

```
sh namd_build_script.sh 
```

On prompt, enter your gitlab credentials to clone the NAMD repository from the gitlab. 

To run a set of single VM test on a PBS cluster, modify the line '#PBS -J 1-64' and adjust it to the number of available VMs on the cluster, then submit the script

```
qsub array_hpl_run_scr.pbs
```

### Note:
Currently tested only on HBv2, HBv3 and HBv4 VMs.




