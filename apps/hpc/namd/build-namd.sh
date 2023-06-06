#!/bin/bash

export INSTALL_DIR=/share/home/hpcuser/temp/woc-benchmarking/apps/hpc/namd
module load gcc-9.2.0
module load mpi/hpcx

export ARCH="znver2"

######################################################################################################################################
cd $INSTALL_DIR

export MPI_HOME=$HPCX_MPI_DIR
module list

git clone https://gitlab.com/tcbgUIUC/namd
cd namd
git checkout 409062fb
export BUILD_DIR=$(pwd)

wget http://charm.cs.illinois.edu/distrib/charm-6.10.2.tar.gz
tar -xzf charm-6.10.2.tar.gz
cd charm-v6.10.2
./build charm++ mpi-linux-x86_64 gcc gfortran -j16 --build-shared --basedir=$MPI_HOME --with-production 2>&1 | tee charm_build_mpi.log
cd ..

wget https://sourceforge.net/projects/tcl/files/Tcl/8.5.9/tcl8.5.9-src.tar.gz
tar -xzf tcl8.5.9-src.tar.gz
mkdir -p $BUILD_DIR/tcl8.5.9-linux-x86_64-threaded
cd tcl8.5.9/unix
CC=gcc CFLAGS="-O3 -march=$ARCH -mfma -mavx2 -m3dnow -fomit-frame-pointer" ./configure --enable-threads --disable-shared --enable-64bit --prefix=$BUILD_DIR/tcl8.5.9-linux-x86_64-threaded
make -j8
make install
cd ../..
ln -s tcl8.5.9-linux-x86_64-threaded tcl
# for Genoa use -O3 -Ofast -march=skylake-avx512 -mtune=skylake-avx512 -funroll-all-loops -fprefetch-loop-arrays --param prefetch-latency=300 -mieee-fp 

wget http://www.fftw.org/fftw-3.3.10.tar.gz
tar -xzf fftw-3.3.10.tar.gz
mkdir -p $BUILD_DIR/fftw3
cd fftw-3.3.10/
./configure CC="gcc  -O3 -march=$ARCH -mfma -mavx2 -m3dnow -fomit-frame-pointer" F77="gfortran -O3 -march=$ARCH -mfma -mavx2 -m3dnow -fomit-frame-pointer" FC="gfortran -O3 -march=$ARCH -mfma -mavx2 -m3dnow -fomit-frame-pointer" CXX="g++ -O3 -march=$ARCH -mfma -mavx2 -m3dnow -fomit-frame-pointer" CPP="gcc -E" CXXCPP="g++ -E" --prefix=$BUILD_DIR/fftw3 --with-g77-wrappers --enable-avx2 --enable-threads CFLAGS="$CFLAGS -fPIC" CXXFLAGS="$CXXFLAGS -fPIC" FFLAGS="$FFLAGS -fPIC" --enable-single
make -j 16
make install
cd ../
ln -s fftw3 fftw

export CHARM_ARCH=mpi-linux-x86_64-gfortran-gcc
#export CHARM_ARCH=mpi-linux-x86_64
./config  Linux-x86_64-g++  --charm-arch $CHARM_ARCH --charm-base ./charm-v6.10.2  --with-fftw3 2>&1 | tee config.log

cd Linux-x86_64-g++
echo CXXOPTS += -mavx2 -mfma -march=$ARCH -ffp-contract=fast -funroll-loops -flto=auto -O3 >> Make.config
echo COPTS += -mavx2 -mfma -march=$ARCH -ffp-contract=fast -funroll-loops -flto=auto -O3 >> Make.config
make -j 32 2>&1 | tee make.log
export NAMDROOT=$PWD

cd ../
mkdir -p ./modulefile
cat <<EOF > ./modulefile/namd
#%Module
set              namdversion        2.15
set              NAMDROOT           $BUILD_DIR/Linux-x86_64-g++
setenv           NAMDROOT           $BUILD_DIR/Linux-x86_64-g++

append-path      PATH              $NAMDROOT
EOF
