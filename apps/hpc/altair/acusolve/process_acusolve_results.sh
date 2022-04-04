#!/usr/bin/env python3

from glob import glob
import pprint
import traceback
import sys
import os
import logging as log
import argparse

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
    fset = ""
    tet = ""
    ppn = 0
   
    for x,line in enumerate(tmp_lines):
        if line.find("acuPrep:                    Problem =") != -1:
            problem = line.split("=")[-1].strip()
        elif line.find("acuPrep:       Number of subdomains =") != -1:
            nsd = line.split("=")[1].strip()
        elif line.find("acuPrep:          Number of threads =") != -1:
            nt = line.split("=")[1].strip()
        elif line.find("acuSolve-impi:       Message passing type =") != -1:
            mpi = line.split("=")[1].strip()
        elif line.find("   Solution  CPU/Elapse time=") != -1:
            tmp = line.split("=")[1].strip()
            if tmp_lines[x-3].find("flow") != -1:
                fset = tmp.split()[1].strip()
            elif tmp_lines[x-3].find("turbulence") != -1:
                tset = tmp.split()[1].strip()
        elif line.find(" Total CPU/Elapse time      =") != -1:
            tmp = line.split("=")[1].strip()
            tet = tmp.split()[1].strip()

    if problem != "":
       if problem not in data:
           print("{}".format(problem))
           data[problem] = {}
    if mpi not in data[problem]:
        print("{} : {} ".format(problem,mpi))
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
                    "results": {
                        "tet": [tet],
                        "tset": [tset],
                        "fset": [fset]
                    }
                }
            else:
                log.debug("Adding: {} : {} : {}".format(problem,nsd,nt))
                data[problem][mpi][ppn][nt][nodes]["dir"].append(logfile)
                data[problem][mpi][ppn][nt][nodes]["results"]["tet"].append(tet)
                data[problem][mpi][ppn][nt][nodes]["results"]["tset"].append(tset)
                data[problem][mpi][ppn][nt][nodes]["results"]["fset"].append(fset)
    else:
        failed_to_finish.append(logfile)


log.debug("Failed to run to completion:\n{}".format(failed_to_finish))        
log.debug("Data: {}".format(pp.pprint(data)))        
sys.exit(0)
    
if a == True:
    model = items[0].firstChild.data
    if model not in data:
        data[model] = dict()

    # Find the number of hosts
    try:
        items = mydoc.getElementsByTagName('NumberOfHosts')
        host_cnt = int(items[0].firstChild.data)
        items = mydoc.getElementsByTagName('Sample')
        cores = int(items[0].getElementsByTagName("NumberOfWorkers")[0].firstChild.data)
        ppn = cores/host_cnt
        if ppn not in data[model]:
            data[model][ppn] = dict()
        if host_cnt not in data[model][ppn]:
            data[model][ppn][host_cnt] = dict()

        # Find the run date
        items = mydoc.getElementsByTagName('RunDate')
        run_date = items[0].firstChild.data

        # Find the chip model
        items = mydoc.getElementsByTagName('Sample')
        total_elapsed_time = items[0].getElementsByTagName("TotalElapsedTime")[0].firstChild.data
        sample_elapsed_time = items[0].getElementsByTagName("SampleElapsedTime")[0].firstChild.data
        number_of_sample_steps = items[0].getElementsByTagName("NumberOfSampleSteps")[0].firstChild.data
        log.debug("Cores: {}".format(cores))
        if cores not in data[model][ppn][host_cnt]:
            data[model][ppn][host_cnt][cores] = dict()
            data[model][ppn][host_cnt][cores]["TotalElapsedTime"] = list()
            data[model][ppn][host_cnt][cores]["SampleElapsedTime"] = list()
            data[model][ppn][host_cnt][cores]["AverageElapsedTime"] = list()
            data[model][ppn][host_cnt][cores]["RunDate"] = list()
            data[model][ppn][host_cnt][cores]["CalcSpeedup"] = list()
            data[model][ppn][host_cnt][cores]["CalcParallel_Eff"] = list()
        
        # Add the data points
        data[model][ppn][host_cnt][cores]["TotalElapsedTime"].append(float('{:0.2f}'.format(float(total_elapsed_time))))
        data[model][ppn][host_cnt][cores]["SampleElapsedTime"].append(float('{:0.2f}'.format(float(sample_elapsed_time))))
        data[model][ppn][host_cnt][cores]["AverageElapsedTime"].append(float('{:0.2f}'.format(float(sample_elapsed_time)/float(number_of_sample_steps))))
        data[model][ppn][host_cnt][cores]["RunDate"].append('{:.10}'.format(run_date))

        # Find the chip model
        items = mydoc.getElementsByTagName('ChipModel')
        chip_model = items[0].firstChild.data
        if chip_model not in data[model][ppn][host_cnt][cores]:
            data[model][ppn][host_cnt][cores]["Chip Model"] = chip_model

    
    except:
        log.warning("Job Failed - File name: %s" % xmlfile)
        if args.logging.lower() == "debug":
            status=traceback.print_exc(file=sys.stdout)
        #break
        
#pp = pprint.PrettyPrinter(indent=4)
#pp.pprint(data)

results = dict()
# Calculate the equivalent_serial_time
for model in data:
    for ppn in data[model]:
        log.debug("Model: {}".format(model))
        min_nodes=min(list(data[model][ppn].keys()))
        log.debug("Min Node Count: {}".format(min_nodes))
        min_core_cnt=min(data[model][ppn][min_nodes].keys())
        log.debug("Min Core Count: {}".format(min_core_cnt))
        # Calculate the equivalent serial time
        sample_times = data[model][ppn][min_nodes][min_core_cnt]["SampleElapsedTime"]
        min_time = min(sample_times)
        max_time = max(sample_times)
        log.debug("Max: {}\tMin: {}".format(max_time,min_time))
        est = min_core_cnt*min_time
        log.debug("Equivalent Serial Time: {}".format(est))

        # Setup results
        if model not in results:
            results[model] = dict()

        # Calculate Speedup for each run
        host_cnt_list = list(data[model][ppn].keys())
        host_cnt_list.sort()
        for host_cnt in host_cnt_list:
            core_cnt_list = list(data[model][ppn][host_cnt].keys())
            core_cnt_list.sort()

            for core_cnt in core_cnt_list:

                log.debug("Hosts: {}, Core Count: {}, PPN: {}".format(host_cnt, core_cnt, core_cnt/host_cnt))
                sample_times = data[model][ppn][host_cnt][core_cnt]["SampleElapsedTime"]
                min_time = min(sample_times)
                max_time = max(sample_times)
                log.debug("Max: {}\tMin: {}".format(max_time,min_time))
                et_i = min_time
                speedup = est / et_i
                par_eff = 100*(est / (core_cnt * et_i))
                ppn = core_cnt/host_cnt
                #print("Hosts: {:6}, CoreCount: {:6}, PPN: {:4}, Speedup: {:8.2f}, ParallelEff: {:>5.1f}".format(host_cnt, core_cnt, ppn, speedup, par_eff))
            
                # Setup the results dictionary
                if ppn not in results[model]:
                    results[model][ppn] = dict()
                if host_cnt not in results[model][ppn]:
                    results[model][ppn][host_cnt] = dict()
                results[model][ppn][host_cnt]["Cores"] = core_cnt
                results[model][ppn][host_cnt]["Speedup"] = speedup
                results[model][ppn][host_cnt]["ParEff"] = par_eff
                results[model][ppn][host_cnt]["SampleElapsedTime"] = min(sample_times)

# Print out the results
for model in results:
    ppn_list = list(results[model].keys())
    ppn_list.sort()
    log.info("Model: {}".format(model))
    log.info("PPN List: {}".format(ppn_list))

    outfilename = "starccm_bm_%s.csv" % model
    with open(outfilename, "w") as outfile:
        line = "{:>7} {:>7} {:>5} {:>9} {:>9} {:>13}".format("Hosts,", "Cores,", "PPN,", "SETime,", "SpeedUp,", "ParallelEff,")
        log.info(line)
        outfile.write(line + "\n")
        for ppn in ppn_list:
            #print("PPN: {}".format(ppn))
            host_cnt_list = list(results[model][ppn].keys())
            host_cnt_list.sort()
            for host_cnt in host_cnt_list:
                cores = results[model][ppn][host_cnt]["Cores"]
                speedup = results[model][ppn][host_cnt]["Speedup"]
                par_eff = results[model][ppn][host_cnt]["ParEff"]
                sample_elapsed_time = results[model][ppn][host_cnt]["SampleElapsedTime"]
                line = "{:6}, {:6}, {:4}, {:8.2f}, {:8.2f}, {:>12.1f}".format(host_cnt, cores, ppn, sample_elapsed_time, speedup, par_eff)
                log.info(line)
                outfile.write(line + "\n")
