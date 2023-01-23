#!/bin/bash
  
tgz_file=${1:-SPEOSHPC_2022R2_LINX64.tgz}

INSTALL_DIR=/shared/apps/ansys_inc

mkdir speos_tmp
cd speos_tmp

tar -xzvf ../$tgz_file

./INSTALL -silent -install_dir "$INSTALL_DIR/"
