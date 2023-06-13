# Fluent Benchmarking
Scripts for benchmarking Ansys FLUENT on PBS & Slurm clusters

## Getting Started

### Dependencies

* None 
* Relies on HPCX MPI available on AzureHPC images

### Building Ansys Fluent
To build Ansys Fluent on Azure, use [this](https://raw.githubusercontent.com/Azure/azurehpc/master/apps/fluent/install_fluent.sh) build script. 


To run a simulation, modify and submit the job scripts for your respective job scheduller. For PBS

```
qsub run-fluent.pbs
```
and for Slurm
```
sbatch run-fluent.slurm
```

## Output

The solver ratings can be obtained by running 
```
grep "Solver rating" *.log 
```
inside the job directory. 



