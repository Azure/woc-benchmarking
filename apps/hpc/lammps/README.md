# LAMMPS Benchmarking
Instructions for building LAMMPS on Azure HBv3 VMs and running simulations under SLURM workload scheduller

## Getting Started

### Dependencies

* aocc 4.0.0
* HPC-X MPI library (or any other MPI Library available)

### Building LAMMPS

download and set-up the spack (in particular, set up the aocc compiler and hpcx mpi on spack)

to set up, first load the aooc in your environment, then try
```
spack compiler find
```
edit the compiler file in `~/.spack/linux/compilers.yaml` and add the following optimization flags under `aocc@4.0.0`

```
    flags:
      cflags: -march=znver2 -O3 -Ofast -fopenmp 
      cxxflags: -march=znver2 -O3 -Ofast -fopenmp 
      fflags: -march=znver2 -O3 -Ofast -fopenmp 
```

also edit the file `spack_root/etc/spack/defaults/packages.yaml` and add the location of hpcx mpi to the top of the file, e.g.
```
  hpcx-mpi:
    externals:
    - spec: hpcx-mpi@2.9.0
      modules:
      - mpi/hpcx
      prefix: /opt/hpcx-v2.9.0-gcc-MLNX_OFED_LINUX-5.4-1.0.3.0-redhat8.4-x86_64/ompi/

```
install lammps
```
spack install -j 120 lammps %aocc fftw_precision=single +intel ~kim +asphere +class2 +kspace +manybody +molecule +mpiio +opt +replica +rigid +granular +openmp-package +openmp ^amdfftw ^hpcx-mpi
```

to run a simulation
```
sbatch submit-lammps.slurm
```



### Note:
Currently tested on HBv3 series VMs.




