#!/bin/bash
#SBATCH --job-name=lammps
#SBATCH --nodes=16
#SBATCH --ntasks-per-node=120
#SBATCH --partition=hbv3
#SBATCH --time=6:00:00
#SBATCH --exclusive
#SBATCH --output=lammps-log.%j
#SBATCH --error=lammps-log.%j
#SBATCH --mem=0

module load mpi/hpcx
source /anf/lammps/spack/share/spack/setup-env.sh
spack load lammps 

cd $SLURM_SUBMIT_DIR/results

mkdir ${SLURM_NNODES}N-40PPN.$SLURM_JOBID
cd ${SLURM_NNODES}N-40PPN.$SLURM_JOBID
cp $SLURM_SUBMIT_DIR/data/AA_box.in .
ln -s $SLURM_SUBMIT_DIR/data/data.equil .

export PMIX_INSTALL_PREFIX=$OPAL_PREFIX
export NPCS=$((SLURM_NNODES * 40))
export OMP_NUM_THREADS=3
mpirun -np $NPCS --map-by ppr:10:numa:PE=$OMP_NUM_THREADS --rank-by slot --bind-to core --report-bindings -x OMP_NUM_THREADS -x LD_LIBRARY_PATH -x UCX_TLS=dc_x,sm,self -x UCX_DC_MLX5_TM_ENABLE=y -x UCX_DC_TM_ENABLE=y -x UCX_UNIFIED_MODE=y lmp -in AA_box.in -sf intel -pk intel 0 omp $OMP_NUM_THREADS mode single
