# CP2K Benchmarking
Instructions for building CP2K on Azure HBv4 VMs and running simulations under PBS and SLURM workload schedullers

## Getting Started

### Dependencies

* gcc 13.1.0
* HPC-X MPI library (or any other MPI Library available)
* Spack

### Building CP2K
To buil CP2K using spack, you first need to build libxsmm 
```
spack install -j 144 libxsmm +shared+generator target=x86_64 %gcc@13.1.0

```
cd to libxsmm lib dir, using `spack location -i libxsmm`, then run `strip libxsmmext.so libxsmmext.so.1 libxsmmext.so.1.17.0`

now build cp2k using this build of libxsmm
```
spack install --dirty -j 144 cp2k+elpa smm=libxsmm %gcc@13.1.0 ^fftw+openmp ^amdscalapack ^amdblis ^amdlibflame ^libint ^libxc ^hpcx ^elpa+openmp ^libxsmm +shared+generator target=x86_64 %gcc@13.1.0 /6tsgr
```  
where "/6tsgr" is the spack id for the libxsmm build on your system in the previous step. 


For compiler optimization, we recommend `-O3 -march=znver4 -Ofast` in your spack build receipe. GCC 13.1.0 is necessary to implement these compile time optimizations for znver4 architecture. 

To run a set of benchmarks, adjust the input variables at the top of `cp2k_benchmarking.sh` script and run

```
./cp2k_benchmarking.sh
```

### Note:
Currently tested on HB series VMs.

### Input files
The input files accompanying this script are obtained from [CP2K's public repository](https://github.com/cp2k/cp2k/blob/master/benchmarks/QS_DM_LS/H2O-dft-ls.NREP4.inp) for H2O-DFT-LS-NRES4 benchmark, without any modifications. 



