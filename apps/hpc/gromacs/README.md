# Gromacs benchmarking

Gromacs is an open source software package, widely used for molecular dynamics simulations of proteins, lipids and nucleic acids. Our benchmarking studies are performed using two benchmarks: Peptides in water (12M atoms) and Ribosome in Water (2M atoms). The benchmarks can be obtained from the [Max Planck Institute for Multidisciplinary Sciences](https://www.mpinat.mpg.de/grubmueller/bench). 

## Getting Started

### Dependencies

* gcc compilers
* HPC-X MPI library (or any other MPI Library available)

### Install Gromacs
To install, set the proper installation path and gromacs version and run the installation script:

```
sh install_gmx.sh
```

Spack was not used for the installation as it relies on intel mkl library for gromacs, which might not work properly on AMD hardware at the moment. 


### Setting Up the Benchmarking Scripts

Two scripts are used for the benchmarking studies: 
* "gmx_benchmarking.sh" is a bash script which sets up the runtime parameters and submits the batch jobs to the system. 
* "summarize.sh" is a bash script that is used to gather the results.

The scripts require the following parameters as input:

| Input Parameter |	Description |
| ---------- | -------- |
| `NODE_LIST`	| List of node numbers used for the benchmarking studies, e.g. (2 8 32 64) for 2,4,8,32,64 node runs |
| `PPN_LIST`	| List of the number of processes per node (PPN) for the given `NODE_LIST`, e.g. (30 60 90 120) for 30,60,90,120 processes per node for the given node numbers on an HBv2 cluster |
| `THRD_LIST`   | List of thread counts per each PPN in `PPN_LIST`, e.g. (1 2 3 4) to run Gromacs using 1 through 4 threads for a given PPN |
| `compiler`	| Compiler version (default is gcc-9.2.0) |
| `mpi_library`	| MPI Library version (default is hpcx-2.8.3) |
| `BENCHMARK`   | The Gromacs benchmarking test used for the study (default is PEP for Peptides vs RIB for Ribosome) |
| `REPS`    | Number of replicas performed for each benchmarking test. Default is 3|
| `INPUTDIR` | the directory containing the input files

### Note:
Currently tested only on HBv2, HBv3, HBv3X and HC44.

### Executing program

* Run
```
sh gmx_benchmarking.sh
```

## Output

To gather the results, run:
```
sh summarize.sh
```


## Authors

arastegari@microsoft.com 


## Version History

* 0.1
    * Initial Release

