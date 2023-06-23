# COpenFOAM Benchmarking
Instructions for building OpenFOAM on Azure HBv4 VMs and running simulations under PBS and SLURM workload schedullers

## Getting Started

### Dependencies

* gcc 13.1.0
* HPC-X MPI library (or any other MPI Library available)
* Spack

### Building CP2K
To buil OpenFOAM using spack try 
```
spack install -j 144 openfoam@2006 %gcc@13.1.0 ^hpcx

```

For compiler optimization, we recommend `-O3 -march=znver4 -Ofast` in your spack build receipe. GCC 13.1.0 is necessary to implement these compile time optimizations for znver4 architecture. 

To run a set of benchmarks, adjust the input variables at the top of `cp2k_benchmarking.sh` script and run

```
./cp2k_benchmarking.sh
```

to obtain a summary of the results, adjust the input variables at the top of `summarize.sh` script and run
```
sh summarize.sh
```

### Note:
Currently tested on HB series VMs.




