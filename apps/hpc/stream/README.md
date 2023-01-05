# stream
Stream Memory Benchmark: builds the stream benchmark using AMD's AOCC, and runs it on AMD's H series VMs on Azure.

## Getting Started
The test depends on clang (AMD's AOCC). 

To Build:
```
sh build_stream.sh
```

To Run:
```
sh stream_run_script.sh $PWD $SKU
```
where "SKU" is the hardware type (currently AMD's MilanX aka hbrs_v3 and Naple aka hbrs_v2).

A stream triad number of greater than 350 MB/s is generally a pass for these two VM types. More SKU types to be added in future. 

