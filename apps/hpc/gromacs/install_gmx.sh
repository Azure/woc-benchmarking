#!/bin/bash

export GMX_VERSION=2023.1
export WORKING_DIR=/mnt/resource_nvme/
export INSTALL_DIR=/apps/gromacs-${GMX_VERSION}

module load gcc-13.1.0
module load mpi/hpcx-v2.15

cd $WORKING_DIR
sudo yum install cmake -y
sudo yum install sphinx libsphinxclient-devel libsphinxclient -y
sudo dnf install libarchive -y
sudo yum install hwloc -y
sudo ldconfig

echo "Get Gromacs"
wget -q http://ftp.gromacs.org/pub/gromacs/gromacs-${GMX_VERSION}.tar.gz
tar xvf gromacs-${GMX_VERSION}.tar.gz

echo "Build Gromacs"
cd gromacs-${GMX_VERSION}
mkdir build
cd build

cmake \
    -DBUILD_SHARED_LIBS=off  \
    -DBUILD_TESTING=off \
    -DREGRESSIONTEST_DOWNLOAD=OFF \
    -DGMX_BUILD_OWN_FFTW=on \
    -DGMX_DOUBLE=off \
    -DGMX_EXTERNAL_BLAS=off \
    -DGMX_EXTERNAL_LAPACK=off \
    -DGMX_FFT_LIBRARY=fftw3 \
    -DGMX_GPU=off \
    -DGMX_MPI=on \
    -DCMAKE_CXX_COMPILER=g++ \
    -DMPI_CXX_COMPILER=mpicxx \
    -DCMAKE_C_COMPILER=gcc \
    -DMPI_C_COMPILER=mpicc \
    -DGMX_OPENMP=on \
    -DGMX_X11=off \
    -DCMAKE_EXE_LINKER_FLAGS="-zmuldefs " \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
    -DCMAKE_C_FLAGS_RELWITHDEBINFO="-O3 -g -march=znver4 -Ofast" \
    -DCMAKE_CXX_FLAGS_RELWITHDEBINFO="-O3 -g -march=znver4 -Ofast" \
    -DGMX_HWLOC=on \
    -DGMXAPI=OFF \
    -DGMX_SIMD=AVX_512 \
    ..

make -j30
make install
