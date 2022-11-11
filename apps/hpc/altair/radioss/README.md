# Radioss Benchmarking

## Clone git repository
- git clone https://github.com/Azure/woc-benchmarking.git

## Download Models: Neon1M11 and T10M.tgz
- Scripts are setup for them to be installed in /shared/data/altair/radios
- T10M benchmark
 - create the directory T10M and cd into that directory.
 - 7za x T10M.7z (uncompress the file)
- NEON1M11 benchmark
 - create the directory NEON1M11 and cd into that directory.
 - 7za x NEON1M11.7z (uncompress the file)

## Install Radioss 2022.1
- Edit paths in woc-benchmarking/apps/hpc/altair/radioss/install_radioss.sh to fit your system. They are currently setup to work using the cc-base template for a CycleCloud deployment.

## Licensing
- Add a line to point to the license server in the script or register the system with the Altair hosted license server
 - ALTAIR_LICENSE_PATH=Port@Host
 - Add the node to the hosted hyperworks server 
  - <path to altair version install>/altair/security/bin/linux64/almutil -hhwuauth -system -code <get code from altairone website>

