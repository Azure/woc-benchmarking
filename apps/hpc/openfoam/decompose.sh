#!/bin/bash

INSTALL_DIR="$1"
RUN_DIR="$2"
CASE_NAME="$3"
NODES="$4"
PPN="$5"
mpi_library="$6"
SPACK_VERSION="$7"
FOAM_SPEC="$8"

echo INSTALL_DIR=$INSTALL_DIR RUN_DIR=$RUN_DIR CASE_NAME=$CASE_NAME NODES=$NODES PPN=$PPN mpi_library=$mpi_library SPACK_VERSION=$SPACK_VERSION FOAM_SPEC=$FOAM_SPEC

NTASKS=$((NODES * PPN))

yes | sudo yum install python3
source /opt/hpcx*/hpcx-init.sh
hpcx_load
export PATH="/apps/spack/bin/:$PATH"
. /apps/spack/share/spack/setup-env.sh

spack load $FOAM_SPEC

echo -n "Azure benchmark: start decompose "
date +%s ; date -u

source $INSTALL_DIR/etc/bashrc FOAMY_HEX_MESH=yes
source $FOAM_ETC/bashrc
cd $RUN_DIR/..
######## This needs to be changed if the mesh is run on a different number of cores, current number is 96
#MESH_NAME=MESH_576_6_96
MESH_NAME=MESH_1056_11_96
MESH_DIR=$(pwd)/${MESH_NAME}

cd $RUN_DIR
if [ -d ${MESH_DIR} ]; then
  ##cp -pr ${MESH_DIR}/* $CASE_NAME
  rsync -av --exclude polyMesh --exclude triSurface ${MESH_DIR} $CASE_NAME
else
  echo "Error: Mesh directory ${MESH_DIR} not found"
  exit
fi

cd $CASE_NAME
mv ${MESH_NAME}/* .
rmdir ${MESH_NAME}
ln -s ${MESH_DIR}/constant/polyMesh constant/
ln -s ${MESH_DIR}/constant/triSurface constant/

foamDictionary -entry numberOfSubdomains -set $NTASKS system/decomposeParDict
foamDictionary -entry method -set multiLevel system/decomposeParDict
foamDictionary -entry multiLevelCoeffs -set "{}" system/decomposeParDict
foamDictionary -entry scotchCoeffs -set "{}" system/decomposeParDict
foamDictionary -entry hierarchicalCoeffs -set "{}" system/decomposeParDict
foamDictionary -entry multiLevelCoeffs.level0 -set "{}" system/decomposeParDict
foamDictionary -entry multiLevelCoeffs.level0.numberOfSubdomains -set $NODES_N system/decomposeParDict
foamDictionary -entry multiLevelCoeffs.level0.method -set scotch system/decomposeParDict
foamDictionary -entry multiLevelCoeffs.level1 -set "{}" system/decomposeParDict
foamDictionary -entry multiLevelCoeffs.level1.numberOfSubdomains -set $PPN_N system/decomposeParDict
foamDictionary -entry multiLevelCoeffs.level1.method -set scotch system/decomposeParDict

# Additional changes to help simpleFoam work for larger motorbike cases, e.g. 130x52x52
# Taken from https://github.com/OpenFOAM/OpenFOAM-Intel/tree/master/benchmarks/motorbike
foamDictionary -entry solvers.p.nPreSweeps -set 0 system/fvSolution
foamDictionary -entry solvers.p.nPostSweeps -set 2 system/fvSolution
foamDictionary -entry solvers.p.cacheAgglomeration -set on system/fvSolution
foamDictionary -entry solvers.p.agglomerator -set faceAreaPair system/fvSolution
foamDictionary -entry solvers.p.nCellsInCoarsestLevel -set 10 system/fvSolution
foamDictionary -entry solvers.p.mergeLevels -set 1 system/fvSolution

foamDictionary -entry relaxationFactors.equations.U -set 0.7 system/fvSolution
foamDictionary -entry relaxationFactors.fields -add "{}" system/fvSolution
foamDictionary -entry relaxationFactors.fields.p -set 0.3 system/fvSolution

# Copy motorbike surface from resources directory
echo -n "Azure benchmark: running decomposePar "
date +%s ; date -u
decomposePar -copyZero 2>&1 | tee log.decomposeParMultiLevel
echo -n "Azure benchmark: finish decompose "
date +%s ; date -u

