# HPL Benchmarking
Scripts for automatic build of HPL on Azure HPC VMs, and single VM benchmarking on a PBS cluster

## Getting Started

### Dependencies

* gcc compilers
* HPC-X MPI library (or any other MPI Library available)

### Building HPL
To buil HPL, simply run 

```
sh hpl_build_script.sh 
```

To run a set of single VM test on a PBS cluster, modify the line '#PBS -J 1-64' and adjust it to the number of available VMs on the cluster, then submit the script

```
qsub array_hpl_run_scr.pbs
```

### Note:
Currently tested only on HBv2, HBv3 and HBv4 VMs.

## Output

A summary of the results is printed in
```
hpl-test-results.log
```

To run single VM tests, simply run 
```
hpl_run_scr_hbvN.sh $PWD
```

where N denotes 2, 3 or 4, representing the HBv2, HBv3 or HBv4 respectively.

This script is still under deveopment, and is meant for testing the health of the VMs. The HPL results will be slighly lower than optimal, to maintain a reasonable runtime. To achieve optimal results, the problem size and dimensions need to be larger. As a results, the runtimes will be significantly longer for the optimal tests. 



