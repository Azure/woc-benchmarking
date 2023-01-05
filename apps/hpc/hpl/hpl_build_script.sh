#!/bin/bash

export HPL_VERSION="2.3"

wdir=$(pwd)
module load gcc-9.2.0
module load mpi/hpcx
git clone https://github.com/flame/blis.git
cd blis/
git reset --hard ae10d9495486f589ed0320f0151b2d195574f1cf
mkdir libblis
libbls=$(pwd)/libblis
sed -i 's/COPTFLAGS      := -O2/COPTFLAGS      := -O2 -Ofast -ffast-math -ftree-vectorize -funroll-loops -march=znver2/' config/amd64/make_defs.mk
./configure --prefix=$libbls --enable-threading=openmp CC=gcc zen3
make 
make install
cd ../

wget --no-check-certificate https://www.netlib.org/benchmark/hpl/hpl-${HPL_VERSION}.tar.gz
tar -xzf hpl-${HPL_VERSION}.tar.gz
cd hpl-${HPL_VERSION}/
hpldir=$(pwd)
cd setup
sh make_generic
cp Make.UNKNOWN ../Make.Linux
cd ../
sed -i 's/ARCH         = UNKNOWN/ARCH         = Linux/' Make.Linux
sed -i 's,TOPdir       = $(HOME)/hpl'",TOPdir       = $hpldir," Make.Linux
sed -i 's,LAdir        ='",LAdir        = $libbls," Make.Linux
sed -i 's,LAinc        ='",LAinc        = -I$libbls/include/blis," Make.Linux
sed -i 's,LAlib        = -lblas'",LAlib        = $libbls/lib/libblis.a -lm," Make.Linux
sed -i 's/CCFLAGS      = $(HPL_DEFS)/CCFLAGS      = $(HPL_DEFS) -fomit-frame-pointer -O3 -funroll-loops -W -Wall -march=znver2 -mtune=znver2 -fopenmp/' Make.Linux
sed -i 's/LINKER       = mpif77/LINKER       = mpicc/' Make.Linux
sed -i 's/LINKFLAGS    =/LINKFLAGS    = $(CCFLAGS)/' Make.Linux
make arch=Linux

cd $wdir
cp $hpldir/bin/Linux/xhpl .

cat <<EOF > HPL.dat
HPLinpack benchmark input file
Innovative Computing Laboratory, University of Tennessee
HPL.out      output file name (if any)
6            device out (6=stdout,7=stderr,file)
1            # of problems sizes (N)
128000       #84480            Ns
1            # of NBs
232            NBs
0            PMAP process mapping (0=Row-,1=Column-major)
1            # of process grids (P x Q)
4           Ps
4            Qs
16.0         threshold
1            # of panel fact
2            PFACTs (0=left, 1=Crout, 2=Right)
1            # of recursive stopping criterium
4            NBMINs (>= 1)
1            # of panels in recursion
2            NDIVs
1            # of recursive panel fact.
2            RFACTs (0=left, 1=Crout, 2=Right)
1            # of broadcast
2            BCASTs (0=1rg,1=1rM,2=2rg,3=2rM,4=Lng,5=LnM)
1            # of lookahead depth
1            DEPTHs (>=0)
1            SWAP (0=bin-exch,1=long,2=mix)
64           swapping threshold
0            L1 in (0=transposed,1=no-transposed) form
0            U  in (0=transposed,1=no-transposed) form
1            Equilibration (0=no,1=yes)
8            memory alignment in double (> 0)
EOF

<<<<<<< HEAD

chmod +x appfile_ccx*
=======
cat <<EOF > appfile_ccx
-np 1 ./xhpl_ccx.sh 0 0-5 6
-np 1 ./xhpl_ccx.sh 0 8-13 6
-np 1 ./xhpl_ccx.sh 0 16-21 6
-np 1 ./xhpl_ccx.sh 0 24-29 6
-np 1 ./xhpl_ccx.sh 1 30-35 6
-np 1 ./xhpl_ccx.sh 1 38-43 6
-np 1 ./xhpl_ccx.sh 1 46-51 6
-np 1 ./xhpl_ccx.sh 1 54-59 6
-np 1 ./xhpl_ccx.sh 2 60-65 6
-np 1 ./xhpl_ccx.sh 2 68-73 6
-np 1 ./xhpl_ccx.sh 2 76-81 6
-np 1 ./xhpl_ccx.sh 2 84-89 6
-np 1 ./xhpl_ccx.sh 3 90-95 6
-np 1 ./xhpl_ccx.sh 3 98-103 6
-np 1 ./xhpl_ccx.sh 3 106-111 6
-np 1 ./xhpl_ccx.sh 3 114-119 6
EOF

cat <<EOF > xhpl_ccx.sh 
#! /usr/bin/env bash
#
# Bind memory to node \$1 and four child threads to CPUs specified in \$2
#
# Kernel parallelization is performed at the 2nd innermost loop (IC)
export LD_LIBRARY_PATH=\$HPCX_MPI_DIR/lib:\$LD_LIBRARY_PATH
export OMP_NUM_THREADS=\$3
export GOMP_CPU_AFFINITY="\$2"
export OMP_PROC_BIND=TRUE
# BLIS_JC_NT=1 (No outer loop parallelization):
export BLIS_JC_NT=1
# BLIS_IC_NT= #cores/ccx (# of 2nd level threads �~@~S one per core in the shared L3 cache domain):
export BLIS_IC_NT=\$OMP_NUM_THREADS
# BLIS_JR_NT=1 (No 4th level threads):
export BLIS_JR_NT=1
# BLIS_IR_NT=1 (No 5th level threads):
export BLIS_IR_NT=1
numactl --membind=\$1 ./xhpl
EOF

cat <<EOF > hpl_run_scr_hbv3.sh
#!/bin/bash
wdir=\$1

#module load mpi/hpcx
source /opt/hpcx-*-x86_64/hpcx-init.sh
hpcx_load

ulimit -s unlimited
ulimit -l unlimited
ulimit -a

echo always | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
echo always | sudo tee /sys/kernel/mm/transparent_hugepage/defrag

cd \$wdir

mkdir HPL-test.\$(hostname | tr "[:upper:]" "[:lower:]")
cd HPL-test.\$(hostname | tr "[:upper:]" "[:lower:]")

cp ../HPL.dat .
cp ../appfile*_ccx .
cp ../xhpl_ccx.sh .
cp ../xhpl .

export mpi_options="--mca mpi_leave_pinned 1 --bind-to none --report-bindings --mca btl self,vader --map-by ppr:1:l3cache -x OMP_NUM_THREADS=6 -x OMP_PROC_BIND=TRUE -x OMP_PLACES=cores -x LD_LIBRARY_PATH"

echo "Running on \$(hostname | tr "[:upper:]" "[:lower:]")" > hpl-\$(hostname | tr "[:upper:]" "[:lower:]").log
mpirun \$mpi_options -app ./appfile_ccx  >> hpl-\$(hostname | tr "[:upper:]" "[:lower:]").log
#echo "system: \$(hostname | tr "[:upper:]" "[:lower:]") HPL: \$(grep WR hpl*.log | awk -F ' ' '{print \$7}')" >> ../hpl-test-results.log
EOF

cat <<EOF > hpl_run_scr_hbv2.sh
#!/bin/bash
wdir=\$1

#module load mpi/hpcx
source /opt/hpcx-*-x86_64/hpcx-init.sh
hpcx_load

ulimit -s unlimited
ulimit -l unlimited
ulimit -a

echo always | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
echo always | sudo tee /sys/kernel/mm/transparent_hugepage/defrag

cd \$wdir

mkdir HPL-test.\$(hostname | tr "[:upper:]" "[:lower:]")
cd HPL-test.\$(hostname | tr "[:upper:]" "[:lower:]")

cp ../HPL.dat .
cp ../appfile*_ccx .
cp ../xhpl_ccx.sh .
cp ../xhpl .

sed -i "s/4           Ps/6           Ps/g" HPL.dat
sed -i "s/4            Qs/5            Qs/g" HPL.dat

echo "Running on \$(hostname | tr "[:upper:]" "[:lower:]")" > hpl-\$(hostname | tr "[:upper:]" "[:lower:]").log
mpirun -np 30 --report-bindings --mca btl self,vader --map-by ppr:1:l3cache:pe=4 -x OMP_NUM_THREADS=4 -x OMP_PROC_BIND=TRUE -x OMP_PLACES=cores -x LD_LIBRARY_PATH xhpl >> hpl-\$(hostname | tr "[:upper:]" "[:lower:]").log
#echo "system: \$(hostname | tr "[:upper:]" "[:lower:]") HPL: \$(grep WR hpl*.log | awk -F ' ' '{print \$7}')" >> ../hpl-test-results.log
EOF

cat <<EOF > hpl_pssh_script.sh
#!/bin/bash
export wdir=\$(pwd)

sudo yum install pssh -y

echo "beginning date: \$(date)"

echo \$(hostname | tr "[:upper:]" "[:lower:]") > hosts.txt

if command -v pbsnodes --version &> /dev/null
then
	pbsnodes -avS | grep free | awk -F ' ' '{print tolower(\$1)}' >> hosts.txt
fi

if [ "\${VM_SERIES}" == "hbrs_v3" ]; then
	pssh -p 301 -t 0 -i -h hosts.txt "cd \$wdir && ./hpl_run_scr_hbv3.sh \$wdir" >> hpl_pssh.log 2>&1
elif [ "\${VM_SERIES}" == "hbrs_v2" ]; then
	pssh -p 301 -t 0 -i -h hosts.txt "cd \$wdir && ./hpl_run_scr_hbv2.sh \$wdir" >> hpl_pssh.log 2>&1
fi

sleep 60

IFS=\$'\n' read -d '' -r -a names < ./hosts.txt
for i in \${names[@]}; do
    echo "system: \$i HPL: \$(grep WR ./HPL-test.\$i/hpl*.log | awk -F ' ' '{print \$7}')" >> hpl-test-results.log
done

echo "end date: \$(date)"

EOF

chmod +x appfile_ccx
>>>>>>> 5f833d4bd55b3eb4d6b5ad7722772ba4b95a16d0
chmod +x xhpl_ccx.sh
chmod +x hpl_run_scr_*.sh
chmod +x hpl_pssh_script.sh
