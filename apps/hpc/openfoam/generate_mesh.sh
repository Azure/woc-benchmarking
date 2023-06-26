#!/bin/bash

INSTALL_DIR="$1"
RUN_DIR="$2"
CASE_NAME="$3"
NODES="$4"
PPN="$5"
BLOCKMESH_DIMENSIONS="$6"
mpi_library="$7" 
SPACK_VERSION="$8" 
FOAM_SPEC="$9"

########## we added this
yes | sudo yum install python3
source /opt/hpcx*/hpcx-init.sh
hpcx_load
export PATH="/apps/spack/bin/:$PATH"
. /apps/spack/share/spack/setup-env.sh
spack load $FOAM_SPEC
##########

echo -n "Azure benchmark: start generate_mesh "
date +%s ; date -u

source $INSTALL_DIR/etc/bashrc FOAMY_HEX_MESH=yes
source $FOAM_ETC/bashrc

cd $RUN_DIR
cp -r $WM_PROJECT_DIR/tutorials/incompressible/simpleFoam/motorBike/* $CASE_NAME
cd $CASE_NAME

cat $PBS_NODEFILE | sort -u > hostlist.generate
HOSTFILE=hostlist.generate
NTASKS=$((NODES * PPN))

foamDictionary \
    -entry castellatedMeshControls.maxGlobalCells \
    -set 300000000 \
    system/snappyHexMeshDict

foamDictionary \
    -entry castellatedMeshControls.maxLocalCells \
    -set 2000000 \
    system/snappyHexMeshDict


foamDictionary \
    -entry blocks \
    -set "( hex ( 0 1 2 3 4 5 6 7 ) ( $BLOCKMESH_DIMENSIONS ) simpleGrading ( 1 1 1 ) )" \
    system/blockMeshDict

# set up decomposition
X=$((NTASKS / 4))
Y=2
Z=2

foamDictionary \
    -entry numberOfSubdomains \
    -set $NTASKS \
    system/decomposeParDict

foamDictionary \
    -entry hierarchicalCoeffs.n \
    -set "($X $Y $Z)" \
    system/decomposeParDict

# Copy motorbike surface from resources directory
cp $WM_PROJECT_DIR/tutorials/resources/geometry/motorBike.obj.gz constant/triSurface/
echo -n "Azure benchmark: running surfaceFeatures "
date +%s ; date -u
#surfaceFeatures 2>&1 | tee log.surfaceFeatures
surfaceFeatureExtract 2>&1 | tee log.surfaceFeatures
echo -n "Azure benchmark: running blockMesh "
date +%s ; date -u
blockMesh 2>&1 | tee log.blockMesh
echo -n "Azure benchmark: running decomposePar "
date +%s ; date -u
decomposePar -copyZero 2>&1 | tee log.decomposePar

echo -n "Azure benchmark: running snappyHexMesh "
date +%s ; date -u
# mpi_options must have been set an environment variable by batch script 
mpirun $mpi_options snappyHexMesh -parallel -overwrite 2>&1 | tee log.snappyHexMesh
echo -n "Azure benchmark: running reconstructParMesh "
date +%s ; date -u
reconstructParMesh -constant 2>&1 | tee log.reconstructParMesh
date +%s ; date -u
rm -rf ./processor*
echo -n "Azure benchmark: running renumberMesh "
date +%s ; date -u
renumberMesh -constant -overwrite 2>&1 | tee log.renumberMesh
echo -n "Azure benchmark: finish generate_mesh "
date +%s ; date -u
