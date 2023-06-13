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

To adjust the optimizations, change the ARCH variable to the respective architecture on which simulations is going to run, e.g. znver3, znver2, znver1 for HBv3, HBv2 and HB respectively. The script is to be modified for Intel based architectures, since they mostly support avx512 instructions.

To run a 4 VM test on a PBS cluster, modify the paths in "namd.pbs" scripts and submit the script

```
qsub namd.pbs
```

### Note:
Currently tested only on HBv2 and HBv3 VMs.

### Input files
To obtain a reasonable performance on H series VMs, adjust the number of iterations to a large number, e.g. 50000. See the input parameters in this [blog post](https://techcommunity.microsoft.com/t5/azure-high-performance-computing/accelerating-namd-on-azure-hb-series-vms/ba-p/3775531). 




