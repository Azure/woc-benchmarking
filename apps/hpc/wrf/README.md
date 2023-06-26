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

build hdf5-1.12.2

```
wget https://github.com/HDFGroup/hdf5/archive/refs/tags/hdf5-1_12_2.tar.gz
tar -xzvf hdf5-1_12_2.tar.gz
mkdir hdf5
cd hdf5-1_12_2
CFLAGS="$CFLAGS -fPIC -O3 -march=znver4" CXXFLAGS="$CXXFLAGS -fPIC -O3 -march=znver4" FFLAGS="$FFLAGS -fPIC -O3 -march=znver4" FCFLAGS="$FCFLAGS -fPIC -O3 -march=znver4" ./configure --prefix=$WRFROOT/hdf5 --with-zlib=$WRFROOT/zlib --enable-fortran --enable-shared --enable-parallel
make -j 96
make install
```

build netcdf-c 4.7.4

```
wget https://github.com/Unidata/netcdf-c/archive/refs/tags/v4.7.4.tar.gz
tar -xzvf v4.7.4.tar.gz
mkdir netcdf
cd netcdf-c-4.7.4
CFLAGS="$CFLAGS -fPIC  -O3 -march=znver4" CXXFLAGS="$CXXFLAGS -fPIC  -O3 -march=znver4" FFLAGS="$FFLAGS -fPIC  -O3 -march=znver4" FCFLAGS="$FCFLAGS -fPIC  -O3 -march=znver4" CPPFLAGS="-I$WRFROOT/hdf5/include -I$WRFROOT/zlib/include" LDFLAGS="-L$WRFROOT/hdf5/lib -L$WRFROOT/zlib/lib" ./configure --enable-shared --enable-parallel-tests --disable-dap --prefix=$WRFROOT/netcdf --enable-netcdf4 
make -j 96
make install
```

build netcdf-fortran-4.5.3

```
wget https://github.com/Unidata/netcdf-fortran/archive/refs/tags/v4.5.3.tar.gz
tar -xzvf v4.5.3.tar.gz
cd netcdf-fortran-4.5.3
export NCDIR=$WRFROOT/netcdf
export LD_LIBRARY_PATH=${NCDIR}/lib:${LD_LIBRARY_PATH}
CFLAGS="$CFLAGS -fPIC -O3 -march=znver4" CXXFLAGS="$CXXFLAGS -fPIC -O3 -march=znver4" FFLAGS="$FFLAGS -fPIC  -O3 -march=znver4" FCFLAGS="$FCFLAGS -fPIC  -O3 -march=znver4" CPPFLAGS=-I${NCDIR}/include LDFLAGS=-L${NCDIR}/lib ./configure --prefix=${NCDIR} --enable-netcdf4
make -j 96
make install
```

build WRF 4.2.2

```
export WRFIO_NCD_LARGE_FILE_SUPPORT=1
export HDF5=$WRFROOT/hdf5
export NETCDF=$WRFROOT/netcdf
export ZLIB=$WRFROOT/zlib
export PATH=$WRFROOT/netcdf/bin:$PATH
export NETCDF_classic=1

wget https://github.com/wrf-model/WRF/archive/refs/tags/v4.2.2.tar.gz
tar -xzvf v4.2.2.tar.gz
cd WRF-4.2.2

./configure
34
```

Modify the file `configure.wrf` and add the optimization flags to FCOPTIM. For compiler optimization, we recommend `-O3 -march=znver4 -Ofast` in your spack build receipe. GCC 13.1.0 is necessary to implement these compile time optimizations for znver4 architecture. Next, build WRF

```
./compile -j 96 em_real 2>&1 | tee compile.log
  
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



