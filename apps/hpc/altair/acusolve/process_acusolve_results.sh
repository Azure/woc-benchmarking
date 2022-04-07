#!/usr/bin/env python3

from glob import glob
import pprint
import traceback
import sys
import os
import logging as log
import argparse
import numpy as np

pp = pprint.PrettyPrinter(indent=4)

parser = argparse.ArgumentParser()
parser.add_argument("-m", "--models", type=str, default=None, help="Only process models -m model1,model2,modeln")
parser.add_argument("-l", "--logging", type=str, default="INFO", help="Logging level")
args = parser.parse_args()

if args.logging.lower() == "debug":
    log.basicConfig(level=log.DEBUG, format='%(message)s')
elif args.logging.lower() == "error":
    log.basicConfig(level=log.DEBUG, format='%(message)s')
elif args.logging.lower() == "warning":
    log.basicConfig(level=log.WARNING, format='%(message)s')
else:
    log.basicConfig(level=log.INFO, format='%(message)s')

files = list()
if args.models is not None:
    log.info("Processing benchmarking tests for {}".format(args.models))
    models = args.models.split(",")
    for model in models:
        files = files + glob("{}*/*.Log".format(model))

else:
    log.info("Processing all the Log files")
    args.models = "all"
    files = glob('*/*.Log')

log.info("Model(s): {}".format(args.models))
log.info("Logging Level: {}".format(args.logging))
log.debug("Files to process: {}".format(files))

data = dict()
failed_to_finish = list()
for logfile in files:
    log.debug("File name: %s" % logfile)

    # Process hosts file to find nodes and PPN
    dir_name,file_name = os.path.split(logfile)
    file_name = file_name.split(".")[0]
    host_file = "{}{}{}{}".format(dir_name, os.sep, file_name, ".hosts")

    nodes = 0
    with open(host_file, "r") as f:
        nodes = set(f.readlines())
        nodes = int(len(nodes))
        log.debug("Nodes: {}".format(nodes))

    

    tmp_lines = open(logfile).readlines()
    problem = ""
    nsd = ""
    processor = ""
    mpi = ""
    tset = ""
    tefet = ""
    fset = ""
    fefet = ""
    tet = ""
    ppn = 0
    IntNodeFrac = ""
   
    for x,line in enumerate(tmp_lines):
        if line.find("acuPrep:                    Problem =") != -1:
            problem = line.split("=")[-1].strip()
        elif line.find("acuPrep:       Number of subdomains =") != -1:
            nsd = line.split("=")[1].strip()
        elif line.find("acuPrep:          Number of threads =") != -1:
            nt = line.split("=")[1].strip()
        elif line.find("acuSolve-impi:       Message passing type =") != -1:
            mpi = line.split("=")[1].strip()
        elif line.find("acuSolve-impi:    Interface-node fraction =") != -1:
             IntNodeFrac = line.split("=")[1].strip()
        elif line.find("   Solution  CPU/Elapse time=") != -1:
            tmp = line.split("=")[1].strip()
            if tmp_lines[x-3].find("flow") != -1:
                fset = tmp.split()[1].strip()
                tmp2 = tmp_lines[x-1].split("=")[1].strip()
                fefet = tmp2.split()[1].strip()
            elif tmp_lines[x-3].find("turbulence") != -1:
                tset = tmp.split()[1].strip()
                tmp2 = tmp_lines[x-1].split("=")[1].strip()
                tefet = tmp2.split()[1].strip()
        elif line.find(" Total CPU/Elapse time      =") != -1:
            tmp = line.split("=")[1].strip()
            tet = tmp.split()[1].strip()

    if problem != "":
       if problem not in data:
           log.debug("{}".format(problem))
           data[problem] = {}
    if mpi not in data[problem]:
        log.debug("{} : {} ".format(problem,mpi))
        data[problem][mpi] = {}

    log.debug("Log file: {}".format(logfile))
    if nsd != "":
        ppn = int(int(nsd)/nodes)
    
        log.debug("Nodes: {}, PPN: {}".format(nodes, ppn))
        if ppn not in data[problem][mpi]:
            log.debug("{} : {}".format(problem,nsd))
            data[problem][mpi][ppn] = {}
       
        if nt != "":
            if tet == "":
                 log.debug("Job failed to complete {} ".format(logfile))
                 continue
            
            if nt not in data[problem][mpi][ppn] :
                log.debug("Initialize: {} : {} : {}".format(problem,ppn,nt))
                data[problem][mpi][ppn][nt] = {}
            if nodes not in data[problem][mpi][ppn][nt]:
                data[problem][mpi][ppn][nt][nodes] = {
                    "dir": [logfile],
                    "cores": int(ppn)*int(nodes),
                    "results": {
                        "tet": [tet],
                        "tset": [tset],
                        "tefet": [tefet],
                        "fset": [fset],
                        "fefet": [fefet],
                        "inf": [float(IntNodeFrac)]
                    }
                }
            else:
                log.debug("Adding: {} : {} : {}".format(problem,nsd,nt))
                data[problem][mpi][ppn][nt][nodes]["dir"].append(logfile)
                data[problem][mpi][ppn][nt][nodes]["results"]["tet"].append(tet)
                data[problem][mpi][ppn][nt][nodes]["results"]["tset"].append(tset)
                data[problem][mpi][ppn][nt][nodes]["results"]["tefet"].append(tefet)
                data[problem][mpi][ppn][nt][nodes]["results"]["fset"].append(fset)
                data[problem][mpi][ppn][nt][nodes]["results"]["fefet"].append(fefet)
                data[problem][mpi][ppn][nt][nodes]["results"]["inf"].append(float(IntNodeFrac))
    else:
        failed_to_finish.append(logfile)


log.debug("Failed to run to completion:\n{}".format(failed_to_finish))        
log.debug("Data: {}".format(pp.pprint(data)))        

# Process the data
results = dict()
# Calculate the equivalent_serial_time
for model in data:
    log.debug("Model: {}".format(model))
    for mpi in data[model]:
        log.debug("MPI: {}".format(mpi))
        for ppn in data[model][mpi]:
            log.debug("PPN: {}".format(ppn))
            for nt in data[model][mpi][ppn]:
                log.debug("Threads: {}".format(nt))
                for nodes in data[model][mpi][ppn][nt]:
                    log.debug("Nodes: {}".format(nodes))
                    min_nodes=min(list(data[model][mpi][ppn][nt].keys()))
                    log.debug("Min Node Count: {}".format(min_nodes))
                    min_core_cnt=data[model][mpi][ppn][nt][min_nodes]["cores"]
                    log.debug("Min Core Count: {}".format(min_core_cnt))

                    # Calculate the equivalent serial time
                    log.debug("Current: {}".format(data[model][mpi][ppn][nt][min_nodes]))
                    tet_sample_times = data[model][mpi][ppn][nt][min_nodes]["results"]["tet"]
                    tset_sample_times = data[model][mpi][ppn][nt][min_nodes]["results"]["tset"]
                    tefet_sample_times = data[model][mpi][ppn][nt][min_nodes]["results"]["tefet"]
                    fset_sample_times = data[model][mpi][ppn][nt][min_nodes]["results"]["fset"]
                    fefet_sample_times = data[model][mpi][ppn][nt][min_nodes]["results"]["fefet"]
                    sample_times = []
                    for x,val in enumerate(tset_sample_times):
                        sample_times.append(float(tset_sample_times[x])+float(tefet_sample_times[x])+float(fset_sample_times[x])+float(fefet_sample_times[x]))
                    min_time = min(sample_times)
                    max_time = max(sample_times)
                    log.debug("Max: {}\tMin: {}".format(max_time,min_time))
                    est = min_core_cnt*min_time
                    log.debug("Equivalent Serial Time: {}".format(est))

                    # Setup results
                    if model not in results:
                        results[model] = dict()
                    if mpi not in results[model]:
                        results[model][mpi] = dict()
                    if ppn not in results[model][mpi]:
                        results[model][mpi][ppn] = dict()
                    if nt not in results[model][mpi][ppn]:
                        results[model][mpi][ppn][nt] = dict()

                    # Calculate Speedup for each run
                    node_cnt_list = list(data[model][mpi][ppn][nt].keys())
                    node_cnt_list.sort()
                    for node_cnt in node_cnt_list:
                        core_cnt = data[model][mpi][ppn][nt][node_cnt]["cores"]
                        log.debug("Hosts: {}, Core Count: {}, PPN: {}".format(node_cnt, core_cnt, ppn))
                        tset_sample_times = data[model][mpi][ppn][nt][node_cnt]["results"]["tset"]
                        tefet_sample_times = data[model][mpi][ppn][nt][node_cnt]["results"]["tefet"]
                        fset_sample_times = data[model][mpi][ppn][nt][node_cnt]["results"]["fset"]
                        fefet_sample_times = data[model][mpi][ppn][nt][node_cnt]["results"]["fefet"]
                        IntNodeFrac_times = data[model][mpi][ppn][nt][node_cnt]["results"]["inf"]
                        sample_times = []
                        
                        log.debug("{}".format(data[model][mpi][ppn][nt][node_cnt]))
                        log.debug("{}".format(fset_sample_times))
                        log.debug("{}".format(fefet_sample_times))
                        log.debug("{}".format(tset_sample_times))
                        log.debug("{}".format(tefet_sample_times))
                        for x,val in enumerate(tset_sample_times):
                            sample_times.append(float(tset_sample_times[x])+float(tefet_sample_times[x])+float(fset_sample_times[x])+float(fefet_sample_times[x]))

                        min_time = min(sample_times)
                        max_time = max(sample_times)
                        avg_time = np.average(sample_times)
                        avg_inf = np.average(IntNodeFrac_times)
                        stdev_time = np.std(sample_times, ddof=1)
                        log.debug("Max: {}\tMin: {}".format(max_time,min_time))
                        et_i = min_time
                        speedup = est / et_i
                        par_eff = 100*(est / (core_cnt * et_i))
                        ppn = core_cnt/node_cnt
                        log.debug("Hosts: {:6}, CoreCount: {:6}, PPN: {:4}, Speedup: {:8.2f}, ParallelEff: {:>5.1f}".format(node_cnt, core_cnt, ppn, speedup, par_eff))
                        
                        # Setup the results dictionary
                        if node_cnt not in results[model][mpi][ppn][nt]:
                            results[model][mpi][ppn][nt][node_cnt] = dict()
                        results[model][mpi][ppn][nt][node_cnt]["Cores"] = core_cnt
                        results[model][mpi][ppn][nt][node_cnt]["Speedup"] = speedup
                        results[model][mpi][ppn][nt][node_cnt]["ParEff"] = par_eff
                        results[model][mpi][ppn][nt][node_cnt]["MinSolverElapsedTime"] = min_time
                        results[model][mpi][ppn][nt][node_cnt]["MaxSolverElapsedTime"] = max_time
                        results[model][mpi][ppn][nt][node_cnt]["AvgSolverElapsedTime"] = avg_time
                        results[model][mpi][ppn][nt][node_cnt]["StdSolverElapsedTime"] = stdev_time
                        results[model][mpi][ppn][nt][node_cnt]["AvgIntNodeFrac"] = avg_inf
                        results[model][mpi][ppn][nt][node_cnt]["ResultCount"] = len(sample_times)

# Print out the results
for model in results:
    mpi_list = list(results[model].keys())
    mpi_list.sort()
    log.info("Model: {}".format(model))
    for mpi in results[model]:
        outfilename = "acusolve_{}_{}.csv".format(model,mpi)
        log.info("MPI: {}".format(mpi))
        ppn_list = list(results[model][mpi].keys())
        ppn_list.sort()
        log.info("PPN List: {}".format(ppn_list))

        with open(outfilename, "w") as outfile:
            line = "{:>7} {:>7} {:>5} {:>8} {:>8} {:>9} {:>9} {:>9} {:>9} {:>9} {:>13}".format("Hosts,", "Cores,", "PPN,", "Results,", "AvgINF,", "AvgTime,", "MinTime,", "MaxTime,", "Stdev,", "SpeedUp,", "ParallelEff,")
            log.info(line)
            outfile.write(line + "\n")
            for ppn in ppn_list:
                nt_list = list(results[model][mpi][ppn].keys())
                nt_list.sort()
                for nt in nt_list:
                    nodes_list = list(results[model][mpi][ppn][nt].keys())
                    nodes_list.sort()
                    for nodes in nodes_list:
                        cores = results[model][mpi][ppn][nt][nodes]["Cores"]
                        speedup = results[model][mpi][ppn][nt][nodes]["Speedup"]
                        par_eff = results[model][mpi][ppn][nt][nodes]["ParEff"]
                        min_elapsed_time = results[model][mpi][ppn][nt][nodes]["MinSolverElapsedTime"]
                        max_elapsed_time = results[model][mpi][ppn][nt][nodes]["MaxSolverElapsedTime"]
                        avg_elapsed_time = results[model][mpi][ppn][nt][nodes]["AvgSolverElapsedTime"]
                        avg_int_node_frac = results[model][mpi][ppn][nt][nodes]["AvgIntNodeFrac"]
                        stdev_time = results[model][mpi][ppn][nt][nodes]["StdSolverElapsedTime"]
                        res_cnt = results[model][mpi][ppn][nt][nodes]["ResultCount"]
                        line = "{:6}, {:6}, {:4}, {:7}, {:7.2f}, {:8.2f}, {:8.2f}, {:8.2f}, {:8.2f}, {:8.2f}, {:>12.1f}".format(nodes, cores, ppn, res_cnt, avg_int_node_frac, avg_elapsed_time, min_elapsed_time, max_elapsed_time, stdev_time, speedup, par_eff)
                        log.info(line)
                        outfile.write(line + "\n")
