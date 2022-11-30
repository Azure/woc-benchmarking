#! /bin/bash

if test -f "stream.c"; then
    rm stream.c
fi

wget https://developer.amd.com/wordpress/media/files/aocc-compiler-4.0.0.tar
tar -xf aocc-compiler-4.0.0.tar
cd aocc-compiler-4.0.0
./install.sh
cd ../
source ./setenv_AOCC.sh

wget https://raw.githubusercontent.com/jeffhammond/STREAM/master/stream.c

clang stream.c -fopenmp -mcmodel=large -DSTREAM_TYPE=double -mavx2 -DSTREAM_ARRAY_SIZE=260000000 -DNTIMES=100 -ffp-contract=fast -fnt-store -O3 -ffast-math -ffinite-loops -arch zen3 -o stream


