# WRF Benchmarking
Instructions for building WRF on Azure HBv4 VMs and running simulations under PBS workload scheduller

## Getting Started

### Dependencies

* gcc 13.1.0
* HPC-X MPI library (or any other MPI Library available)

### Building WRF 4.2.2

load the compiler & mpi library and set up the build variables
```
module load gcc-9.2
module load mpi/hpcx-v2.9.0

export CC=$(which mpicc )
export CXX=$(which mpicxx ) 
export FC=$(which mpifort ) 
export F77=$(which mpif77 )
export F90=$(which mpif90 )

mkdir wrf-hpcx
cd wrf-hpcx
export WRFROOT=$PWD
```

build zlib 1.2.13
```
wget https://www.zlib.net/zlib-1.2.13.tar.gz
tar -xzvf zlib-1.2.13.tar.gz
mkdir zlib
cd zlib-1.2.13
CFLAGS="$CFLAGS -fPIC  -O3 -march=znver4 -Ofast" CXXFLAGS="$CXXFLAGS -fPIC  -O3 -march=znver4 -Ofast" FFLAGS="$FFLAGS -fPIC  -O3 -march=znver4 -Ofast" FCFLAGS="$FCFLAGS -fPIC  -O3 -march=znver4 -Ofast" ./configure --prefix=$WRFROOT/zlib
make
make install
```





For compiler optimization, we recommend `-O3 -march=znver4 -Ofast` in your spack build receipe. GCC 13.1.0 is necessary to implement these compile time optimizations for znver4 architecture. 

To run a set of benchmarks, adjust the input variables at the top of `wrf_benchmarking-hpcx.sh` script and run

```
./wrf_benchmarking-hpcx.sh
```

to obtain a summary of the results, adjust the input variables at the top of `summarize.sh` script and run
```
sh summarize.sh
```

### Note:
Currently tested on HB series VMs.

### Input files
The input files accompanying this script are obtained from [UCAR's website](https://www2.mmm.ucar.edu/wrf/users/benchmark/benchdata_v422.html) for WRF 4.2.2 without any modifications. 



