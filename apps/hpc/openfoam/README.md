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

To run a set of benchmarks, first build the mesh by adjusting the top lines of `PBS_mesh_gcc_hpcx.sh` and running
```
sh PBS_mesh_gcc_hpcx.sh
```

next, decompose the mesh by adjusting the top lines of `PBS_decompose_gcc_hpcx.sh` and running

```
sh PBS_decompose_gcc_hpcx.sh
```

afterwards you can run the benchmark by adjusting the top lines of `PBS_bench_gcc_hpcx.sh` and running
```
sh PBS_bench_gcc_hpcx.sh
```
note that, in the current version, the location of spack repo needs to be set in all the scripts. 

To obtain a summary of the results, adjust the input variables at the top of `summarize.sh` script and run
```
sh summarize.sh
```

### Note:
Currently tested on HB series VMs.




